#!/bin/sh

# Graceful shutdown script for GRC Toolkit
# Handles SIGTERM signals and ensures clean shutdown

# Function to handle shutdown signals
shutdown_handler() {
    echo "🛑 Received shutdown signal, initiating graceful shutdown..."
    
    # Stop nginx gracefully
    if [ -n "$NGINX_PID" ]; then
        echo "📝 Stopping nginx gracefully..."
        nginx -s quit
        
        # Wait for nginx to stop gracefully
        wait $NGINX_PID 2>/dev/null
        echo "✅ Nginx stopped gracefully"
    fi
    
    # Clean up any temporary files
    echo "🧹 Cleaning up temporary files..."
    rm -f /usr/share/nginx/html/index.html
    
    echo "✅ Graceful shutdown completed"
    exit 0
}

# Set up signal handlers
trap shutdown_handler SIGTERM SIGINT SIGQUIT

# Start nginx in background and capture PID
echo "🚀 Starting nginx..."
nginx -g "daemon off;" &
NGINX_PID=$!

# Wait for nginx to be ready
echo "⏳ Waiting for nginx to be ready..."
sleep 2

# Check if nginx is running
if ! kill -0 $NGINX_PID 2>/dev/null; then
    echo "❌ Failed to start nginx"
    exit 1
fi

echo "✅ Nginx started successfully (PID: $NGINX_PID)"

# Wait for nginx process
wait $NGINX_PID
