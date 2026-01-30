# Use a pinned, reproducible nginx base image (avoid floating tags)
FROM nginx:alpine@sha256:b2e814d28359e77bd0aa5fed1939620075e4ffa0eb20423cc557b375bd5c14ad

# Set version label
LABEL version="2.1.0-dev" \
      maintainer="iFocus Innovations LLC" \
      description="GRC Toolkit with OSCAL and PQC Migration Features"

# Set version label
LABEL version="2.1.0-dev" \
      maintainer="iFocus Innovations LLC" \
      description="GRC Toolkit with OSCAL and PQC Migration Features"

# Set working directory
WORKDIR /usr/share/nginx/html

# Copy the HTML file and any static assets
COPY grctoolkit.html /usr/share/nginx/html/grctoolkit.html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy startup and graceful shutdown scripts
COPY startup.sh /usr/local/bin/startup.sh
COPY graceful-shutdown.sh /usr/local/bin/graceful-shutdown.sh
RUN chmod +x /usr/local/bin/startup.sh /usr/local/bin/graceful-shutdown.sh

# Create a non-root user for security and set proper permissions
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G appgroup -g appgroup appuser && \
    chown -R appuser:appgroup /usr/share/nginx/html && \
    chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/log/nginx && \
    chown -R appuser:appgroup /etc/nginx/conf.d && \
    mkdir -p /tmp && \
    chown -R appuser:appgroup /tmp && \
    chmod 755 /tmp

# Expose port 8080
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Switch to non-root user
USER appuser

# Start with our custom startup script
CMD ["/usr/local/bin/startup.sh"]
