#!/bin/bash

set -euo pipefail

fail=0

echo "🔍 Checking Dockerfile hardening..."

if ! grep -qE '^USER ' Dockerfile; then
  echo "❌ Dockerfile must define a non-root USER"
  fail=1
else
  if grep -qE '^USER (root|0)\b' Dockerfile; then
    echo "❌ Dockerfile USER must not be root"
    fail=1
  fi
fi

if ! grep -qE '^HEALTHCHECK ' Dockerfile; then
  echo "❌ Dockerfile should define a HEALTHCHECK"
  fail=1
fi

if ! grep -qE '^EXPOSE ' Dockerfile; then
  echo "❌ Dockerfile should declare an EXPOSE port"
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "✅ Container hardening checks passed"
