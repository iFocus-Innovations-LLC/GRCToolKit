#!/bin/bash

# Script to update the GEMINI API key in Kubernetes Secret
# Usage: ./scripts/update-secret.sh "YOUR_GEMINI_API_KEY"

set -e

if [ -z "$1" ]; then
    echo "❌ Error: Please provide your GEMINI API key"
    echo "Usage: ./scripts/update-secret.sh \"YOUR_GEMINI_API_KEY\""
    exit 1
fi

API_KEY="$1"
NAMESPACE="grc-toolkit"

echo "🔐 Updating GEMINI API key in Kubernetes Secret..."

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "📝 Creating namespace $NAMESPACE..."
    kubectl create namespace "$NAMESPACE"
fi

# Create or update the secret
kubectl create secret generic grc-toolkit-secrets \
    --from-literal=gemini-api-key="$API_KEY" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secret updated successfully!"
echo "🚀 You can now deploy the application with: ./scripts/deploy.sh"
