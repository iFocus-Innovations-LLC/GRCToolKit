# Puppet Audit Engine — Quick Start

This guide shows how to use the Puppet audit engine POC for SSH hardening validation.

## Prerequisites

### Option 1: Install Puppet (Local Testing)

```bash
# Ubuntu/Debian
curl -O https://apt.puppet.com/puppet-release-jammy.deb
sudo dpkg -i puppet-release-jammy.deb
sudo apt-get update
sudo apt-get install puppet-agent

# Add to PATH
export PATH=/opt/puppetlabs/bin:$PATH

# Verify
puppet --version
```

### Option 2: Skip Installation (Syntax Validation Only)

The smoke test gracefully handles missing Puppet installation.

## Running the POC

### 1. Smoke Test (Recommended First Step)

```bash
cd /workspace
./scripts/test-puppet-audit.sh
```

**Expected output** (without Puppet):
```
🧪 Puppet Audit Engine Smoke Test

⚠️  Puppet not installed - skipping runtime tests
   (Install puppet 7+ to test: https://www.puppet.com/docs/puppet/8/install_puppet.html)

✅ Syntax-only validation mode
```

**Expected output** (with Puppet):
```
🧪 Puppet Audit Engine Smoke Test

1) Puppet version
puppet 8.x.x

2) Validate manifest syntax
✅ Manifests syntax valid

3) Lint manifests (if puppet-lint available)
✅ Lint passed

4) Noop dry-run (module load check)
✅ Base module loads

5) SSH hardening module noop run
✅ SSH hardening module ran (exit code 0: no drift)

6) Wrapper script JSON output
✅ Wrapper executed
✅ JSON structure valid

Finding output:
{
  "control": "IA-2",
  "status": "PASS",
  "message": "All SSH hardening settings in desired state (no drift detected)",
  "evidence": "...",
  "puppet_module": "grc_audit::ssh_hardening",
  "timestamp": "2026-09-30T15:47:32Z",
  "grc_audit_mode": "read_only"
}

🎉 Puppet audit engine smoke test PASSED
```

### 2. Direct Puppet Noop Run

```bash
# Check SSH hardening (read-only, no changes)
puppet apply --noop \
  --modulepath=./puppet/modules \
  -e 'include grc_audit::ssh_hardening'
```

### 3. Via Wrapper (JSON Output)

```bash
# Run wrapper to get JSON finding
./scripts/puppet-audit-wrapper.sh grc_audit::ssh_hardening IA-2

# Output (pretty-printed)
{
  "control": "IA-2",
  "status": "WARN",
  "message": "SSH configuration drift detected: 2 setting(s) out of compliance",
  "evidence": "...should be 'present' (noop)...",
  "puppet_module": "grc_audit::ssh_hardening",
  "timestamp": "2026-09-30T15:47:32Z",
  "grc_audit_mode": "read_only"
}
```

## Understanding the Output

### Puppet Exit Codes

- **0**: No changes needed (PASS)
- **2**: Changes would be made in real run (WARN/FAIL)
- **4+**: Failures (FAIL)

### Status Mapping

- **PASS**: All resources in desired state (no drift)
- **WARN**: Drift detected (settings out of compliance)
- **FAIL**: Puppet validation errors
- **SKIP**: Puppet not installed or config file missing

### Evidence

The `evidence` field contains the last 1000 characters of Puppet output, showing which resources are out of sync.

## Example Scenarios

### Scenario 1: SSH PasswordAuthentication Enabled (Drift)

**Current state**: `/etc/ssh/sshd_config` has `PasswordAuthentication yes`  
**Desired state**: `PasswordAuthentication no` (NIST baseline)

**Puppet noop output**:
```
Notice: /Stage[main]/Grc_audit::Ssh_hardening/File_line[ssh_password_authentication]/ensure: 
  current_value 'absent', should be 'present' (noop)
```

**Wrapper finding**:
```json
{
  "control": "IA-2",
  "status": "WARN",
  "message": "SSH configuration drift detected: 1 setting(s) out of compliance"
}
```

### Scenario 2: All Settings Compliant

**Current state**: All SSH settings match NIST baselines  
**Puppet noop output**: `Notice: Applied catalog in 0.03 seconds` (no changes)

**Wrapper finding**:
```json
{
  "control": "IA-2",
  "status": "PASS",
  "message": "All SSH hardening settings in desired state (no drift detected)"
}
```

## Customizing Baselines

Edit `puppet/modules/grc_audit/manifests/ssh_hardening.pp`:

```puppet
class grc_audit::ssh_hardening (
  # Allow password auth for dev environments
  Enum['yes', 'no'] $password_auth_allowed = 'yes',  # Changed from 'no'
  # ... other params
) {
  # ...
}
```

Or pass parameters:

```bash
puppet apply --noop --modulepath=./puppet/modules \
  -e "class { 'grc_audit::ssh_hardening': password_auth_allowed => 'yes' }"
```

## HITL Guardrails

**NEVER run without `--noop` unless you have documented HITL approval:**

```bash
# ❌ DO NOT DO THIS without HITL approval
puppet apply --modulepath=./puppet/modules \
  -e 'include grc_audit::ssh_hardening'

# ✅ Always use noop for audit
puppet apply --noop --modulepath=./puppet/modules \
  -e 'include grc_audit::ssh_hardening'
```

The wrapper script enforces noop mode and will not apply changes.

## Integration with GRCToolKit

### Future: Runner API Endpoint

```bash
# POST /run-puppet
curl -X POST http://localhost:8081/run-puppet \
  -H "Content-Type: application/json" \
  -d '{"module": "ssh_hardening"}'

# Response
{
  "findings": [{
    "control": "IA-2",
    "status": "PASS",
    "message": "All SSH hardening settings in desired state"
  }]
}
```

### Future: OSCAL Export

Findings will map to OSCAL assessment results:

```json
{
  "control-id": "IA-2",
  "status": "pass",
  "remarks": "All SSH hardening settings in desired state",
  "evidence": "puppet noop report",
  "assessment-method": "puppet-noop",
  "timestamp": "2026-09-30T15:47:32Z"
}
```

## Troubleshooting

### "Puppet not installed"

Install Puppet 7+ or run in syntax-only mode (smoke test will skip runtime checks).

### "SSH config not found"

The module checks for `/etc/ssh/sshd_config` (Linux/Unix). Windows support is deferred.

### "Permission denied"

Puppet needs read access to `/etc/ssh/sshd_config`. On most systems, this is world-readable.

### Module not found

Ensure `--modulepath` points to `./puppet/modules` (repo root).

## Next Steps

1. Review design doc: `docs/PUPPET-AUDIT-ENGINE.md`
2. Add more modules (file permissions, package baseline, audit daemon)
3. Integrate with Runner API
4. Add OSCAL export
5. Windows Registry/ACL checks

---

**Version:** 0.1 (POC)  
**Last Updated:** 2026-09-30  
**Branch:** `cursor/puppet-audit-engine-a598`  
**PR:** https://github.com/iFocus-Innovations-LLC/GRCToolKit/pull/52
