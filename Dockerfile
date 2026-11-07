# Multi-stage build to eliminate vendored/bundled vulnerable packages
# Stage 1: Builder with dependencies
FROM nginx:1.31.8-alpine-slim@sha256:9c68ad4f28e7dee4b9484a7859bf451da39ef661bcd038ef62e87593fcd91c86 AS builder

# Install Python and build dependencies
RUN apk add --no-cache python3 wget && \
    python3 -m venv /opt/venv

# Bootstrap pip and install app dependencies
COPY scripts/requirements-local-demo.txt /tmp/requirements.txt
RUN wget -q https://bootstrap.pypa.io/get-pip.py && \
    /opt/venv/bin/python get-pip.py && \
    rm get-pip.py && \
    /opt/venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Remove pip's vendored packages and bundled wheels to eliminate stale CVEs
# These are not needed at runtime, only during pip install
RUN find /opt/venv -type d -name "_vendor" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/venv -type d -name "_bundled" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/venv -type f -name "*.whl" -delete 2>/dev/null || true && \
    rm -rf /opt/venv/lib/python*/site-packages/pip 2>/dev/null || true

# Stage 2: Final runtime image
FROM nginx:1.31.8-alpine-slim@sha256:9c68ad4f28e7dee4b9484a7859bf451da39ef661bcd038ef62e87593fcd91c86

# Install only Python runtime (no pip, no build tools)
RUN apk add --no-cache python3 && \
    rm -f /etc/nginx/conf.d/default.conf

# Copy only the installed packages from builder (no pip, no vendored packages)
COPY --from=builder /opt/venv /opt/venv

# Copy our nginx config (listens on 8080, /health, proxies /api/llm/ to Python server on 8081)
COPY nginx.conf /etc/nginx/nginx.conf

# Static assets: served as-is (no API key injection for production - proxy handles keys)
WORKDIR /usr/share/nginx/html
COPY grctoolkit.html ./index.html
COPY ai-agent ./ai-agent/
COPY compliance-docs ./compliance-docs/
COPY oscal ./oscal/
COPY assets ./assets/

# Copy Python LLM proxy (dependencies already installed in builder stage)
COPY scripts/ansible-runner-api.py /app/ansible-runner-api.py
RUN mkdir -p /tmp/grc-oscal-reports && \
    chown nginx:nginx /tmp/grc-oscal-reports

# Copy startup script that launches both nginx and Python proxy
COPY scripts/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 550 /docker-entrypoint.sh && \
    chown nginx:nginx /docker-entrypoint.sh

# Ensure nginx user can read files and write pid/cache
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /tmp /app /opt/venv

# Run as non-root (required by container hardening checks)
USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
