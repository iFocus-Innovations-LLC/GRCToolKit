# GRC Toolkit - nginx + Python LLM proxy for secure server-side API key handling
# Zero-trust: pinned multi-arch index digest, non-root user, slim Alpine 3.23 base (fewer pkgs/CVEs vs full alpine + curl install)
FROM nginx:1.30.0-alpine-slim@sha256:2fb5d772cea6ef1a8dab525df1b9485289eee167d26af9613fce27a12c060caa

# Install Python 3 for the LLM proxy server (keeps API keys server-side)
RUN apk add --no-cache python3 py3-pip && \
    rm -f /etc/nginx/conf.d/default.conf

# Copy our nginx config (listens on 8080, /health, proxies /api/llm/ to Python server on 8081)
COPY nginx.conf /etc/nginx/nginx.conf

# Static assets: served as-is (no API key injection for production - proxy handles keys)
WORKDIR /usr/share/nginx/html
COPY grctoolkit.html ./index.html
COPY ai-agent ./ai-agent/
COPY compliance-docs ./compliance-docs/
COPY oscal ./oscal/
COPY assets ./assets/

# Copy Python LLM proxy and requirements
COPY scripts/ansible-runner-api.py /app/ansible-runner-api.py
COPY scripts/requirements-local-demo.txt /app/requirements.txt
RUN pip3 install --no-cache-dir -r /app/requirements.txt && \
    mkdir -p /tmp/grc-oscal-reports && \
    chown nginx:nginx /tmp/grc-oscal-reports

# Copy startup script that launches both nginx and Python proxy
COPY scripts/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 550 /docker-entrypoint.sh

# Ensure nginx user can read files and write pid/cache
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /tmp /app

# Run as non-root (required by container hardening checks)
USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
