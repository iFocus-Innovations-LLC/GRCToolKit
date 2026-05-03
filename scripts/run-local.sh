#!/usr/bin/env bash
# Serve the app from the repo root so paths like /ai-agent/ resolve. Injects GEMINI_API_KEY
# into local-index.html (gitignored) the same way as scripts/docker-entrypoint.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
PORT="${PORT:-8080}"
OUT="local-index.html"

k="${GEMINI_API_KEY:-}"
k="${k//$'\r'/}"
k="${k#"${k%%[![:space:]]*}"}"
k="${k%"${k##*[![:space:]]}"}"
if [[ -z "$k" ]]; then
  echo "warning: GEMINI_API_KEY is unset. Export it from AI Studio (https://aistudio.google.com/) or set window.GEMINI_API_KEY in the browser console before Analyze." >&2
fi
k_esc=$(printf '%s' "$k" | sed -e 's/[\\|&]/\\&/g')
sed -e "s|__GEMINI_API_KEY__|${k_esc}|g" grctoolkit.html > "$OUT"

echo "Repository: $ROOT"
echo "URL:        http://127.0.0.1:${PORT}/${OUT}"
echo "Stop:       Ctrl+C"
exec python3 -m http.server "$PORT"
