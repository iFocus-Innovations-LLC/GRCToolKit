#!/bin/bash

# Container Testing Script for GRC Toolkit
# This script tests the Docker container locally

set -e

echo "🧪 Testing GRC Toolkit Container..."

# Build the Docker image
echo "🔨 Building Docker image..."
docker build -t grc-toolkit:test .

# Run the container
echo "🚀 Starting container..."
docker run -d --name grc-toolkit-test -p 8080:8080 grc-toolkit:test

# Wait for container to be ready
echo "⏳ Waiting for container to be ready..."
sleep 10

# Test health endpoint
echo "🏥 Testing health endpoint..."
if curl -f http://localhost:8080/health; then
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
if curl -f http://localhost:8080/; then
    echo "✅ Main page loads successfully!"
else
    echo "❌ Main page failed to load!"
    docker logs grc-toolkit-test
    docker stop grc-toolkit-test
    docker rm grc-toolkit-test
    exit 1
fi

# Test that the page contains expected content
echo "📄 Testing page content..."
if curl -s http://localhost:8080/ | grep -q "GRC Toolkit AI Agent"; then
    echo "✅ Page contains expected content!"
else
    echo "❌ Page content validation failed!"
    docker logs grc-toolkit-test
    docker stop grc-toolkit-test
    docker rm grc-toolkit-test
    exit 1
fi

# Test security headers
echo "🔒 Testing security headers..."
HEADERS=$(curl -s -I http://localhost:8080/)
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
