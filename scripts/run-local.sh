#!/usr/bin/env bash
# Serve the app from the repo root so paths like /ai-agent/ resolve. Injects GEMINI_API_KEY
# into local-index.html (gitignored) the same way as scripts/docker-entrypoint.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
PORT="${PORT:-8080}"
OUT="local-index.html"

# Pick up GEMINI_API_KEY from repo-root .env when the shell did not export it (file is gitignored).
if [[ -z "${GEMINI_API_KEY:-}" && -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ROOT/.env" || true
  set +a
fi

k="${GEMINI_API_KEY:-}"
k="${k//$'\r'/}"
k="${k#"${k%%[![:space:]]*}"}"
k="${k%"${k##*[![:space:]]}"}"
if [[ -z "$k" ]]; then
  echo "warning: GEMINI_API_KEY is unset. Get a key from https://aistudio.google.com/ then either:" >&2
  echo "  export GEMINI_API_KEY=\"...\"   # same terminal, then re-run this script" >&2
  echo "  echo 'GEMINI_API_KEY=...' >> .env   # repo root, chmod 600; this script loads .env automatically" >&2
  echo "Or in the browser console: window.GEMINI_API_KEY = \"...\"; then Analyze (no reload needed)." >&2
fi
k_esc=$(printf '%s' "$k" | sed -e 's/[\\|&]/\\&/g')
sed -e "s|__GEMINI_API_KEY__|${k_esc}|g" grctoolkit.html > "$OUT"

echo "Repository: $ROOT"
echo "Open this URL (injected key lives only here — not in grctoolkit.html):"
echo "  http://127.0.0.1:${PORT}/${OUT}"
echo "Stop: Ctrl+C"
exec python3 -m http.server "$PORT"
