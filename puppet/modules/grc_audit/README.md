# GRC Audit Puppet Module

**Purpose:** Read-only NIST 800-53 compliance validation using Puppet noop mode  
**License:** Apache 2.0 (matches Puppet open-source)  
**HITL:** Evidence collection only; no state changes without human approval

---

## Overview

This module provides Puppet manifests for validating system configuration against NIST 800-53 Rev. 5 controls using Puppet's `--noop` mode. All checks are read-only by default and never modify system state.

**Note:** This POC uses only core Puppet resource types (`exec`, `notify`, `file`). No external dependencies required.

## Modules

### `grc_audit::ssh_hardening`

**Controls:** IA-2, AC-3, AC-17  
**Validates:**
- SSH PasswordAuthentication setting
- PermitRootLogin configuration
- PubkeyAuthentication requirement
- SSH Protocol version

**Usage:**
```bash
# Noop mode (read-only audit)
puppet apply --noop \
  --modulepath=/workspace/puppet/modules \
  -e 'include grc_audit::ssh_hardening'

# Via wrapper (produces JSON finding)
./scripts/puppet-audit-wrapper.sh grc_audit::ssh_hardening IA-2
```

**Parameters:**
- `ensure_compliance`: Boolean (default: false) - If true, requires HITL approval
- `password_auth_allowed`: 'yes' or 'no' (default: 'no')
- `permit_root_login`: 'yes', 'no', 'prohibit-password', etc. (default: 'no')
- `pubkey_auth_required`: 'yes' or 'no' (default: 'yes')

## Installation

### Puppet Open-Source (Recommended)

```bash
# Ubuntu/Debian
curl -O https://apt.puppet.com/puppet-release-$(lsb_release -cs).deb
sudo dpkg -i puppet-release-$(lsb_release -cs).deb
sudo apt-get update
sudo apt-get install puppet-agent

# RHEL/CentOS
sudo rpm -Uvh https://yum.puppet.com/puppet-release-el-8.noarch.rpm
sudo yum install puppet-agent

# Add puppet to PATH
export PATH=/opt/puppetlabs/bin:$PATH
```

### OpenVox (Community Fork)

If using OpenVox or other community Puppet distributions, ensure Puppet 7+ compatibility.

## Development

### Testing

```bash
# Syntax validation
puppet parser validate puppet/modules/grc_audit/manifests/*.pp

# Lint (optional)
puppet-lint --no-autoloader_layout-check puppet/modules/grc_audit/

# Smoke test
./scripts/test-puppet-audit.sh
```

### Adding New Modules

1. Create manifest: `puppet/modules/grc_audit/manifests/your_module.pp`
2. Follow naming convention: `class grc_audit::your_module`
3. Set `ensure_compliance = false` for audit-only default
4. Add NIST control comments at top
5. Use `file_line`, `package`, `service` resources for checks
6. Test in noop mode

## Architecture

```
grc_audit module
├── init.pp              Base class
├── ssh_hardening.pp     IA-2, AC-3, AC-17 (SSH)
├── file_permissions.pp  AC-6 (future)
└── package_baseline.pp  CM-7 (future)
```

## HITL Guardrails

- **Never run without `--noop`**: Wrapper enforces noop flag
- **AU-2 audit trail**: All runs logged with timestamp
- **HITL approval required**: Any `puppet apply` without `--noop` requires documented human approval per docs/HITL-FRAMEWORK.md

## Integration with GRCToolKit

### Finding Format

Wrapper produces JSON compatible with Ansible findings:

```json
{
  "control": "IA-2",
  "status": "PASS|WARN|FAIL",
  "message": "Human-readable description",
  "evidence": "Puppet noop output excerpt",
  "puppet_module": "grc_audit::ssh_hardening",
  "timestamp": "2026-09-30T15:30:00Z",
  "grc_audit_mode": "read_only"
}
```

### OSCAL Export

Findings map to OSCAL assessment results using existing GRCToolKit patterns.

## License Notes

- **Puppet DSL code (this module):** Apache 2.0
- **Puppet runtime:** Puppet 7/8 (Apache 2.0) or OpenVox
- **Not used:** Puppet Enterprise, Puppet Comply (commercial)

## References

- [Puppet Open Source Docs](https://www.puppet.com/docs/puppet/8/puppet_index.html)
- [Puppet Apply](https://www.puppet.com/docs/puppet/8/man/apply.html)
- [Noop Mode](https://www.puppet.com/docs/puppet/8/configuration.html#noop)
- [NIST 800-53 Rev. 5](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)

---

**Version:** 0.1 (POC)  
**Last Updated:** 2026-09-30
