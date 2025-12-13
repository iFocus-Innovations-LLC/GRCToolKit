#!/bin/bash

# GCP Setup Script for GRC Toolkit
# This script sets up the necessary GCP resources for the GRC Toolkit

set -e

PROJECT_ID=${GCP_PROJECT_ID:-"your-project-id"}
CLUSTER_NAME=${GKE_CLUSTER_NAME:-"grc-toolkit-cluster"}
REGION=${GCP_REGION:-"us-central1"}
ZONE=${GCP_ZONE:-"us-central1-a"}
GAR_LOCATION=${GAR_LOCATION:-"us-central1"}
REPOSITORY=${REPOSITORY:-"grc-toolkit"}

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
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable dns.googleapis.com

# Create Google Artifact Registry repository
echo "📦 Creating Google Artifact Registry repository..."
gcloud artifacts repositories create $REPOSITORY \
    --repository-format=docker \
    --location=$GAR_LOCATION \
    --description="GRC Toolkit Docker repository" \
    --quiet || echo "Repository already exists"

# Create GKE cluster
echo "☸️  Creating GKE cluster..."
gcloud container clusters create $CLUSTER_NAME \
    --zone=$ZONE \
    --num-nodes=3 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=10 \
    --enable-autorepair \
    --enable-autoupgrade \
    --machine-type=e2-medium \
    --disk-size=20GB \
    --disk-type=pd-standard \
    --enable-network-policy \
    --enable-ip-alias \
    --quiet || echo "Cluster already exists"

# Get cluster credentials
echo "🔑 Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID

# Create static IP for production
echo "🌐 Creating static IP address..."
gcloud compute addresses create grc-toolkit-ip \
    --global \
    --quiet || echo "Static IP already exists"

# Get the static IP address
STATIC_IP=$(gcloud compute addresses describe grc-toolkit-ip --global --format="value(address)")
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

# Configure kubectl
echo "⚙️  Configuring kubectl..."
kubectl config current-context

# Create namespace
echo "📁 Creating namespace..."
kubectl create namespace grc-toolkit || echo "Namespace already exists"

echo "✅ GCP setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Update the domain in k8s/ingress.yaml and the managed certificate above"
echo "2. Point your domain's DNS to the static IP: $STATIC_IP"
echo "3. Run './scripts/deploy.sh production' to deploy the application"
echo ""
echo "🔧 Useful commands:"
echo "- View cluster: gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE"
echo "- Get credentials: gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE"
echo "- View pods: kubectl get pods -n grc-toolkit"
echo "- View services: kubectl get services -n grc-toolkit"
