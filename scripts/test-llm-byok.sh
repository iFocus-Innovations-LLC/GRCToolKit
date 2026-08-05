#!/usr/bin/env bash
# Focused smoke for multi-LLM BYOK: HTML key injection + local /api/llm/analyze proxy.
#
# Prerequisites (typical):
#   ./scripts/run-local.sh
#
# Usage:
#   ./scripts/test-llm-byok.sh
#   LLM_PROVIDER=openai ./scripts/test-llm-byok.sh
#   MVP_LLM_LIVE=1 LLM_PROVIDER=gemini ./scripts/test-llm-byok.sh   # real API call
#
# Env: loads .env.local / .env like run-local.sh. See .env.local.example.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -f "$ROOT/.env.local" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env.local"
  set +a
fi
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ROOT/.env" || true
  set +a
fi

BASE_URL="${BASE_URL:-http://127.0.0.1:8080}"
HTML_PATH="${MVP_HTML_PATH:-/local-index.html}"
ANSIBLE_RUNNER_PORT="${ANSIBLE_RUNNER_PORT:-8081}"
ANSIBLE_API_BASE="${ANSIBLE_API_BASE:-http://127.0.0.1:${ANSIBLE_RUNNER_PORT}}"
LLM_PROVIDER="${LLM_PROVIDER:-gemini}"
MVP_LLM_LIVE="${MVP_LLM_LIVE:-0}"
case "${LLM_PROVIDER}" in
  gemini|openai|anthropic|groq|vertex) ;;
  *) LLM_PROVIDER=gemini ;;
esac

trim_ws() {
  local v="${1:-}"
  v="${v//$'\r'/}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}

key_env_for_provider() {
  case "$1" in
    gemini) echo "GEMINI_API_KEY" ;;
    openai) echo "OPENAI_API_KEY" ;;
    anthropic) echo "ANTHROPIC_API_KEY" ;;
    groq) echo "GROQ_API_KEY" ;;
    vertex) echo "VERTEX_API_KEY" ;;
  esac
}

window_var_for_provider() {
  key_env_for_provider "$1"
}

PAGE_URL="${BASE_URL%/}${HTML_PATH}"
failed=0

echo "🎯 Multi-LLM BYOK smoke"
echo "  page=${PAGE_URL}"
echo "  provider=${LLM_PROVIDER}"
echo "  proxy=${ANSIBLE_API_BASE}"

echo ""
echo "1) Adapter asset"
if curl -sfS --max-time 5 "${BASE_URL%/}/ai-agent/llm-providers.js" | grep -q "analyzeScenario"; then
  echo "✅ llm-providers.js served"
else
  echo "❌ llm-providers.js missing or incomplete at ${BASE_URL%/}/ai-agent/llm-providers.js"
  failed=1
fi

echo ""
echo "2) HTML injection"
html=$(curl -sS --connect-timeout 5 "$PAGE_URL" 2>/dev/null || true)
if [[ -z "$html" ]]; then
  echo "❌ page unreachable: $PAGE_URL"
  echo "   Start: ./scripts/run-local.sh  then re-run this script."
  exit 1
fi

if echo "$html" | grep -Fq '__LLM_PROVIDER__'; then
  echo "❌ __LLM_PROVIDER__ still in page — rebuild local-index via run-local.sh"
  failed=1
elif echo "$html" | grep -Fq "window.LLM_PROVIDER = \"${LLM_PROVIDER}\""; then
  echo "✅ LLM_PROVIDER=${LLM_PROVIDER}"
else
  echo "⚠️  page provider may differ from LLM_PROVIDER=${LLM_PROVIDER}"
fi

for ph in __GEMINI_API_KEY__ __OPENAI_API_KEY__ __ANTHROPIC_API_KEY__ __GROQ_API_KEY__ __VERTEX_API_KEY__; do
  if echo "$html" | grep -Fq "$ph"; then
    echo "❌ placeholder remains: $ph"
    failed=1
  fi
done
[[ "$failed" -eq 0 ]] && echo "✅ BYOK placeholders substituted"

env_name="$(key_env_for_provider "$LLM_PROVIDER")"
win_var="$(window_var_for_provider "$LLM_PROVIDER")"
key="$(trim_ws "${!env_name:-}")"
if [[ -n "$key" ]]; then
  if echo "$html" | grep -Fq "window.${win_var} = \"${key}\""; then
    echo "✅ ${win_var} matches ${env_name}"
  else
    echo "❌ ${win_var} does not match ${env_name} — restart run-local.sh after setting the key"
    failed=1
  fi
else
  echo "⚠️  ${env_name} unset (empty injection OK for offline smoke)"
fi

if ! echo "$html" | grep -q 'id="llmProviderSelect"'; then
  echo "❌ llmProviderSelect missing from page"
  failed=1
else
  echo "✅ provider picker present"
fi

echo ""
echo "3) LLM proxy"
health=$(curl -sS --connect-timeout 2 "${ANSIBLE_API_BASE}/health" 2>/dev/null || true)
if ! echo "$health" | grep -q '"ok"[[:space:]]*:[[:space:]]*true'; then
  echo "❌ runner not at ${ANSIBLE_API_BASE}/health"
  failed=1
elif ! echo "$health" | grep -q '"llmProxy"[[:space:]]*:[[:space:]]*true'; then
  echo "❌ health missing llmProxy:true"
  failed=1
else
  echo "✅ llmProxy=true"
fi

code=$(curl -sS -o /tmp/grc-llm-byok-err.json -w "%{http_code}" --connect-timeout 5 \
  -X POST "${ANSIBLE_API_BASE}/api/llm/analyze" \
  -H "Content-Type: application/json" \
  -d '{"provider":"openai","prompt":"ping","apiKey":""}' 2>/dev/null || echo "000")
if [[ "$code" == "400" ]] && grep -qi "Missing OpenAI" /tmp/grc-llm-byok-err.json 2>/dev/null; then
  echo "✅ missing-key rejected (400)"
else
  echo "❌ expected 400 missing OpenAI key, got ${code}"
  failed=1
fi

if [[ "$MVP_LLM_LIVE" == "1" ]]; then
  if [[ -z "$key" ]]; then
    echo "❌ MVP_LLM_LIVE=1 requires ${env_name}"
    failed=1
  else
    echo "… live call provider=${LLM_PROVIDER}"
    payload=$(
      MVP_LIVE_PROVIDER="$LLM_PROVIDER" MVP_LIVE_KEY="$key" python3 - <<'PY'
import json, os
print(json.dumps({
    "provider": os.environ["MVP_LIVE_PROVIDER"],
    "prompt": 'Reply with JSON only: {"ok": true}',
    "apiKey": os.environ["MVP_LIVE_KEY"],
}))
PY
    )
    code=$(curl -sS -o /tmp/grc-llm-byok-live.json -w "%{http_code}" --max-time 90 \
      -X POST "${ANSIBLE_API_BASE}/api/llm/analyze" \
      -H "Content-Type: application/json" \
      -d "$payload" 2>/dev/null || echo "000")
    if [[ "$code" == "200" ]]; then
      echo "✅ live /api/llm/analyze OK"
    else
      echo "❌ live call HTTP ${code}"
      head -c 400 /tmp/grc-llm-byok-live.json 2>/dev/null; echo
      failed=1
    fi
  fi
else
  echo "⚠️  skip live call (MVP_LLM_LIVE=1 to enable)"
fi

echo ""
if [[ "$failed" -eq 0 ]]; then
  echo "🎉 multi-LLM BYOK smoke passed"
  exit 0
fi
echo "❌ multi-LLM BYOK smoke failed"
exit 1
