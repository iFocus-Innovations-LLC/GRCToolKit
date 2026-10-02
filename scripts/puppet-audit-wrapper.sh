#!/bin/bash
# Puppet noop audit wrapper with structured YAML parsing
# Usage: puppet-audit-wrapper.sh <module> <control> [config_path] [--oscal]
set -euo pipefail

# Configuration
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="${1:-grc_audit::ssh_hardening}"
CONTROL="${2:-IA-2}"
CONFIG_PATH="${3:-}"
OSCAL_FLAG="${4:-}"
OSCAL_DIR="${OSCAL_DIR:-/tmp/grc-oscal-reports}"
GRC_DEBUG="${GRC_DEBUG:-0}"

# Create output directory
mkdir -p "$OSCAL_DIR"

# Debug logging helper (only if GRC_DEBUG=1)
debug() {
  if [[ "$GRC_DEBUG" == "1" ]]; then
    echo "# DEBUG: $*" >&2
  fi
}

check_puppet_available() {
  if ! command -v puppet &>/dev/null; then
    cat <<EOF
{
  "control": "${CONTROL}",
  "status": "SKIP",
  "message": "Puppet not installed",
  "evidence": "Puppet binary not found in PATH",
  "puppet_module": "${MODULE}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "grc_audit_mode": "read_only"
}
EOF
    exit 0
  fi
}

run_puppet_noop() {
  # Create per-run temp directory with mktemp
  local run_dir
  run_dir=$(mktemp -d -t puppet-grc-XXXXXX)
  debug "Created run directory: $run_dir"
  
  # Build puppet apply command
  local puppet_cmd="include ${MODULE}"
  if [[ -n "$CONFIG_PATH" ]]; then
    puppet_cmd="class { '${MODULE}': sshd_config_path => '${CONFIG_PATH}' }"
  fi
  
  # Run puppet apply in noop mode with explicit paths
  local exit_code=0
  local output
  output=$(puppet apply --noop \
    --vardir="$run_dir/vardir" \
    --modulepath="${ROOT}/puppet/modules" \
    --detailed-exitcodes \
    -e "$puppet_cmd" \
    2>&1) || exit_code=$?
  
  debug "Puppet exit code: $exit_code"
  debug "Vardir: $run_dir/vardir"
  
  # Return: exit_code, run_dir, output (newline-separated)
  printf "%d\n%s\n%s\n" "$exit_code" "$run_dir" "$output"
}

parse_puppet_output() {
  local exit_code="$1"
  local run_dir="$2"
  local output="$3"
  
  local report_file="$run_dir/vardir/state/last_run_report.yaml"
  
  # Check if report exists
  if [[ ! -f "$report_file" ]]; then
    debug "Report file not found: $report_file"
    cat <<EOF
{
  "control": "${CONTROL}",
  "status": "ERROR",
  "message": "Puppet report not generated",
  "evidence": "Expected report at $report_file but file not found. Puppet may have failed to write report.",
  "puppet_module": "${MODULE}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "grc_audit_mode": "read_only"
}
EOF
    return 1
  fi
  
  debug "Found report file: $report_file"
  
  # Parse with Python if available
  if command -v python3 &>/dev/null; then
    python3 "${ROOT}/scripts/parse-puppet-summary.py" "$run_dir/vardir" "$CONTROL" "$MODULE"
    return 0
  fi
  
  # Fallback: simple exit code mapping (less accurate)
  debug "Python not available, using exit code fallback"
  
  local status="SKIP"
  local message="Could not parse Puppet output"
  local evidence
  
  # Strip ANSI codes
  local clean_output
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
  
  if [[ $exit_code -eq 0 ]]; then
    status="PASS"
    message="All SSH hardening settings in desired state (no drift detected)"
  elif [[ $exit_code -eq 2 ]]; then
    status="WARN"
    message="SSH configuration drift detected (changes would be made)"
  elif [[ $exit_code -ge 4 ]]; then
    status="FAIL"
    message="Puppet validation failed (exit code ${exit_code})"
  else
    status="SKIP"
    message="Unexpected Puppet exit code: ${exit_code}"
  fi
  
  evidence=$(echo "$clean_output" | tail -c 1000 | sed 's/"/\\"/g' | tr '\n' ' ')
  
  cat <<EOF
{
  "control": "${CONTROL}",
  "status": "${status}",
  "message": "${message}",
  "evidence": "${evidence}",
  "puppet_module": "${MODULE}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "grc_audit_mode": "read_only"
}
EOF
}

main() {
  check_puppet_available
  
  # Run Puppet in noop mode
  local puppet_result
  puppet_result=$(run_puppet_noop)
  
  # Parse result (newline-separated)
  local exit_code
  local run_dir
  local output
  
  exit_code=$(echo "$puppet_result" | sed -n '1p')
  run_dir=$(echo "$puppet_result" | sed -n '2p')
  output=$(echo "$puppet_result" | sed -n '3,$p')
  
  debug "Parsed exit_code=$exit_code, run_dir=$run_dir"
  
  # Parse and emit JSON finding (uses structured YAML if available)
  local finding_json
  finding_json=$(parse_puppet_output "$exit_code" "$run_dir" "$output")
  
  # Only JSON to stdout
  echo "$finding_json"
  
  # Optionally convert to OSCAL format
  if [[ "$OSCAL_FLAG" == "--oscal" ]] && command -v python3 &>/dev/null; then
    local timestamp
    timestamp=$(date +%s)
    local oscal_file="${OSCAL_DIR}/puppet-${MODULE//::/-}-${CONTROL}-${timestamp}.json"
    if echo "$finding_json" | python3 "${ROOT}/scripts/puppet-to-oscal.py" > "$oscal_file" 2>/dev/null; then
      debug "OSCAL result: ${oscal_file}"
    fi
  fi
  
  # Cleanup temp directory
  if [[ -n "$run_dir" ]] && [[ -d "$run_dir" ]]; then
    rm -rf "$run_dir"
    debug "Cleaned up: $run_dir"
  fi
  
  exit 0
}

main "$@"
