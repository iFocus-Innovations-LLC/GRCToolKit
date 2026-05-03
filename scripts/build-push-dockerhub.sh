#!/usr/bin/env bash
# Build and push to Docker Hub with a valid image name (namespace/repo:tag, repo has no '/').
# Runtime check prevents: cryptotronbot/grctoolkit-ai/grctoolkit-demo → insufficient_scope on Hub.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NAMESPACE="${DOCKERHUB_USER:-${DOCKERHUB_NAMESPACE:-}}"
REPO="${DOCKERHUB_REPO:-}"
TAG="${DOCKERHUB_TAG:-latest}"

if [[ -z "$NAMESPACE" || -z "$REPO" ]]; then
  echo "Usage: set namespace + single-segment repository name + tag, then run from repo root."
  echo "  DOCKERHUB_USER=cryptotronbot DOCKERHUB_REPO=grctoolkit-demo DOCKERHUB_TAG=v1 $0"
  echo ""
  echo "Docker Hub does not accept a second '/' inside the repository name."
  echo "Wrong:  cryptotronbot/grctoolkit-ai/grctoolkit-demo:v1"
  echo "Right:  cryptotronbot/grctoolkit-demo:v1"
  exit 1
fi

if [[ "$REPO" == */* ]]; then
  echo "ERROR: DOCKERHUB_REPO must be a single path segment (no '/'). Got: $REPO"
  exit 1
fi

IMAGE_REF="docker.io/${NAMESPACE}/${REPO}:${TAG}"
echo "Building and pushing: $IMAGE_REF"
docker build --push -t "$IMAGE_REF" .
