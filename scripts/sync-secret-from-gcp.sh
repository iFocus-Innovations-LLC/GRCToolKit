#!/bin/bash

# Sync GEMINI_API_KEY from GCP Secret Manager to Kubernetes
# Requires: gcloud, kubectl, Secret Manager API enabled
# Usage: ./scripts/sync-secret-from-gcp.sh [SECRET_NAME]

set -e

SECRET_NAME="${1:-gemini-api-key}"
PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
NAMESPACE="grc-toolkit"

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: Set GCP_PROJECT_ID or run: gcloud config set project YOUR_PROJECT"
    exit 1
fi

echo "🔐 Syncing secret from GCP Secret Manager..."
echo "   Project: $PROJECT_ID"
echo "   Secret:  $SECRET_NAME"

# Fetch secret value from GCP (never echo it)
API_KEY=$(gcloud secrets versions access latest --secret="$SECRET_NAME" --project="$PROJECT_ID" 2>/dev/null) || {
    echo "❌ Secret '$SECRET_NAME' not found. Create it with:"
    echo "   echo -n 'YOUR_KEY' | gcloud secrets create $SECRET_NAME --data-file=- --project=$PROJECT_ID"
    exit 1
}

API_KEY_TRIM="${API_KEY#"${API_KEY%%[![:space:]]*}"}"
API_KEY_TRIM="${API_KEY_TRIM%"${API_KEY_TRIM##*[![:space:]]}"}"
if [ -z "$API_KEY_TRIM" ]; then
    echo "❌ Error: Secret Manager version for '$SECRET_NAME' is empty or whitespace only." >&2
    echo "   Add a new version: echo -n 'YOUR_KEY' | gcloud secrets versions add $SECRET_NAME --data-file=- --project=$PROJECT_ID"
    exit 1
fi
API_KEY="$API_KEY_TRIM"

# Ensure namespace exists
kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

# Create or update K8s secret
kubectl create secret generic grc-toolkit-secrets \
    --from-literal=gemini-api-key="$API_KEY" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secret synced successfully!"
