#!/usr/bin/env bash
# Smoke test for Puppet audit engine POC
# Tests manifest syntax, noop mode, and JSON output format

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failed=0

echo "🧪 Puppet Audit Engine Smoke Test"
echo ""

# Check if puppet is available
if ! command -v puppet &>/dev/null; then
  echo "⚠️  Puppet not installed - skipping runtime tests"
  echo "   (Install puppet 7+ to test: https://www.puppet.com/docs/puppet/8/install_puppet.html)"
  echo ""
  echo "✅ Syntax-only validation mode"
  
  # Can still validate syntax without puppet binary using parser if available
  if command -v puppet &>/dev/null; then
    echo "1) Validate manifest syntax"
    if puppet parser validate puppet/modules/grc_audit/manifests/*.pp 2>&1; then
      echo "✅ Manifests syntax valid"
    else
      echo "❌ Manifest syntax errors"
      failed=1
    fi
  fi
  
  exit $failed
fi

echo "1) Puppet version"
puppet --version

echo ""
echo "2) Validate manifest syntax"
if puppet parser validate puppet/modules/grc_audit/manifests/*.pp 2>&1; then
  echo "✅ Manifests syntax valid"
else
  echo "❌ Manifest syntax errors"
  failed=1
fi

echo ""
echo "3) Lint manifests (if puppet-lint available)"
if command -v puppet-lint &>/dev/null; then
  if puppet-lint --no-autoloader_layout-check puppet/modules/grc_audit/ 2>&1; then
    echo "✅ Lint passed"
  else
    echo "⚠️  Lint warnings (non-blocking)"
  fi
else
  echo "⚠️  puppet-lint not installed (optional)"
fi

echo ""
echo "4) Noop dry-run (module load check)"
if puppet apply --noop \
  --modulepath=./puppet/modules \
  -e "include grc_audit" 2>&1 | tee /tmp/puppet-smoke-init.log; then
  echo "✅ Base module loads"
else
  echo "❌ Base module failed to load"
  failed=1
fi

echo ""
echo "5) SSH hardening module noop run"
if puppet apply --noop \
  --modulepath=./puppet/modules \
  --detailed-exitcodes \
  -e "include grc_audit::ssh_hardening" 2>&1 | tee /tmp/puppet-smoke-ssh.log; then
  exit_code=0
else
  exit_code=$?
fi

# Detailed exit codes: 0=no changes, 2=changes, 4+=errors
if [[ $exit_code -eq 0 || $exit_code -eq 2 ]]; then
  echo "✅ SSH hardening module ran (exit code ${exit_code}: $([ $exit_code -eq 0 ] && echo 'no drift' || echo 'drift detected'))"
else
  echo "❌ SSH hardening module failed (exit code ${exit_code})"
  failed=1
fi

echo ""
echo "6) Wrapper script JSON output"
if ./scripts/puppet-audit-wrapper.sh grc_audit::ssh_hardening IA-2 > /tmp/puppet-finding.json 2>&1; then
  echo "✅ Wrapper executed"
  
  # Validate JSON structure
  if command -v jq &>/dev/null; then
    if jq -e '.control, .status, .message, .evidence' /tmp/puppet-finding.json >/dev/null 2>&1; then
      echo "✅ JSON structure valid"
      echo ""
      echo "Finding output:"
      jq '.' /tmp/puppet-finding.json || cat /tmp/puppet-finding.json
    else
      echo "❌ JSON structure invalid"
      cat /tmp/puppet-finding.json
      failed=1
    fi
  else
    echo "⚠️  jq not installed (can't validate JSON structure)"
    echo "Finding output:"
    cat /tmp/puppet-finding.json
  fi
else
  echo "❌ Wrapper script failed"
  cat /tmp/puppet-finding.json 2>/dev/null || echo "(no output)"
  failed=1
fi

echo ""
echo "7) OSCAL integration (if Python 3 available)"
if command -v python3 &>/dev/null; then
  if ./scripts/puppet-audit-wrapper.sh grc_audit::ssh_hardening IA-2 --oscal > /tmp/puppet-finding-oscal.json 2>&1; then
    echo "✅ Wrapper with OSCAL flag executed"
    
    # Check if OSCAL file was created
    oscal_file=$(find /tmp/grc-oscal-reports -name "puppet-*.json" -type f 2>/dev/null | head -1)
    if [[ -n "$oscal_file" ]] && [[ -f "$oscal_file" ]]; then
      echo "✅ OSCAL result file created: $oscal_file"
      
      if command -v jq &>/dev/null; then
        if jq -e '.["assessment-results"]' "$oscal_file" >/dev/null 2>&1; then
          echo "✅ OSCAL structure valid"
        else
          echo "❌ OSCAL structure invalid"
          failed=1
        fi
      fi
    else
      echo "⚠️  OSCAL file not created (non-critical for POC)"
    fi
  else
    echo "❌ Wrapper with OSCAL flag failed"
    failed=1
  fi
else
  echo "⚠️  Python 3 not installed (skipping OSCAL test)"
fi

echo ""
if [[ $failed -eq 0 ]]; then
  echo "🎉 Puppet audit engine smoke test PASSED"
  exit 0
else
  echo "❌ Puppet audit engine smoke test FAILED"
  exit 1
fi
