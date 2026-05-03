#!/bin/sh
# Render index.html from the baked template so GEMINI_API_KEY (from env / K8s secret) is injected
# at container start. Template marker must match grctoolkit.html.
set -e
TEMPLATE=/usr/share/nginx/html/index.html.template
OUT=/usr/share/nginx/html/index.html
if [ ! -f "$TEMPLATE" ]; then
  echo "error: missing ${TEMPLATE}" >&2
  exit 1
fi
k=$(printf '%s' "${GEMINI_API_KEY:-}" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
k=$(printf '%s' "$k" | sed -e 's/[\\|&]/\\&/g')
sed -e "s|__GEMINI_API_KEY__|${k}|g" "$TEMPLATE" > "$OUT"
exec nginx -g "daemon off;"
