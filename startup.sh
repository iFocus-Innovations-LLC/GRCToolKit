#!/bin/sh

# Startup script to inject environment variables into HTML
# This ensures the GEMINI_API_KEY is securely injected at runtime

echo "🔐 Injecting GEMINI_API_KEY into HTML..."

# Create a temporary HTML file with the API key injected
if [ -n "$GEMINI_API_KEY" ]; then
    echo "✅ API key found, injecting into HTML..."
    sed "s/window.GEMINI_API_KEY = \"\";/window.GEMINI_API_KEY = \"${GEMINI_API_KEY}\";/g" /usr/share/nginx/html/grctoolkit.html > /usr/share/nginx/html/index.html
else
    echo "⚠️  No API key provided, using original HTML..."
    cp /usr/share/nginx/html/grctoolkit.html /usr/share/nginx/html/index.html
fi

echo "🚀 Starting nginx with graceful shutdown support..."

# Start the graceful shutdown script
exec /usr/local/bin/graceful-shutdown.sh
