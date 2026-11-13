# Multi-stage build to eliminate vendored/bundled vulnerable packages
# Stage 1: Builder with dependencies
FROM ubuntu:24.04@sha256:0d5255be560e2d2ddcfbfda88549e9e815ef29e7cd7fc62183d5709e6e2963c6 AS builder

# Install Python, venv, and wget for bootstrapping pip
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-venv \
        wget \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
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
FROM ubuntu:24.04@sha256:0d5255be560e2d2ddcfbfda88549e9e815ef29e7cd7fc62183d5709e6e2963c6

# Install only runtime dependencies: nginx, python3, curl for healthcheck
# nginx-light is a minimal variant without unnecessary modules
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx-light \
        python3 \
        curl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* && \
    rm -f /etc/nginx/sites-enabled/default

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
    chown www-data:www-data /tmp/grc-oscal-reports

# Copy startup script that launches both nginx and Python proxy
COPY scripts/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 550 /docker-entrypoint.sh && \
    chown www-data:www-data /docker-entrypoint.sh

# Ensure www-data user can read files and write pid/cache
# Ubuntu nginx uses www-data instead of nginx user
RUN chown -R www-data:www-data /usr/share/nginx/html /var/log/nginx /tmp /app /opt/venv && \
    chown -R www-data:www-data /var/lib/nginx && \
    mkdir -p /var/cache/nginx && \
    chown -R www-data:www-data /var/cache/nginx

# Run as non-root (required by container hardening checks)
# Ubuntu nginx default user is www-data
USER www-data

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
