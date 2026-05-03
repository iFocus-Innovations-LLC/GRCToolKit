# Static GRC Toolkit - nginx serves the app on port 8080 for CI/CD compatibility
# Zero-trust: pinned multi-arch index digest, non-root user, slim Alpine 3.23 base (fewer pkgs/CVEs vs full alpine + curl install)
FROM nginx:1.30.0-alpine-slim@sha256:2fb5d772cea6ef1a8dab525df1b9485289eee167d26af9613fce27a12c060caa

RUN rm -f /etc/nginx/conf.d/default.conf

# Copy our nginx config (listens on 8080, /health, security headers)
COPY nginx.conf /etc/nginx/nginx.conf

# Static assets: template is rendered to index.html on container start (API key injection).
WORKDIR /usr/share/nginx/html
COPY grctoolkit.html ./index.html.template
COPY scripts/docker-entrypoint.sh /docker-entrypoint.sh
RUN chown nginx:nginx /docker-entrypoint.sh && chmod 550 /docker-entrypoint.sh
COPY ai-agent ./ai-agent/
COPY compliance-docs ./compliance-docs/
COPY oscal ./oscal/

# Ensure nginx user can read files and write pid/cache
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /tmp

# Run as non-root (required by container hardening checks)
USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
