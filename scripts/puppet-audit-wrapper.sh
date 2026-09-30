#!/usr/bin/env bash
# Puppet audit wrapper: runs puppet apply --noop and converts output to GRCToolKit JSON finding.
# Never applies changes; enforces noop mode for read-only validation.
#
# Usage:
#   ./scripts/puppet-audit-wrapper.sh grc_audit::ssh_hardening [control_id] [config_path] [--oscal]
#
# Output: JSON finding to stdout
#   {"control": "IA-2", "status": "PASS|WARN|FAIL", "message": "...", "evidence": "..."}
#
# With --oscal flag: Also writes OSCAL result to /tmp/grc-oscal-reports/

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODULE="${1:-}"
CONTROL="${2:-PUPPET}"
CONFIG_PATH="${3:-}"
OSCAL_FLAG="${4:-}"

# Handle optional config_path parameter
if [[ "$CONFIG_PATH" == "--oscal" ]]; then
  OSCAL_FLAG="--oscal"
  CONFIG_PATH=""
elif [[ "$OSCAL_FLAG" != "--oscal" ]]; then
  OSCAL_FLAG=""
fi

REPORT_DIR="${ROOT}/puppet/reports"
OSCAL_DIR="/tmp/grc-oscal-reports"
TIMESTAMP="$(date +%s)"
REPORT_FILE="${REPORT_DIR}/puppet-noop-${TIMESTAMP}.yaml"

if [[ -z "$MODULE" ]]; then
  echo '{"control": "PUPPET", "status": "FAIL", "message": "Usage: puppet-audit-wrapper.sh <module> [control_id] [config_path] [--oscal]", "evidence": ""}' >&2
  exit 1
fi

# Ensure report directories exist
mkdir -p "$REPORT_DIR"
if [[ "$OSCAL_FLAG" == "--oscal" ]]; then
  mkdir -p "$OSCAL_DIR"
fi

# Safety check: never run without explicit validation that we're in noop mode
check_puppet_available() {
  if ! command -v puppet &>/dev/null; then
    echo '{"control": "'"${CONTROL}"'", "status": "SKIP", "message": "Puppet not installed (install puppet 7+ or run in container)", "evidence": "puppet command not found"}' >&2
    exit 0
  fi
}

run_puppet_noop() {
  local output
  local exit_code=0
  local vardir="/tmp/puppet-run-${TIMESTAMP}"
  
  # Create temp vardir for this run's structured output
  mkdir -p "$vardir"
  
  # Build puppet apply command
  local puppet_cmd="include ${MODULE}"
  
  # If config_path provided, use it as a parameter
  if [[ -n "$CONFIG_PATH" ]]; then
    puppet_cmd="class { '${MODULE}': sshd_config_path => '${CONFIG_PATH}' }"
  fi
  
  # Run puppet apply in noop mode with structured output
  # --vardir: isolated directory for this run's state/reports
  # --noop: never apply changes
  # --detailed-exitcodes: 0=no changes, 2=changes, 4+=errors
  output=$(puppet apply --noop \
    --vardir="$vardir" \
    --modulepath="${ROOT}/puppet/modules" \
    --detailed-exitcodes \
    -e "$puppet_cmd" \
    2>&1) || exit_code=$?
  
  # Write metadata to files AFTER puppet completes
  printf "%s" "$vardir" > "/tmp/puppet-vardir-${TIMESTAMP}.txt"
  printf "%s" "$exit_code" > "/tmp/puppet-exitcode-${TIMESTAMP}.txt"
  
  # Output goes to stdout
  echo "$output"
}

parse_puppet_output() {
  local output="$1"
  local exit_code="$2"
  local vardir="$3"
  
  # Save raw output to report file for debugging
  echo "$output" > "$REPORT_FILE"
  
  # If Python available, use structured YAML parsing
  if command -v python3 &>/dev/null && [[ -n "$vardir" ]]; then
    # Parse Puppet's structured output (last_run_report.yaml)
    python3 "${ROOT}/scripts/parse-puppet-summary.py" "$vardir" "$CONTROL" "$MODULE"
    return 0
  fi
  
  echo "# DEBUG: Falling back to exit code (python3=$(command -v python3), vardir=${vardir})" >&2
  
  # Fallback: simple exit code mapping (less accurate)
  local status="SKIP"
  local message="Could not parse Puppet output"
  local evidence=""
  
  # Strip ANSI color codes from output for JSON safety
  local clean_output
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
  
  # Exit codes: 0=no changes, 2=changes, 4+=errors
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
  
  # Emit JSON finding
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
  local output
  output=$(run_puppet_noop 2>&1)
  
  # Read exit code and vardir from temp files
  local exit_code=0
  local vardir=""
  
  if [[ -f "/tmp/puppet-exitcode-${TIMESTAMP}.txt" ]]; then
    exit_code=$(cat "/tmp/puppet-exitcode-${TIMESTAMP}.txt")
    rm -f "/tmp/puppet-exitcode-${TIMESTAMP}.txt"
  fi
  
  if [[ -f "/tmp/puppet-vardir-${TIMESTAMP}.txt" ]]; then
    vardir=$(cat "/tmp/puppet-vardir-${TIMESTAMP}.txt")
    rm -f "/tmp/puppet-vardir-${TIMESTAMP}.txt"
  fi
  
  # Parse and emit JSON finding (uses structured YAML if available)
  local finding_json
  finding_json=$(parse_puppet_output "$output" "$exit_code" "$vardir")
  echo "$finding_json"
  
  # Optionally convert to OSCAL format
  if [[ "$OSCAL_FLAG" == "--oscal" ]] && command -v python3 &>/dev/null; then
    local oscal_file="${OSCAL_DIR}/puppet-${MODULE//::/-}-${CONTROL}-${TIMESTAMP}.json"
    if echo "$finding_json" | python3 "${ROOT}/scripts/puppet-to-oscal.py" > "$oscal_file" 2>/dev/null; then
      echo "# OSCAL result: ${oscal_file}" >&2
    fi
  fi
  
  # Cleanup temp vardir
  if [[ -n "$vardir" ]] && [[ -d "$vardir" ]]; then
    rm -rf "$vardir"
  fi
  
  # Success (JSON emitted to stdout)
  exit 0
}

main "$@"
