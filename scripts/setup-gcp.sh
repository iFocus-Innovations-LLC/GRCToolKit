#!/bin/bash

# GCP Setup Script for GRC Toolkit
# This script sets up the necessary GCP resources for the GRC Toolkit

set -e

PROJECT_ID=${GCP_PROJECT_ID:-"your-project-id"}
CLUSTER_NAME=${GKE_CLUSTER_NAME:-"grc-toolkit-cluster"}
REGION=${GCP_REGION:-"us-central1"}
GAR_LOCATION=${GAR_LOCATION:-"us-central1"}
REPOSITORY=${REPOSITORY:-"grc-toolkit"}

if [[ "${PROJECT_ID}" == "your-project-id" ]]; then
    echo "error: Set GCP_PROJECT_ID to your real project id before running this script."
    exit 1
fi

echo "🏗️  Setting up GCP resources for GRC Toolkit..."

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is not installed. Please install it first."
    exit 1
fi

# Authenticate with GCP
echo "🔐 Authenticating with GCP..."
gcloud auth login
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "🔌 Enabling required GCP APIs..."
gcloud services enable container.googleapis.com --project="$PROJECT_ID"
gcloud services enable artifactregistry.googleapis.com --project="$PROJECT_ID"
gcloud services enable compute.googleapis.com --project="$PROJECT_ID"
gcloud services enable dns.googleapis.com --project="$PROJECT_ID"

# Create Google Artifact Registry repository
echo "📦 Creating Google Artifact Registry repository..."
gcloud artifacts repositories create $REPOSITORY \
    --repository-format=docker \
    --location=$GAR_LOCATION \
    --project="$PROJECT_ID" \
    --description="GRC Toolkit Docker repository" \
    --quiet || echo "Repository already exists"

# Create GKE cluster (regional Standard — matches ci-cd get-credentials --region)
echo "☸️  Creating GKE cluster..."
gcloud container clusters create "$CLUSTER_NAME" \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --release-channel=regular \
    --num-nodes=3 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=10 \
    --enable-autorepair \
    --enable-autoupgrade \
    --machine-type=e2-medium \
    --disk-size=20 \
    --disk-type=pd-standard \
    --enable-network-policy \
    --enable-ip-alias \
    --addons=HttpLoadBalancing,HorizontalPodAutoscaling \
    --quiet || echo "Cluster already exists"

# Get cluster credentials
echo "🔑 Getting cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" \
    --region="$REGION" --project="$PROJECT_ID"

# Configure kubectl
echo "⚙️  Configuring kubectl..."
kubectl config current-context

# Namespace required before GKE ManagedCertificate in that namespace
echo "📁 Creating namespace..."
kubectl create namespace grc-toolkit || echo "Namespace already exists"

# Create static IP for production
echo "🌐 Creating static IP address..."
gcloud compute addresses create grc-toolkit-ip \
    --global \
    --project="$PROJECT_ID" \
    --quiet || echo "Static IP already exists"

# Get the static IP address
STATIC_IP=$(gcloud compute addresses describe grc-toolkit-ip --global --project="$PROJECT_ID" --format="value(address)")
echo "📍 Static IP address: $STATIC_IP"

# Create managed SSL certificate
echo "🔒 Creating managed SSL certificate..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: grc-toolkit-ssl-cert
  namespace: grc-toolkit
spec:
  domains:
    - grc-toolkit.yourdomain.com  # Replace with your actual domain
EOF

echo "✅ GCP setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Update the domain in k8s/ingress.yaml and the managed certificate above"
echo "2. Point your domain's DNS to the static IP: $STATIC_IP"
echo "3. Run './scripts/deploy.sh production' to deploy the application"
echo ""
echo "🔧 Useful commands:"
echo "- View cluster: gcloud container clusters describe $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID"
echo "- Get credentials: gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID"
echo "- View pods: kubectl get pods -n grc-toolkit"
echo "- View services: kubectl get services -n grc-toolkit"
