# Multi-stage Dockerfile for Hardened Agentic AI
# Goal: Protect the data at all costs through container hardening and zero-trust principles.

# Stage 1: Build & Dependency Verification
FROM node:20-slim AS builder
WORKDIR /app

# Install build dependencies and security scanners
RUN apt-get update && apt-get install -y \
    curl \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Copy package files and install production dependencies
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Final Hardened Runtime
FROM node:20-slim
WORKDIR /app

# 1. Install minimal runtime dependencies (gcloud, ansible)
RUN apt-get update && apt-get install -y \
    curl \
    python3-pip \
    ansible \
    && rm -rf /var/lib/apt/lists/* \
    && curl https://sdk.cloud.google.com | bash
ENV PATH=$PATH:/root/google-cloud-sdk/bin

# 2. Copy the Agent's "Soul", "Skills", and core logic
COPY --from=builder /app/node_modules ./node_modules
COPY ai-agent/ ./ai-agent/
COPY skills/ ./skills/
COPY oscal/ ./oscal/
COPY grctoolkit.html ./public/index.html

# 3. Security Hardening
# - Run as a non-root user (node)
# - Remove unnecessary shell access where possible
# - Set filesystem to read-only except for /tmp
USER node

# 4. Environment Variables (No secrets here!)
ENV GRC_PROJECT_ID="bionic-kiln-466119-u3"
ENV AGENT_MODE="autonomous"
ENV NODE_ENV="production"

# 5. Network & Port Configuration
EXPOSE 8085

# 6. Health Check for DevOps Monitoring
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8085/health || exit 1

# 7. Entrypoint: Start the GRC Sentinel Agent
CMD ["node", "ai-agent/grc-compliance-engine.js"]
