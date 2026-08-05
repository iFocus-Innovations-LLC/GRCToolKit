#!/bin/bash

# Container Testing Script for GRC Toolkit
# This script tests the Docker container locally

set -e

HOST_PORT="${TEST_CONTAINER_PORT:-8080}"

echo "🧪 Testing GRC Toolkit Container..."


# Build the Docker image
echo "🔨 Building Docker image..."
docker build -t grc-toolkit:test .

# Run the container (inject multi-LLM placeholders like docker-entrypoint / Community BYOK)
echo "🚀 Starting container..."
TEST_TOKEN="${TEST_API_TOKEN:-test-placeholder}"
docker run -d --name grc-toolkit-test -p "${HOST_PORT}:8080" \
  -e LLM_PROVIDER="${LLM_PROVIDER:-gemini}" \
  -e GEMINI_API_KEY="${GEMINI_API_KEY:-$TEST_TOKEN}" \
  -e OPENAI_API_KEY="${OPENAI_API_KEY:-}" \
  -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
  -e GROQ_API_KEY="${GROQ_API_KEY:-}" \
  -e VERTEX_API_KEY="${VERTEX_API_KEY:-}" \
  grc-toolkit:test

# Wait for container to be ready
echo "⏳ Waiting for container to be ready..."
sleep 10

# Test health endpoint
echo "🏥 Testing health endpoint..."
if curl -f "http://localhost:${HOST_PORT}/health"; then
    echo "✅ Health check passed!"
else
    echo "❌ Health check failed!"
    docker logs grc-toolkit-test
    docker stop grc-toolkit-test
    docker rm grc-toolkit-test
    exit 1
fi

# Test main page
echo "🌐 Testing main page..."
if curl -f "http://localhost:${HOST_PORT}/"; then
    echo "✅ Main page loads successfully!"
else
    echo "❌ Main page failed to load!"
    docker logs grc-toolkit-test
    docker stop grc-toolkit-test
    docker rm grc-toolkit-test
    exit 1
fi

# Test that the page contains expected content + multi-LLM BYOK wiring
echo "📄 Testing page content..."
PAGE_HTML=$(curl -s "http://localhost:${HOST_PORT}/")
if echo "$PAGE_HTML" | grep -qiE "grctoolkit|GRC Toolkit"; then
    echo "✅ Page contains expected content!"
else
    echo "❌ Page content validation failed!"
    docker logs grc-toolkit-test
    docker stop grc-toolkit-test
    docker rm grc-toolkit-test
    exit 1
fi

echo "🔑 Testing multi-LLM placeholder substitution..."
for ph in __LLM_PROVIDER__ __GEMINI_API_KEY__ __OPENAI_API_KEY__ __ANTHROPIC_API_KEY__ __GROQ_API_KEY__ __VERTEX_API_KEY__; do
  if echo "$PAGE_HTML" | grep -Fq "$ph"; then
    echo "❌ Placeholder still present: $ph"
    docker logs grc-toolkit-test
    docker stop grc-toolkit-test
    docker rm grc-toolkit-test
    exit 1
  fi
done
echo "✅ BYOK placeholders substituted"

if echo "$PAGE_HTML" | grep -q "llm-providers.js" && echo "$PAGE_HTML" | grep -q 'id="llmProviderSelect"'; then
    echo "✅ LLM provider adapter + picker present"
else
    echo "❌ llm-providers.js or llmProviderSelect missing"
    docker stop grc-toolkit-test
    docker rm grc-toolkit-test
    exit 1
fi

echo "📦 Checking llm-providers.js asset..."
if curl -sf "http://localhost:${HOST_PORT}/ai-agent/llm-providers.js" | grep -q "analyzeScenario"; then
    echo "✅ llm-providers.js served"
else
    echo "❌ llm-providers.js not served from container"
    docker stop grc-toolkit-test
    docker rm grc-toolkit-test
    exit 1
fi

# Test security headers
echo "🔒 Testing security headers..."
HEADERS=$(curl -s -I "http://localhost:${HOST_PORT}/")
if echo "$HEADERS" | grep -q "X-Frame-Options"; then
    echo "✅ Security headers present!"
else
    echo "❌ Security headers missing!"
fi

# Clean up
echo "🧹 Cleaning up..."
docker stop grc-toolkit-test
docker rm grc-toolkit-test

echo "🎉 All tests passed! Container is ready for deployment."
