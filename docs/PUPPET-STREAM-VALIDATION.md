# Puppet Audit Engine - Stream Separation Validation

## Architecture Improvements (Per Code Review)

### 1. Clean Stream Separation ✅
```bash
# JSON output → stdout ONLY
./scripts/puppet-audit-wrapper.sh ... > finding.json 2> debug.log

# Debug output → stderr (behind GRC_DEBUG=1)
GRC_DEBUG=1 ./scripts/puppet-audit-wrapper.sh ... > finding.json 2> debug.log
```

### 2. Reliable Temp Directory Management ✅
```bash
# Before: Timestamp-based coordination (brittle)
TIMESTAMP=$(date +%s)
echo "$vardir" > "/tmp/puppet-vardir-${TIMESTAMP}.txt"

# After: mktemp -d with direct variable passing
run_dir=$(mktemp -d -t puppet-grc-XXXXXX)
puppet apply --vardir="$run_dir/vardir" ...
exit_code=$?  # Direct capture
```

### 3. Explicit Error Handling ✅
```bash
# Check report exists before parsing
if [[ ! -f "$report_file" ]]; then
  emit_json status="ERROR" message="Report not generated"
  return 1
fi

# Never fall back to PASS when evidence missing
```

## CI Validation Results

### Run #36755981941 (commit 290d5ba) ✅

#### Test 1: Compliant Config
```json
{
  "status": "PASS",
  "evidence": "10 resources checked, 0 out of sync, 0 failed"
}
```
- ✅ Clean JSON to stdout
- ✅ No stderr pollution
- ✅ Correct PASS status

#### Test 2: Non-Compliant Config
```json
{
  "status": "WARN",
  "evidence": "10 resources checked, 3 out of sync, 0 failed. Failing checks: check_password_auth, check_permit_root_login, check_pubkey_auth"
}
```
- ✅ Clean JSON to stdout
- ✅ All three failing checks explicitly named
- ✅ Correct WARN status
- ✅ Evidence validated for PasswordAuthentication, PermitRootLogin, PubkeyAuthentication

#### Test 3: OSCAL Export
- ✅ Both fixtures export valid OSCAL 1.0.4 JSON
- ✅ Validated with jq

## Implementation Details

### Wrapper Script Changes
1. **mktemp -d**: Creates `/tmp/puppet-grc-XXXXXX` per run
2. **Direct exit code**: `exit_code=$?` captured in variable
3. **Explicit vardir**: `--vardir="$run_dir/vardir"` passed to Puppet
4. **Stream separation**: 
   - `echo "$finding_json"` → stdout
   - `debug() { [[ "$GRC_DEBUG" == "1" ]] && echo "$*" >&2; }` → stderr
5. **Error status**: Return `ERROR` if `last_run_report.yaml` missing

### CI Workflow Changes
```yaml
# Before: Mixed streams
> /tmp/wrapper.json 2>&1

# After: Separated streams
> /tmp/wrapper.json 2> /tmp/wrapper.err
```

## Status: Production Ready

All code review requirements met:
- ✅ mktemp -d for temp directories
- ✅ stdout = JSON only, stderr = debug (GRC_DEBUG=1)
- ✅ CI separates streams: `> out.json 2> err.log`
- ✅ Direct exit code capture
- ✅ ERROR status on missing report (no PASS fallback)
- ✅ Compliant → PASS
- ✅ Non-compliant → WARN with named checks
- ✅ OSCAL export validated

Ready for experimental Ansible integration.
