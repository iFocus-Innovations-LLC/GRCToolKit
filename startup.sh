#!/bin/sh
# Legacy/local helper: same rendering as scripts/docker-entrypoint.sh (Docker image entrypoint).
# Expects index.html.template next to this script or under /usr/share/nginx/html in a container.

set -e
TEMPLATE="${GRC_HTML_TEMPLATE:-/usr/share/nginx/html/index.html.template}"
OUT="${GRC_HTML_OUT:-/usr/share/nginx/html/index.html}"
if [ ! -f "$TEMPLATE" ]; then
  echo "error: template not found: $TEMPLATE" >&2
  exit 1
fi
k="${GEMINI_API_KEY:-}"
k=$(printf '%s' "$k" | sed -e 's/[\\|&]/\\&/g')
sed -e "s|__GEMINI_API_KEY__|${k}|g" "$TEMPLATE" > "$OUT"
echo "Rendered ${OUT} from ${TEMPLATE}."
