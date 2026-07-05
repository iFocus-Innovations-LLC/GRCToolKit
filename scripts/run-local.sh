#!/usr/bin/env bash
# Serve the app from the repo root so paths like /ai-agent/ resolve. Injects GEMINI_API_KEY
# into local-index.html (gitignored) the same way as scripts/docker-entrypoint.sh.
# Also starts scripts/ansible-runner-api.py for live Validate Controls (port 8081).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
PORT="${PORT:-8080}"
RUNNER_PORT="${ANSIBLE_RUNNER_PORT:-8081}"
OUT="local-index.html"
RUNNER_PID=""
HTTP_PID=""

free_port() {
  local port=$1
  if ! command -v lsof >/dev/null 2>&1; then
    return 0
  fi
  local pids
  pids="$(lsof -ti :"${port}" 2>/dev/null || true)"
  if [[ -n "${pids}" ]]; then
    echo "Stopping stale process(es) on port ${port}: ${pids}" >&2
    # shellcheck disable=SC2086
    kill ${pids} 2>/dev/null || true
    sleep 0.3
  fi
}

cleanup() {
  if [[ -n "${HTTP_PID}" ]]; then
    kill "${HTTP_PID}" 2>/dev/null || true
  fi
  if [[ -n "${RUNNER_PID}" ]]; then
    kill "${RUNNER_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

# Load gitignored local secrets (see .env.local.example). Does not override existing env.
if [[ -f "$ROOT/.env.local" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env.local"
  set +a
fi

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
  echo "  .env.local (see .env.local.example), repo-root .env, or export GEMINI_API_KEY for this session" >&2
  echo "  export GEMINI_API_KEY=\"...\"   # same terminal, then re-run this script" >&2
  echo "Or in the browser console: window.GEMINI_API_KEY = \"...\"; then Analyze (no reload needed)." >&2
fi
k_esc=$(printf '%s' "$k" | sed -e 's/[\\|&]/\\&/g')
sed -e "s|__GEMINI_API_KEY__|${k_esc}|g" grctoolkit.html > "$OUT"

LOCAL_VENV="$ROOT/.venv-local-demo"
PYTHON="python3"
if [[ -x "$LOCAL_VENV/bin/python" ]]; then
  PYTHON="$LOCAL_VENV/bin/python"
elif [[ ! -d "$LOCAL_VENV" ]]; then
  echo "Creating local demo venv at .venv-local-demo (fpdf2 for PDF reports)..." >&2
  python3 -m venv "$LOCAL_VENV"
  "$LOCAL_VENV/bin/pip" install -q -r "$ROOT/scripts/requirements-local-demo.txt"
  PYTHON="$LOCAL_VENV/bin/python"
fi

if ! "$PYTHON" -c "import fpdf" >/dev/null 2>&1; then
  echo "Installing fpdf2 into .venv-local-demo..." >&2
  "$LOCAL_VENV/bin/pip" install -q -r "$ROOT/scripts/requirements-local-demo.txt" 2>/dev/null || {
    echo "warning: fpdf2 not installed. OSCAL PDF download will fail until venv is set up." >&2
  }
  PYTHON="$LOCAL_VENV/bin/python"
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "warning: ansible-playbook not found. Validate Controls will fall back to simulation." >&2
  echo "         Install: brew install ansible" >&2
fi

free_port "${RUNNER_PORT}"
free_port "${PORT}"

"$PYTHON" "$ROOT/scripts/ansible-runner-api.py" --port "$RUNNER_PORT" &
RUNNER_PID=$!
sleep 0.2

python3 -m http.server "$PORT" &
HTTP_PID=$!

echo "Repository: $ROOT"
echo "Open (injected key lives only in local-index.html — not in grctoolkit.html):"
echo "  http://127.0.0.1:${PORT}/${OUT}"
echo "Ansible API: http://127.0.0.1:${RUNNER_PORT}/health"
echo "Reports:    /tmp/grc-oscal-reports/ (PDF + JSON)"
echo "Stop:       Ctrl+C (stops UI and Ansible runner)"
wait "${HTTP_PID}"
