#!/bin/sh
# Render index.html from the baked template so LLM BYOK keys (from env / K8s secret)
# are injected at container start. Template markers must match grctoolkit.html.
set -e
TEMPLATE=/usr/share/nginx/html/index.html.template
OUT=/usr/share/nginx/html/index.html
if [ ! -f "$TEMPLATE" ]; then
  echo "error: missing ${TEMPLATE}" >&2
  exit 1
fi

esc() {
  printf '%s' "$1" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed -e 's/[\\|&]/\\&/g'
}

PROVIDER=$(esc "${LLM_PROVIDER:-gemini}")
case "$PROVIDER" in
  gemini|openai|anthropic|groq|vertex) ;;
  *) PROVIDER=gemini ;;
esac

sed \
  -e "s|__LLM_PROVIDER__|${PROVIDER}|g" \
  -e "s|__GEMINI_API_KEY__|$(esc "${GEMINI_API_KEY:-}")|g" \
  -e "s|__OPENAI_API_KEY__|$(esc "${OPENAI_API_KEY:-}")|g" \
  -e "s|__ANTHROPIC_API_KEY__|$(esc "${ANTHROPIC_API_KEY:-}")|g" \
  -e "s|__GROQ_API_KEY__|$(esc "${GROQ_API_KEY:-}")|g" \
  -e "s|__VERTEX_API_KEY__|$(esc "${VERTEX_API_KEY:-}")|g" \
  "$TEMPLATE" > "$OUT"
exec nginx -g "daemon off;"
