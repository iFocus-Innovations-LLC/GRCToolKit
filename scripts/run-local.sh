#!/usr/bin/env bash
# Serve the app from the repo root so paths like /ai-agent/ resolve. Injects multi-LLM BYOK
# placeholders into local-index.html (gitignored) the same way as scripts/docker-entrypoint.sh.
# Also starts scripts/ansible-runner-api.py for Validate Controls + /api/llm/analyze proxy (8081).
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

# Pick up keys from repo-root .env when the shell did not export them (file is gitignored).
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ROOT/.env" || true
  set +a
fi

trim() {
  local v="${1:-}"
  v="${v//$'\r'/}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}

esc_sed() {
  printf '%s' "$(trim "$1")" | sed -e 's/[\\|&]/\\&/g'
}

PROVIDER="$(trim "${LLM_PROVIDER:-gemini}")"
case "${PROVIDER}" in
  gemini|openai|anthropic|groq|vertex) ;;
  *) PROVIDER=gemini ;;
esac

GEMINI_K="$(trim "${GEMINI_API_KEY:-}")"
OPENAI_K="$(trim "${OPENAI_API_KEY:-}")"
ANTHROPIC_K="$(trim "${ANTHROPIC_API_KEY:-}")"
GROQ_K="$(trim "${GROQ_API_KEY:-}")"
VERTEX_K="$(trim "${VERTEX_API_KEY:-}")"

if [[ -z "$GEMINI_K" && "$PROVIDER" == "gemini" ]]; then
  echo "warning: GEMINI_API_KEY is unset. Get a key from https://aistudio.google.com/ then either:" >&2
  echo "  .env.local (see .env.local.example), repo-root .env, or export GEMINI_API_KEY for this session" >&2
  echo "Or in the browser console: window.GEMINI_API_KEY = \"...\"; then Analyze (no reload needed)." >&2
fi
if [[ "$PROVIDER" != "gemini" ]]; then
  echo "info: LLM_PROVIDER=${PROVIDER} — browser calls go through local proxy http://127.0.0.1:${RUNNER_PORT}/api/llm/analyze (CORS)." >&2
fi

sed \
  -e "s|__LLM_PROVIDER__|$(esc_sed "$PROVIDER")|g" \
  -e "s|__GEMINI_API_KEY__|$(esc_sed "$GEMINI_K")|g" \
  -e "s|__OPENAI_API_KEY__|$(esc_sed "$OPENAI_K")|g" \
  -e "s|__ANTHROPIC_API_KEY__|$(esc_sed "$ANTHROPIC_K")|g" \
  -e "s|__GROQ_API_KEY__|$(esc_sed "$GROQ_K")|g" \
  -e "s|__VERTEX_API_KEY__|$(esc_sed "$VERTEX_K")|g" \
  grctoolkit.html > "$OUT"

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
echo "Open (injected keys live only in local-index.html — not in grctoolkit.html):"
echo "  http://127.0.0.1:${PORT}/${OUT}"
echo "LLM provider: ${PROVIDER} (picker in UI; Gemini default)"
echo "Ansible/LLM API: http://127.0.0.1:${RUNNER_PORT}/health"
echo "  LLM proxy:     POST /api/llm/analyze (OpenAI/Anthropic/Groq/Vertex BYOK)"
echo "Reports:    /tmp/grc-oscal-reports/ (PDF + JSON)"
echo "LLM reports:/tmp/grc-llm-compliance-reports/"
echo "Stop:       Ctrl+C (stops UI and Ansible runner)"
wait "${HTTP_PID}"
