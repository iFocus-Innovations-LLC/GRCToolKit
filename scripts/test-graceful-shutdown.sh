#!/bin/bash

# Test script for graceful shutdown functionality
# Usage: ./scripts/test-graceful-shutdown.sh

set -e

echo "🧪 Testing graceful shutdown functionality..."

# Build the container with graceful shutdown
echo "🔨 Building container with graceful shutdown..."
docker build -t grc-toolkit-graceful .

# Start the container
echo "🚀 Starting container..."
TEST_TOKEN="${TEST_API_TOKEN:-test-placeholder}"
CONTAINER_ID=$(docker run -d -p 8083:8080 \
  -e LLM_PROVIDER=gemini \
  -e GEMINI_API_KEY="$TEST_TOKEN" \
  --name grc-toolkit-graceful-test grc-toolkit-graceful)

echo "⏳ Waiting for container to be ready..."
sleep 5

# Check if container is running
if ! docker ps | grep -q grc-toolkit-graceful-test; then
    echo "❌ Container failed to start"
    docker logs grc-toolkit-graceful-test
    exit 1
fi

echo "✅ Container started successfully"

# Test health endpoint
echo "🏥 Testing health endpoint..."
if curl -s http://localhost:8083/health | grep -q "healthy"; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
    docker logs grc-toolkit-graceful-test
    exit 1
fi

# Test graceful shutdown
echo "🛑 Testing graceful shutdown..."
echo "📝 Sending SIGTERM to container..."

# Send SIGTERM and monitor logs
timeout 15s docker logs -f grc-toolkit-graceful-test &
LOGS_PID=$!

# Send SIGTERM
docker stop grc-toolkit-graceful-test

# Wait for logs to finish
wait $LOGS_PID 2>/dev/null || true

# Check if container stopped gracefully
if ! docker ps -a | grep grc-toolkit-graceful-test | grep -q "Exited (0)"; then
    echo "❌ Container did not stop gracefully"
    docker logs grc-toolkit-graceful-test
    exit 1
fi

echo "✅ Graceful shutdown test passed!"

# Cleanup
echo "🧹 Cleaning up..."
docker rm grc-toolkit-graceful-test 2>/dev/null || true

echo "🎉 All graceful shutdown tests passed!"
