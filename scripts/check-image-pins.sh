#!/bin/bash

set -euo pipefail

fail=0

echo "🔍 Checking Dockerfile base image pin..."
if ! grep -qE '^FROM [^ ]+@sha256:' Dockerfile; then
  echo "❌ Dockerfile base image must be pinned with @sha256 digest"
  fail=1
fi

if grep -qE '^FROM .+:latest(\s|$)' Dockerfile; then
  echo "❌ Dockerfile must not use :latest"
  fail=1
fi

echo "🔍 Checking Kubernetes image references..."
if [ -d k8s ]; then
  while IFS= read -r line; do
    image_ref=$(echo "$line" | awk '{print $2}' | tr -d '"')
    if [[ -z "$image_ref" ]]; then
      continue
    fi
    if [[ "$image_ref" == *"PROJECT_ID"* ]]; then
      echo "❌ Kubernetes image reference contains PROJECT_ID placeholder: $image_ref"
      fail=1
    fi
    if [[ "$image_ref" == *":latest" ]]; then
      echo "❌ Kubernetes image reference must not use :latest: $image_ref"
      fail=1
    fi
  done < <(grep -R "image:" k8s/*.yaml 2>/dev/null || true)
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "✅ Image pin checks passed"
