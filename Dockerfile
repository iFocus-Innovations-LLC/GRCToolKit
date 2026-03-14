# Static GRC Toolkit - nginx serves the app on port 8080 for CI/CD compatibility
# Zero-trust: pinned base image, non-root user, minimal attack surface
FROM nginx:1.26-alpine@sha256:1eadbb07820339e8bbfed18c771691970baee292ec4ab2558f1453d26153e22d

# Install curl for HEALTHCHECK (Alpine minimal image may not include it)
RUN apk add --no-cache curl \
    && rm -f /etc/nginx/conf.d/default.conf

# Copy our nginx config (listens on 8080, /health, security headers)
COPY nginx.conf /etc/nginx/nginx.conf

# Copy static assets to nginx html root
WORKDIR /usr/share/nginx/html
COPY grctoolkit.html ./index.html
COPY ai-agent ./ai-agent/
COPY compliance-docs ./compliance-docs/
COPY oscal ./oscal/

# Ensure nginx user can read files and write pid/cache
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /tmp

# Run as non-root (required by container hardening checks)
USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://127.0.0.1:8080/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
