#!/usr/bin/env bash
# GRC Toolkit deployment to GKE (flat k8s/ manifests).
#
# Prerequisites (GCP project admin or equivalent): APIs enabled, cluster exists,
# account can push/pull GAR and kubectl apply as needed.
#
# Configuration from the environment or a secrets file — never commit real values.
#
# Usage:
#   ./scripts/deploy.sh [options] [staging|production]
#   GRC_DEPLOY_ENV_FILE=./grc-deploy.env GRC_DEPLOY_SILENT=1 ./scripts/deploy.sh staging
#
# Options:
#   --env-file PATH    Load KEY=value pairs (POSIX). Same as GRC_DEPLOY_ENV_FILE.
#   --cleanup-env-file Remove the env file on exit (after load). Use with secrets in a temp file.
#   --silent           Quiet output; skip interactive gcloud auth login. With --env-file, if the
#                      file lives under a temp directory (/tmp, $TMPDIR, /var/tmp), it is removed
#                      on exit so credentials are not left on disk.
#   --skip-gcloud-login   Skip gcloud auth login only (still logs unless --silent).

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/deploy.sh [options] [staging|production]

Options:
  --env-file PATH         Load config from a file (chmod 600 recommended)
  --cleanup-env-file      Delete the env file on exit (use for mktemp / secret injection)
  --silent                Minimal logging; skip interactive gcloud auth login; auto-removes env
                          file on exit if it resides under a temp directory (see header)
  --skip-gcloud-login     Do not run gcloud auth login (use existing credentials)
  -h, --help              Show this help

Required (environment or env file):
  GCP_PROJECT_ID          Real GCP project id (not the placeholder)
  GKE_CLUSTER_NAME        GKE cluster name
  GCP_REGION              Cluster region (e.g. us-central1)

Optional:
  GAR_LOCATION            Default us-central1
  REPOSITORY              Default grc-toolkit
  SERVICE                 Default grc-toolkit
  GEMINI_API_KEY          Or a valid k8s/secret.yaml (no REPLACE_ME)

Env file format: Each non-empty line must be KEY=value (comments start with #).
  Do not put a bare project id on a line — use GCP_PROJECT_ID=YOUR_PROJECT_ID

Example:
  cp scripts/grc-deploy.env.example grc-deploy.env
  # edit values; chmod 600 grc-deploy.env
  gcloud auth login   # once if not using --silent / skip login
  GRC_DEPLOY_ENV_FILE=./grc-deploy.env ./scripts/deploy.sh staging
EOF
}

ENVIRONMENT="staging"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file)
      GRC_DEPLOY_ENV_FILE="${2:-}"
      if [[ -z "${GRC_DEPLOY_ENV_FILE}" ]]; then
        echo "error: --env-file requires a path" >&2
        exit 1
      fi
      shift 2
      ;;
    --cleanup-env-file)
      GRC_DEPLOY_CLEANUP_ENV_FILE=1
      shift
      ;;
    --silent)
      GRC_DEPLOY_SILENT=1
      GRC_SKIP_GCLOUD_AUTH_LOGIN=1
      shift
      ;;
    --skip-gcloud-login)
      GRC_SKIP_GCLOUD_AUTH_LOGIN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    staging|production)
      ENVIRONMENT="$1"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "${GRC_DEPLOY_CLEANUP_ENV_FILE:-}" == "1" && -z "${GRC_DEPLOY_ENV_FILE:-}" ]]; then
  echo "error: --cleanup-env-file (or GRC_DEPLOY_CLEANUP_ENV_FILE=1) requires --env-file or GRC_DEPLOY_ENV_FILE" >&2
  exit 1
fi

load_env_file() {
  local f="$1" line linenum=0 key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    linenum=$((linenum + 1))
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" != *"="* ]]; then
      echo "error: ${f}:${linenum}: expected KEY=value; got a bare value (add the name, e.g. GCP_PROJECT_ID=${line})" >&2
      exit 1
    fi
    key="${line%%=*}"
    value="${line#*=}"
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      echo "error: ${f}:${linenum}: invalid variable name: ${key}" >&2
      exit 1
    fi
    export "${key}=${value}"
  done <"$f"
}

# True if the env file directory is a typical temp path (e.g. mktemp under TMPDIR, /tmp).
deploy_env_file_is_transient() {
  local f="$1" d t
  [[ -n "$f" ]] || return 1
  d="$(cd "$(dirname "$f")" && pwd -P)" || return 1
  [[ "$d" == /tmp || "$d" == /tmp/* ]] && return 0
  [[ "$d" == /var/tmp || "$d" == /var/tmp/* ]] && return 0
  t="${TMPDIR:-}"
  t="${t%/}"
  [[ -n "$t" && ( "$d" == "$t" || "$d" == "$t"/* ) ]] && return 0
  return 1
}

if [[ -n "${GRC_DEPLOY_ENV_FILE:-}" ]]; then
  if [[ ! -f "${GRC_DEPLOY_ENV_FILE}" ]]; then
    echo "error: env file not found: ${GRC_DEPLOY_ENV_FILE}" >&2
    exit 1
  fi
  load_env_file "${GRC_DEPLOY_ENV_FILE}"
fi

if [[ -n "${GRC_DEPLOY_SILENT:-}" && -n "${GRC_DEPLOY_ENV_FILE:-}" && -z "${GRC_DEPLOY_CLEANUP_ENV_FILE:-}" ]]; then
  if deploy_env_file_is_transient "${GRC_DEPLOY_ENV_FILE}"; then
    GRC_DEPLOY_CLEANUP_ENV_FILE=1
  fi
fi

say() {
  if [[ -z "${GRC_DEPLOY_SILENT:-}" ]]; then
    echo "$@"
  fi
}

# Trim leading/trailing whitespace (bash 3.2+)
trim_ws() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

if [[ -z "${GCP_PROJECT_ID:-}" ]]; then
  echo "error: GCP_PROJECT_ID is required (export it or use --env-file)" >&2
  exit 1
fi
if [[ "${GCP_PROJECT_ID}" == "your-project-id" ]]; then
  echo "error: GCP_PROJECT_ID must be a real project id, not the placeholder" >&2
  exit 1
fi
if [[ -z "${GKE_CLUSTER_NAME:-}" ]]; then
  echo "error: GKE_CLUSTER_NAME is required" >&2
  exit 1
fi
if [[ -z "${GCP_REGION:-}" ]]; then
  echo "error: GCP_REGION is required" >&2
  exit 1
fi

PROJECT_ID="${GCP_PROJECT_ID}"
CLUSTER_NAME="${GKE_CLUSTER_NAME}"
REGION="${GCP_REGION}"
GAR_LOCATION="${GAR_LOCATION:-us-central1}"
REPOSITORY="${REPOSITORY:-grc-toolkit}"
SERVICE="${SERVICE:-grc-toolkit}"

if [[ "${ENVIRONMENT}" != "staging" && "${ENVIRONMENT}" != "production" ]]; then
  echo "error: environment must be staging or production" >&2
  exit 1
fi

if [[ "${ENVIRONMENT}" == "production" ]]; then
  IMAGE_TAG="latest"
else
  IMAGE_TAG="develop"
fi

IMAGE_URL="${GAR_LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${SERVICE}:${IMAGE_TAG}"

say "Deploying GRC Toolkit to ${ENVIRONMENT}"
say "Image: ${IMAGE_URL}"

replace_in_deployment() {
  local old_pat='gcr.io/PROJECT_ID/grc-toolkit:latest'
  local new_url="${IMAGE_URL}"
  local f="k8s/deployment.yaml"
  if sed --version >/dev/null 2>&1; then
    sed -i.bak -e "s|${old_pat}|${new_url}|g" "${f}"
  else
    sed -i.bak '' -e "s|${old_pat}|${new_url}|g" "${f}"
  fi
}

restore_deployment() {
  if [[ -f k8s/deployment.yaml.bak ]]; then
    mv k8s/deployment.yaml.bak k8s/deployment.yaml
  fi
}

cleanup_deploy_exit() {
  restore_deployment
  if [[ "${GRC_DEPLOY_CLEANUP_ENV_FILE:-}" == "1" && -n "${GRC_DEPLOY_ENV_FILE:-}" && -f "${GRC_DEPLOY_ENV_FILE}" ]]; then
    rm -f "${GRC_DEPLOY_ENV_FILE}"
  fi
}

trap cleanup_deploy_exit EXIT

GCLOUD_QUIET=()
if [[ -n "${GRC_DEPLOY_SILENT:-}" ]]; then
  GCLOUD_QUIET=(--quiet)
fi

if [[ -z "${GRC_SKIP_GCLOUD_AUTH_LOGIN:-}" ]]; then
  say "Authenticating with GCP (interactive)..."
  gcloud auth login
else
  say "Skipping gcloud auth login (using existing credentials)"
fi

gcloud config set project "${PROJECT_ID}" "${GCLOUD_QUIET[@]}"

say "Configuring Docker credential helper for Artifact Registry..."
gcloud auth configure-docker "${GAR_LOCATION}-docker.pkg.dev" "${GCLOUD_QUIET[@]}"

say "Fetching GKE credentials..."
gcloud container clusters get-credentials "${CLUSTER_NAME}" \
  --region "${REGION}" --project "${PROJECT_ID}" "${GCLOUD_QUIET[@]}"

say "Patching deployment manifest image reference..."
replace_in_deployment

say "Applying Kubernetes resources..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml

GEMINI_TRIMMED="$(trim_ws "${GEMINI_API_KEY:-}")"
if [[ -n "${GEMINI_TRIMMED}" ]]; then
  say "Creating/updating gemini secret from GEMINI_API_KEY..."
  kubectl create secret generic grc-toolkit-secrets \
    --from-literal=gemini-api-key="${GEMINI_TRIMMED}" \
    --namespace=grc-toolkit \
    --dry-run=client -o yaml | kubectl apply -f -
elif [[ -f k8s/secret.yaml ]] && ! grep -q "REPLACE_ME" k8s/secret.yaml 2>/dev/null; then
  kubectl apply -f k8s/secret.yaml
elif kubectl get secret grc-toolkit-secrets -n grc-toolkit >/dev/null 2>&1; then
  say "Keeping existing Kubernetes secret grc-toolkit-secrets (no non-empty GEMINI_API_KEY in environment)."
  say "To rotate: export GEMINI_API_KEY, add it to your env file, use ./scripts/update-secret.sh, or ./scripts/sync-secret-from-gcp.sh"
else
  echo "error: No Gemini secret configured. Set non-empty GEMINI_API_KEY, use k8s/secret.yaml," >&2
  echo "       create the secret first (./scripts/update-secret.sh), or ./scripts/sync-secret-from-gcp.sh" >&2
  exit 1
fi

kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

if [[ "${ENVIRONMENT}" == "production" ]]; then
  say "Applying production ingress and HPA..."
  kubectl apply -f k8s/ingress.yaml
  kubectl apply -f k8s/hpa.yaml
fi

say "Waiting for rollout..."
kubectl rollout status deployment/grc-toolkit -n grc-toolkit --timeout=300s

kubectl get pods -n grc-toolkit
kubectl get svc -n grc-toolkit

say "Smoke test via port-forward..."
kubectl port-forward service/grc-toolkit-service 8080:80 -n grc-toolkit &
PORT_FORWARD_PID=$!
sleep 10
if curl -fsS --max-time 15 "http://localhost:8080/health" >/dev/null; then
  say "Health check OK"
else
  echo "error: health check failed" >&2
  kill "${PORT_FORWARD_PID}" 2>/dev/null || true
  exit 1
fi
kill "${PORT_FORWARD_PID}" 2>/dev/null || true

trap - EXIT
cleanup_deploy_exit

say "Deployment to ${ENVIRONMENT} completed."

if [[ "${ENVIRONMENT}" == "production" ]]; then
  say "Ingress: configure domain in k8s/ingress.yaml and DNS."
else
  say "Access: kubectl port-forward service/grc-toolkit-service 8080:80 -n grc-toolkit"
fi
