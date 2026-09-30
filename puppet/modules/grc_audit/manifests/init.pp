# GRC Audit Module - Read-Only NIST 800-53 Compliance Validation
# Never changes system state without HITL approval (AU-2 audit trail required)
#
# @summary
#   Root class for GRC audit modules. Use specific classes for control validation.
#
# @example
#   include grc_audit::ssh_hardening
#
# @param ensure_compliance
#   If false (default), all checks run in audit-only mode (noop).
#   If true, requires HITL documented approval before puppet apply without --noop.
class grc_audit (
  Boolean $ensure_compliance = false,
) {
  if $ensure_compliance {
    notify { 'grc_audit_hitl_warning':
      message => 'WARN: ensure_compliance=true requires HITL approval per docs/HITL-FRAMEWORK.md. Run with --noop for audit only.',
    }
  }

  # Module metadata
  notify { 'grc_audit_loaded':
    message => "GRC Audit Module loaded (ensure_compliance=${ensure_compliance})",
  }
}
