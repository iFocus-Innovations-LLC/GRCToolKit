#!/usr/bin/env bash
# Grant least-privilege IAM so Terraform in terraform/gcp-bootstrap can enable APIs
# and manage Artifact Registry. Requires the caller to have roles/resourcemanager.projectIamAdmin
# or Owner on the project.
#
# Usage:
#   GCP_PROJECT_ID=my-proj ./scripts/grant-bootstrap-iam.sh
#   ./scripts/grant-bootstrap-iam.sh my-proj
#
# Optional: target a specific principal (default: current gcloud account):
#   BOOTSTRAP_IAM_MEMBER="user:you@example.com" GCP_PROJECT_ID=my-proj ./scripts/grant-bootstrap-iam.sh
#   BOOTSTRAP_IAM_MEMBER="serviceAccount:tf@my-proj.iam.gserviceaccount.com" GCP_PROJECT_ID=my-proj ./scripts/grant-bootstrap-iam.sh

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-${1:-}}"
MEMBER="${BOOTSTRAP_IAM_MEMBER:-}"

if [[ -z "$PROJECT_ID" ]]; then
  echo "error: set GCP_PROJECT_ID or pass project ID as first argument." >&2
  echo "  GCP_PROJECT_ID=my-proj ./scripts/grant-bootstrap-iam.sh" >&2
  exit 1
fi

if ! command -v gcloud &>/dev/null; then
  echo "error: gcloud is not installed or not on PATH." >&2
  exit 1
fi

if [[ -z "$MEMBER" ]]; then
  account="$(gcloud config get-value account 2>/dev/null || true)"
  if [[ -z "$account" || "$account" == "(unset)" ]]; then
    echo "error: no gcloud account; run gcloud auth login or set BOOTSTRAP_IAM_MEMBER." >&2
    exit 1
  fi
  MEMBER="user:${account}"
fi

readonly ROLES=(
  roles/serviceusage.serviceUsageAdmin
  roles/artifactregistry.admin
)

echo "Granting bootstrap roles on project ${PROJECT_ID} to ${MEMBER}"
for role in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="$MEMBER" \
    --role="$role" \
    --quiet
done

echo "Done. Retry: cd terraform/gcp-bootstrap && terraform init && terraform apply"
