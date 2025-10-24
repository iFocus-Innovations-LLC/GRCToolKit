#!/bin/bash

# GCP Development Environment Setup Script
# GRC Toolkit v1.1 - OSCAL Integration
# Complete setup for GCP development environment

set -e

# Configuration
PROJECT_ID=${GCP_PROJECT_ID:-"your-project-id"}
REGION=${GCP_REGION:-"us-central1"}
ZONE=${GCP_ZONE:-"us-central1-a"}
CLUSTER_NAME=${GKE_CLUSTER_NAME:-"grc-toolkit-dev"}
MACHINE_TYPE=${MACHINE_TYPE:-"e2-standard-2"}
NODE_COUNT=${NODE_COUNT:-2}
ARTIFACT_REGISTRY_LOCATION=${ARTIFACT_REGISTRY_LOCATION:-"us-central1"}
REPOSITORY_NAME=${REPOSITORY_NAME:-"grc-toolkit"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Header
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                GRC Toolkit v1.1 GCP Dev Setup                ║"
echo "║                    OSCAL Integration                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check for required tools
    if ! command -v gcloud &> /dev/null; then
        missing_tools+=("gcloud CLI")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("Docker")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("Git")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Please install the missing tools:"
        echo "- Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
        echo "- Docker: https://docs.docker.com/get-docker/"
        echo "- kubectl: https://kubernetes.io/docs/tasks/tools/"
        echo "- Git: https://git-scm.com/downloads"
        echo "- curl: Usually pre-installed on most systems"
        exit 1
    fi
    
    success "All prerequisites found"
}

# Authenticate and configure GCP
setup_gcp_auth() {
    log "Setting up GCP authentication and configuration..."
    
    # Authenticate with GCP
    gcloud auth login --no-launch-browser
    
    # Set default project
    gcloud config set project $PROJECT_ID
    
    # Set default region and zone
    gcloud config set compute/region $REGION
    gcloud config set compute/zone $ZONE
    
    success "GCP authentication configured"
}

# Enable required APIs
enable_apis() {
    log "Enabling required GCP APIs..."
    
    local apis=(
        "compute.googleapis.com"
        "container.googleapis.com"
        "artifactregistry.googleapis.com"
        "logging.googleapis.com"
        "monitoring.googleapis.com"
        "storage.googleapis.com"
        "secretmanager.googleapis.com"
        "cloudbuild.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        log "Enabling $api..."
        gcloud services enable $api
    done
    
    success "All required APIs enabled"
}

# Create Artifact Registry repository
create_artifact_registry() {
    log "Creating Artifact Registry repository..."
    
    # Create repository if it doesn't exist
    if ! gcloud artifacts repositories describe $REPOSITORY_NAME \
        --location=$ARTIFACT_REGISTRY_LOCATION &> /dev/null; then
        
        gcloud artifacts repositories create $REPOSITORY_NAME \
            --repository-format=docker \
            --location=$ARTIFACT_REGISTRY_LOCATION \
            --description="GRC Toolkit container images"
        
        success "Artifact Registry repository created"
    else
        warning "Artifact Registry repository already exists"
    fi
    
    # Configure Docker authentication
    gcloud auth configure-docker $ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev
    
    success "Docker authentication configured for Artifact Registry"
}

# Create GKE cluster
create_gke_cluster() {
    log "Creating GKE cluster..."
    
    # Check if cluster already exists
    if gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE &> /dev/null; then
        warning "GKE cluster already exists"
        return
    fi
    
    # Create cluster
    gcloud container clusters create $CLUSTER_NAME \
        --zone=$ZONE \
        --num-nodes=$NODE_COUNT \
        --machine-type=$MACHINE_TYPE \
        --enable-autoscaling \
        --min-nodes=1 \
        --max-nodes=5 \
        --enable-autorepair \
        --enable-autoupgrade \
        --enable-ip-alias \
        --enable-network-policy \
        --addons=HttpLoadBalancing,HorizontalPodAutoscaling \
        --enable-stackdriver-kubernetes \
        --disk-size=20GB \
        --disk-type=pd-standard \
        --image-type=COS_CONTAINERD \
        --enable-shielded-nodes \
        --tags=grc-toolkit-dev
    
    success "GKE cluster created"
}

# Get cluster credentials
get_cluster_credentials() {
    log "Getting GKE cluster credentials..."
    
    gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE
    
    # Verify connection
    kubectl cluster-info
    
    success "Cluster credentials configured"
}

# Create namespace
create_namespace() {
    log "Creating Kubernetes namespace..."
    
    # Create namespace if it doesn't exist
    if ! kubectl get namespace grc-toolkit &> /dev/null; then
        kubectl create namespace grc-toolkit
        success "Namespace 'grc-toolkit' created"
    else
        warning "Namespace 'grc-toolkit' already exists"
    fi
}

# Create secrets
create_secrets() {
    log "Creating Kubernetes secrets..."
    
    # Check if GEMINI_API_KEY is provided
    if [ -z "$GEMINI_API_KEY" ]; then
        warning "GEMINI_API_KEY not provided. You'll need to create the secret manually."
        echo "Run: kubectl create secret generic grc-toolkit-secrets --from-literal=gemini-api-key='your-key' -n grc-toolkit"
        return
    fi
    
    # Create secret
    kubectl create secret generic grc-toolkit-secrets \
        --from-literal=gemini-api-key="$GEMINI_API_KEY" \
        --namespace=grc-toolkit \
        --dry-run=client -o yaml | kubectl apply -f -
    
    success "Kubernetes secrets created"
}

# Build and push container image
build_and_push_image() {
    log "Building and pushing container image..."
    
    # Build image
    local image_tag="$ARTIFACT_REGISTRY_LOCATION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY_NAME/grc-toolkit:latest"
    
    log "Building Docker image..."
    docker build -t $image_tag .
    
    # Push image
    log "Pushing image to Artifact Registry..."
    docker push $image_tag
    
    success "Container image built and pushed"
}

# Deploy application
deploy_application() {
    log "Deploying GRC Toolkit application..."
    
    # Apply Kubernetes manifests
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/secret.yaml
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    kubectl apply -f k8s/ingress.yaml
    kubectl apply -f k8s/hpa.yaml
    
    success "Application deployed"
}

# Wait for deployment
wait_for_deployment() {
    log "Waiting for deployment to be ready..."
    
    # Wait for deployment to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/grc-toolkit -n grc-toolkit
    
    # Check pod status
    kubectl get pods -n grc-toolkit
    
    success "Deployment is ready"
}

# Get application URL
get_application_url() {
    log "Getting application URL..."
    
    # Get external IP
    local external_ip=$(kubectl get ingress grc-toolkit-ingress -n grc-toolkit -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -n "$external_ip" ]; then
        echo ""
        echo -e "${GREEN}🎉 GRC Toolkit is now accessible at:${NC}"
        echo -e "${BLUE}   http://$external_ip${NC}"
        echo ""
        echo -e "${YELLOW}Note: It may take a few minutes for the load balancer to be ready.${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠️  External IP not yet available. Check status with:${NC}"
        echo -e "${BLUE}   kubectl get ingress grc-toolkit-ingress -n grc-toolkit${NC}"
    fi
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring and logging..."
    
    # Enable Cloud Logging
    gcloud logging write grc-toolkit-setup "GRC Toolkit development environment setup completed" --severity=INFO
    
    # Create monitoring dashboard (basic)
    cat > monitoring-dashboard.json << EOF
{
  "displayName": "GRC Toolkit Dashboard",
  "mosaicLayout": {
    "tiles": [
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Pod Status",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type=\"k8s_pod\" AND resource.labels.namespace_name=\"grc-toolkit\""
                  }
                }
              }
            ]
          }
        }
      }
    ]
  }
}
EOF
    
    success "Monitoring configured"
}

# Generate setup summary
generate_summary() {
    log "Generating setup summary..."
    
    cat > gcp-dev-setup-summary.md << EOF
# GCP Development Environment Setup Summary

**Setup Date**: $(date)
**Project ID**: $PROJECT_ID
**Region**: $REGION
**Zone**: $ZONE
**Cluster**: $CLUSTER_NAME

## Resources Created

### GCP Services
- Compute Engine API
- Kubernetes Engine API
- Artifact Registry API
- Cloud Logging API
- Cloud Monitoring API
- Cloud Storage API
- Secret Manager API
- Cloud Build API

### GKE Cluster
- **Name**: $CLUSTER_NAME
- **Zone**: $ZONE
- **Machine Type**: $MACHINE_TYPE
- **Node Count**: $NODE_COUNT
- **Auto-scaling**: Enabled (1-5 nodes)

### Artifact Registry
- **Repository**: $REPOSITORY_NAME
- **Location**: $ARTIFACT_REGISTRY_LOCATION
- **Format**: Docker

### Kubernetes Resources
- **Namespace**: grc-toolkit
- **Secrets**: grc-toolkit-secrets
- **ConfigMaps**: grc-toolkit-config
- **Deployments**: grc-toolkit
- **Services**: grc-toolkit-service
- **Ingress**: grc-toolkit-ingress
- **HPA**: grc-toolkit-hpa

## Access Information

### Application URL
- **External IP**: \$(kubectl get ingress grc-toolkit-ingress -n grc-toolkit -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
- **URL**: http://[EXTERNAL-IP]

### Cluster Access
\`\`\`bash
# Get cluster credentials
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE

# Check pod status
kubectl get pods -n grc-toolkit

# View logs
kubectl logs -f deployment/grc-toolkit -n grc-toolkit
\`\`\`

## Cost Estimation

### Monthly Costs (Development)
- **GKE Cluster**: ~\$50-100/month
- **Artifact Registry**: ~\$5/month
- **Cloud Logging**: ~\$10/month
- **Cloud Monitoring**: ~\$5/month
- **Network**: ~\$5/month
- **Total**: ~\$75-125/month

## Next Steps

1. **Verify Deployment**: Check that all pods are running
2. **Test Application**: Access the application URL
3. **Configure Monitoring**: Set up custom dashboards
4. **Set Up Alerts**: Configure alerting rules
5. **Documentation**: Review setup documentation

## Useful Commands

\`\`\`bash
# Check cluster status
kubectl cluster-info

# View all resources
kubectl get all -n grc-toolkit

# Check logs
kubectl logs -f deployment/grc-toolkit -n grc-toolkit

# Scale deployment
kubectl scale deployment grc-toolkit --replicas=3 -n grc-toolkit

# Update secret
kubectl create secret generic grc-toolkit-secrets --from-literal=gemini-api-key='new-key' -n grc-toolkit --dry-run=client -o yaml | kubectl apply -f -
\`\`\`

## Cleanup

To clean up the development environment:

\`\`\`bash
# Delete GKE cluster
gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE

# Delete Artifact Registry repository
gcloud artifacts repositories delete $REPOSITORY_NAME --location=$ARTIFACT_REGISTRY_LOCATION

# Delete firewall rules
gcloud compute firewall-rules delete grc-toolkit-web-access grc-toolkit-ssh-access --quiet
\`\`\`

## Support

- **Documentation**: See project documentation
- **Issues**: Report issues on GitHub
- **Community**: Join the GRC Toolkit community
EOF
    
    success "Setup summary generated: gcp-dev-setup-summary.md"
}

# Main execution
main() {
    echo ""
    log "Starting GCP development environment setup..."
    echo ""
    
    # Validate required environment variables
    if [ "$PROJECT_ID" = "your-project-id" ]; then
        error "Please set GCP_PROJECT_ID environment variable"
        echo "Example: export GCP_PROJECT_ID='your-actual-project-id'"
        exit 1
    fi
    
    # Run setup steps
    check_prerequisites
    setup_gcp_auth
    enable_apis
    create_artifact_registry
    create_gke_cluster
    get_cluster_credentials
    create_namespace
    create_secrets
    build_and_push_image
    deploy_application
    wait_for_deployment
    setup_monitoring
    get_application_url
    generate_summary
    
    echo ""
    echo -e "${GREEN}🎉 GCP Development Environment Setup Complete!${NC}"
    echo "=============================================="
    echo ""
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo "1. Check the setup summary: gcp-dev-setup-summary.md"
    echo "2. Access your application at the provided URL"
    echo "3. Set up monitoring dashboards"
    echo "4. Configure alerting rules"
    echo "5. Review the documentation"
    echo ""
    echo -e "${YELLOW}💰 Estimated monthly cost: ~\$75-125${NC}"
    echo -e "${YELLOW}⏰ Remember to clean up resources when done${NC}"
    echo ""
}

# Run main function
main "$@"
