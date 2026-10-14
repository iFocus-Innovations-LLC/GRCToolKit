#!/bin/sh
# Start both nginx (static UI) and Python LLM proxy (API keys stay server-side).
# For Cloud Run / production: API keys are in env vars (from Secret Manager), never in HTML.
set -e

# Start Python LLM proxy in the background on port 8081
echo "Starting Python LLM proxy on 127.0.0.1:8081..."
cd /app
python3 ansible-runner-api.py --host 127.0.0.1 --port 8081 &
PROXY_PID=$!

# Give the proxy a moment to bind
sleep 2

# Check if proxy is running
if ! kill -0 $PROXY_PID 2>/dev/null; then
  echo "error: Python LLM proxy failed to start" >&2
  exit 1
fi

echo "Python LLM proxy running (PID $PROXY_PID)"

# Start nginx in the foreground
echo "Starting nginx on port 8080..."
exec nginx -g "daemon off;"
