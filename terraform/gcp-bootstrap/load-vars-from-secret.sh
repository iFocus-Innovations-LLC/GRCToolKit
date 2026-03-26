#!/usr/bin/env bash
# Load Terraform variables from a Google Secret Manager JSON payload.
# Use during deployment so project_id is not stored in git.
#
# Prereqs: gcloud auth (user or SA), Secret Manager API enabled on the project
# that HOLDS the secret (often the same GCP project you are bootstrapping).
#
# Secret payload format (plain JSON string in GSM):
#   {"project_id":"my-gcp-project","region":"us-central1","repository_id":"grc-toolkit"}
#
# Usage:
#   source ./load-vars-from-secret.sh
#   terraform plan
#
# Env overrides:
#   GCP_BOOTSTRAP_SECRET_NAME   (default: grc-toolkit-terraform-bootstrap)
#   GCP_BOOTSTRAP_LOOKUP_PROJECT (project id where the secret lives; else gcloud config)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRET_NAME="${GCP_BOOTSTRAP_SECRET_NAME:-grc-toolkit-terraform-bootstrap}"
LOOKUP_PROJECT="${GCP_BOOTSTRAP_LOOKUP_PROJECT:-}"

if [[ -z "${LOOKUP_PROJECT}" ]]; then
  LOOKUP_PROJECT="$(gcloud config get-value project 2>/dev/null || true)"
fi

if [[ -z "${LOOKUP_PROJECT}" ]]; then
  echo "load-vars-from-secret.sh: set GCP_BOOTSTRAP_LOOKUP_PROJECT or run: gcloud config set project YOUR_PROJECT" >&2
  exit 1
fi

JSON="$(gcloud secrets versions access latest --secret="${SECRET_NAME}" --project="${LOOKUP_PROJECT}")"

if command -v jq >/dev/null 2>&1; then
  export TF_VAR_project_id="$(echo "${JSON}" | jq -r '.project_id')"
  _region="$(echo "${JSON}" | jq -r '.region // empty')"
  _repo="$(echo "${JSON}" | jq -r '.repository_id // empty')"
  if [[ -n "${_region}" && "${_region}" != "null" ]]; then
    export TF_VAR_region="${_region}"
  fi
  if [[ -n "${_repo}" && "${_repo}" != "null" ]]; then
    export TF_VAR_repository_id="${_repo}"
  fi
else
  echo "load-vars-from-secret.sh: jq is required to parse the secret JSON" >&2
  exit 1
fi

if [[ -z "${TF_VAR_project_id}" || "${TF_VAR_project_id}" == "null" ]]; then
  echo "load-vars-from-secret.sh: secret missing .project_id" >&2
  exit 1
fi

echo "Loaded TF_VAR_project_id from Secret Manager secret '${SECRET_NAME}' (project ${LOOKUP_PROJECT})." >&2
