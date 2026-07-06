#!/usr/bin/env bash
# Shared helpers for GRC read-only audit probes (install to /usr/local/sbin/).
set -euo pipefail

GRC_CHANGE_ID="${GRCTOOLKIT_CHANGE_ID:-unspecified}"

grc_json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

grc_probe_header() {
  local control="$1"
  local host
  host="$(hostname -f 2>/dev/null || hostname)"
  printf '{"control":"%s","hostname":"%s","change_id":"%s","timestamp":"%s"' \
    "$(grc_json_escape "$control")" \
    "$(grc_json_escape "$host")" \
    "$(grc_json_escape "$GRC_CHANGE_ID")" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

grc_probe_footer() {
  printf '}\n'
}

grc_run_readonly() {
  # Usage: grc_run_readonly "label" command...
  local label="$1"
  shift
  local rc=0 out
  out="$("$@" 2>&1)" || rc=$?
  local esc
  esc="$(grc_json_escape "$out")"
  printf ',"%s":{"exit_code":%d,"output":"%s"}' "$(grc_json_escape "$label")" "$rc" "$esc"
  return 0
}
