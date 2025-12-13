#!/bin/bash

# GRC Toolkit Deployment Script for GCP Kubernetes
# Usage: ./scripts/deploy.sh [staging|production]

set -e

ENVIRONMENT=${1:-staging}
PROJECT_ID=${GCP_PROJECT_ID:-"your-project-id"}
CLUSTER_NAME=${GKE_CLUSTER_NAME:-"grc-toolkit-cluster"}
REGION=${GCP_REGION:-"us-central1"}
GAR_LOCATION=${GAR_LOCATION:-"us-central1"}
REPOSITORY=${REPOSITORY:-"grc-toolkit"}
SERVICE=${SERVICE:-"grc-toolkit"}

echo "🚀 Deploying GRC Toolkit to $ENVIRONMENT environment..."

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    echo "❌ Error: Environment must be 'staging' or 'production'"
    exit 1
fi

# Set image tag based on environment
if [[ "$ENVIRONMENT" == "production" ]]; then
    IMAGE_TAG="latest"
else
    IMAGE_TAG="develop"
fi

IMAGE_URL="$GAR_LOCATION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/$SERVICE:$IMAGE_TAG"

echo "📦 Using image: $IMAGE_URL"

# Authenticate with GCP
echo "🔐 Authenticating with GCP..."
gcloud auth login
gcloud config set project $PROJECT_ID

# Configure Docker for GAR
echo "🐳 Configuring Docker for Google Artifact Registry..."
gcloud auth configure-docker $GAR_LOCATION-docker.pkg.dev

# Get cluster credentials
echo "☸️  Getting GKE cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID

# Update deployment with correct image
echo "📝 Updating deployment manifest..."
sed -i.bak "s|gcr.io/PROJECT_ID/grc-toolkit:latest|$IMAGE_URL|g" k8s/deployment.yaml

# Apply Kubernetes manifests
echo "🚀 Applying Kubernetes manifests..."

# Apply base resources
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Apply environment-specific resources
if [[ "$ENVIRONMENT" == "production" ]]; then
    echo "🏭 Applying production-specific resources..."
    kubectl apply -f k8s/ingress.yaml
    kubectl apply -f k8s/hpa.yaml
fi

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/grc-toolkit -n grc-toolkit --timeout=300s

# Verify deployment
echo "✅ Verifying deployment..."
kubectl get pods -n grc-toolkit
kubectl get services -n grc-toolkit

# Run health check
echo "🏥 Running health check..."
kubectl port-forward service/grc-toolkit-service 8080:80 -n grc-toolkit &
PORT_FORWARD_PID=$!
sleep 10

if curl -f http://localhost:8080/health; then
    echo "✅ Health check passed!"
else
    echo "❌ Health check failed!"
    kill $PORT_FORWARD_PID 2>/dev/null || true
    exit 1
fi

kill $PORT_FORWARD_PID 2>/dev/null || true

# Restore original deployment file
mv k8s/deployment.yaml.bak k8s/deployment.yaml

echo "🎉 Deployment to $ENVIRONMENT completed successfully!"

if [[ "$ENVIRONMENT" == "production" ]]; then
    echo "🌐 Application should be available at: https://grc-toolkit.yourdomain.com"
else
    echo "🔗 To access the application, run: kubectl port-forward service/grc-toolkit-service 8080:80 -n grc-toolkit"
    echo "🌐 Then visit: http://localhost:8080"
fi
