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
  
  # Build puppet apply command
  local puppet_cmd="include ${MODULE}"
  
  # If config_path provided, use it as a parameter
  if [[ -n "$CONFIG_PATH" ]]; then
    puppet_cmd="class { '${MODULE}': sshd_config_path => '${CONFIG_PATH}' }"
  fi
  
  # Run puppet apply in noop mode with YAML report
  # --modulepath: use our grc_audit module
  # --noop: never apply changes
  # --detailed-exitcodes: 0=no changes, 2=changes would be made, 4+=errors
  output=$(puppet apply --noop \
    --modulepath="${ROOT}/puppet/modules" \
    --detailed-exitcodes \
    -e "$puppet_cmd" \
    2>&1) || exit_code=$?
  
  echo "$output"
  return $exit_code
}

parse_puppet_output() {
  local output="$1"
  local exit_code="$2"
  local status="SKIP"
  local message="Unknown"
  local evidence=""
  
  # Puppet detailed exit codes:
  # 0 = no changes (PASS)
  # 1 = exec resource failed in noop (WARN/FAIL - command returned non-zero)
  # 2 = changes would be made in real run (WARN/FAIL depending on severity)
  # 4 = failures (FAIL)
  # 6 = changes + failures (FAIL)
  
  if [[ $exit_code -eq 0 ]]; then
    status="PASS"
    message="All SSH hardening settings in desired state (no drift detected)"
  elif [[ $exit_code -eq 1 ]]; then
    # Exec resources failed (grep didn't find expected config)
    drift_count=$(echo "$output" | grep -c "returned 1 instead of" || echo 0)
    if [[ $drift_count -gt 0 ]]; then
      status="WARN"
      message="SSH configuration drift detected: ${drift_count} setting(s) out of compliance"
    else
      status="FAIL"
      message="Puppet validation failed (exit code 1)"
    fi
  elif [[ $exit_code -eq 2 ]]; then
    # Parse drift details from output
    drift_count=$(echo "$output" | grep -c "current_value.*should be" || echo 0)
    if [[ $drift_count -gt 0 ]]; then
      status="WARN"
      message="SSH configuration drift detected: ${drift_count} setting(s) out of compliance"
    else
      status="WARN"
      message="Puppet detected changes would be made (see evidence for details)"
    fi
  elif [[ $exit_code -ge 4 ]]; then
    status="FAIL"
    message="Puppet validation failed (exit code ${exit_code})"
  else
    status="SKIP"
    message="Unexpected Puppet exit code: ${exit_code}"
  fi
  
  # Extract relevant evidence (last 1000 chars to keep JSON manageable)
  evidence=$(echo "$output" | tail -c 1000 | sed 's/"/\\"/g' | tr '\n' ' ')
  
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
  local exit_code=0
  output=$(run_puppet_noop 2>&1) || exit_code=$?
  
  # Save raw output to report file for debugging
  echo "$output" > "$REPORT_FILE"
  
  # Parse and emit JSON finding
  local finding_json
  finding_json=$(parse_puppet_output "$output" "$exit_code")
  echo "$finding_json"
  
  # Optionally convert to OSCAL format
  if [[ "$OSCAL_FLAG" == "--oscal" ]] && command -v python3 &>/dev/null; then
    local oscal_file="${OSCAL_DIR}/puppet-${MODULE//::/-}-${CONTROL}-${TIMESTAMP}.json"
    if echo "$finding_json" | python3 "${ROOT}/scripts/puppet-to-oscal.py" > "$oscal_file" 2>/dev/null; then
      echo "# OSCAL result: ${oscal_file}" >&2
    fi
  fi
  
  # Success (JSON emitted to stdout)
  exit 0
}

main "$@"
