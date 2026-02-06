# GRC Toolkit - Containerized Deployment Guide

This guide covers deploying the GRC Toolkit application to Google Cloud Platform (GCP) using Kubernetes.

## 🏗️ Architecture Overview

The application is containerized using Docker and deployed on Google Kubernetes Engine (GKE) with the following components:

- **Frontend**: Nginx serving the static HTML application
- **Container Registry**: Google Artifact Registry for Docker images
- **Orchestration**: Kubernetes for container orchestration
- **Load Balancing**: GKE Ingress with SSL termination
- **Auto-scaling**: Horizontal Pod Autoscaler (HPA)
- **CI/CD**: GitHub Actions for automated testing and deployment

## 📋 Prerequisites

### Required Tools
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Docker](https://docs.docker.com/get-docker/)
- [Git](https://git-scm.com/downloads)

### GCP Requirements
- GCP Project with billing enabled
- Required APIs enabled (handled by setup script)
- Domain name for production deployment (optional for staging)

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd GRCToolKit
```

### 2. Configure Environment Variables

```bash
export GCP_PROJECT_ID="your-project-id"
export GKE_CLUSTER_NAME="grc-toolkit-cluster"
export GCP_REGION="us-central1"
export GCP_ZONE="us-central1-a"
```

### 3. Setup GCP Resources

```bash
./scripts/setup-gcp.sh
```

This script will:
- Enable required GCP APIs
- Create Google Artifact Registry repository
- Create GKE cluster with auto-scaling
- Create static IP address
- Setup managed SSL certificate
- Create Kubernetes namespace

### 4. Deploy Application

#### Staging Deployment
```bash
./scripts/deploy.sh staging
```

#### Production Deployment
```bash
./scripts/deploy.sh production
```

## 🔧 Manual Deployment Steps

### 1. Build and Push Docker Image

```bash
# Build the image
docker build -t grc-toolkit .

# Tag for GAR
docker tag grc-toolkit us-central1-docker.pkg.dev/PROJECT_ID/grc-toolkit/grc-toolkit:latest

# Push to registry
docker push us-central1-docker.pkg.dev/PROJECT_ID/grc-toolkit/grc-toolkit:latest
```

### 2. Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml

# Check deployment status
kubectl rollout status deployment/grc-toolkit -n grc-toolkit
```

## 🔄 CI/CD Pipeline

The GitHub Actions workflow automatically:

### On Pull Request:
- Builds Docker image
- Runs security scans with Trivy
- Tests the application
- Validates Kubernetes manifests

### On Push to `develop`:
- Builds and pushes image to GAR
- Deploys to staging environment
- Runs smoke tests

### On Push to `main`:
- Builds and pushes image to GAR
- Deploys to production environment
- Runs comprehensive tests
- Sends deployment notifications

### Required GitHub Secrets:
- `GCP_PROJECT_ID`: Your GCP project ID
- `GCP_SA_KEY`: Service account key JSON
- `GKE_CLUSTER_NAME`: Name of your GKE cluster

## 📊 Monitoring and Observability

### Health Checks
- **Liveness Probe**: `/health` endpoint every 10 seconds
- **Readiness Probe**: `/health` endpoint every 5 seconds
- **Health Endpoint**: Returns 200 OK when healthy

### Logging
```bash
# View application logs
kubectl logs -f deployment/grc-toolkit -n grc-toolkit

# View nginx logs
kubectl logs -f deployment/grc-toolkit -n grc-toolkit -c grc-toolkit
```

### Metrics
```bash
# View pod metrics
kubectl top pods -n grc-toolkit

# View node metrics
kubectl top nodes
```

## 🔒 Security Features

### Container Security
- Non-root user (UID 1001)
- Read-only root filesystem
- Dropped all capabilities
- Security context constraints

### Network Security
- Network policies enabled
- SSL/TLS termination at ingress
- Security headers configured
- CSP (Content Security Policy) implemented

### Image Security
- Regular security scans with Trivy
- Minimal base image (nginx:alpine)
- No unnecessary packages
- Regular updates via CI/CD

## 🎛️ Configuration

### Environment Variables
Configured via ConfigMap:
- `APP_NAME`: Application name
- `APP_VERSION`: Application version

### Resource Limits
- **CPU**: 50m request, 100m limit
- **Memory**: 64Mi request, 128Mi limit
- **Auto-scaling**: 2-10 replicas based on CPU/memory usage

### Customization
Update the following files for your environment:
- `k8s/ingress.yaml`: Domain name and SSL configuration
- `k8s/deployment.yaml`: Resource limits and environment variables
- `scripts/setup-gcp.sh`: GCP project and region settings

## 🚨 Troubleshooting

### Common Issues

#### Pod Not Starting
```bash
kubectl describe pod <pod-name> -n grc-toolkit
kubectl logs <pod-name> -n grc-toolkit
```

#### Service Not Accessible
```bash
kubectl get services -n grc-toolkit
kubectl get ingress -n grc-toolkit
```

#### Image Pull Errors
```bash
# Check image exists
gcloud artifacts docker images list us-central1-docker.pkg.dev/PROJECT_ID/grc-toolkit/grc-toolkit

# Verify authentication
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### Debug Commands
```bash
# Port forward for local testing
kubectl port-forward service/grc-toolkit-service 8080:80 -n grc-toolkit

# Access pod shell
kubectl exec -it <pod-name> -n grc-toolkit -- /bin/sh

# View events
kubectl get events -n grc-toolkit --sort-by='.lastTimestamp'
```

## 📈 Scaling

### Horizontal Scaling
The HPA automatically scales based on:
- CPU utilization (70% threshold)
- Memory utilization (80% threshold)

### Manual Scaling
```bash
# Scale deployment
kubectl scale deployment grc-toolkit --replicas=5 -n grc-toolkit

# Update HPA
kubectl patch hpa grc-toolkit-hpa -n grc-toolkit -p '{"spec":{"maxReplicas":20}}'
```

## 🔄 Updates and Rollbacks

### Rolling Updates
```bash
# Update image
kubectl set image deployment/grc-toolkit grc-toolkit=NEW_IMAGE -n grc-toolkit

# Check rollout status
kubectl rollout status deployment/grc-toolkit -n grc-toolkit
```

### Rollback
```bash
# View rollout history
kubectl rollout history deployment/grc-toolkit -n grc-toolkit

# Rollback to previous version
kubectl rollout undo deployment/grc-toolkit -n grc-toolkit
```

## 💰 Cost Optimization

### Resource Optimization
- Use appropriate machine types (e2-medium)
- Set proper resource requests and limits
- Enable cluster autoscaling
- Use preemptible nodes for non-production

### Storage Optimization
- Use standard persistent disks
- Implement log rotation
- Clean up old images in registry

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Kubernetes and GCP documentation
3. Check application logs and events
4. Contact your DevOps team

## 🔗 Useful Links

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Google Artifact Registry](https://cloud.google.com/artifact-registry/docs)
- [Nginx Configuration](https://nginx.org/en/docs/)
