# Ansible Audit Operations — Safe Validation Handoff (v1)

**Version:** 1.0 (v1 release)  
**Audience:** GRC analysts, system administrators, IT security operators, auditors  
**Related:** [HITL Framework](HITL-FRAMEWORK.md) · [OSCAL Integration](OSCAL-INTEGRATION.md) · [Security](SECURITY.md) · [Command Matrix](ANSIBLE-AUDIT-COMMAND-MATRIX.md)

---

## Purpose

GRCToolKit maps GRC scenarios to NIST 800-53 controls and can produce **OSCAL assessment plans** and **evidence reports** (JSON/PDF). Running Ansible playbooks against production hosts requires **root or sudo** on many checks. **v1 is docs-first and lab-safe:** the web UI must not be treated as an unattended production scanner.

This guide defines how organizations run validation **without outages**, align with **ITIL-style change windows**, and hand off work from **System Administrators** to **IT Security Operators**.

---

## Safety principles (v1)

| Principle | Meaning |
|-----------|---------|
| **Audit-only** | Collect evidence; no remediation from GRCToolKit |
| **Human-in-the-loop** | Production runs require human approval — see [HITL Framework](HITL-FRAMEWORK.md) Tier 2/3 |
| **Change window** | Schedule playbook execution in an approved maintenance or after-hours window (ITIL Standard Change) |
| **Lab vs production** | UI **Validate Controls** is for localhost QA only; production uses **manual CLI** from a jump host |
| **No silent mutation** | AC-3, AC-6, AU-2, SC-7 playbooks use `grc_audit_mode: read_only` — probes only; no `systemd` state changes |

**Reference posture (target state):** [`ansible/playbooks/llm/owasp-llm-top-10-validate.yml`](../ansible/playbooks/llm/owasp-llm-top-10-validate.yml) — read-only intent, conditional privilege escalation, HITL/no auto-remediation.

---

## RACI handoff

| Role | Responsibility |
|------|----------------|
| **GRC Analyst** | Describe scenario in GRCToolKit; review AI control recommendations; export OSCAL assessment plan (PDF) |
| **System Administrator** | Approve change window; provide inventory (`ansible_user`, SSH, become); optional limited sudo for audit account |
| **IT Security Operator** | Review playbooks; execute manually from jump host; attach stdout + OSCAL/PDF evidence |
| **Auditor / GRC Lead** | Review assessment results under change/ticket ID; accept or reject evidence package |

```text
GRC Analyst → OSCAL plan/PDF → SysAdmin (window + access) → IT Sec Operator (ansible-playbook) → Auditor
```

---

## ITIL-aligned execution model

1. **Request** — GRC or security opens a ticket (Standard Change) for read-only compliance validation.
2. **Schedule** — After-hours or maintenance window; notify operations if checks touch auth, audit, or network stacks.
3. **Prepare** — SysAdmin confirms inventory, audit account, and sudo policy (see checklist below).
4. **Execute** — IT Security Operator runs playbooks manually; never from an unattended browser session against production.
5. **Evidence** — Store JSON/PDF under `/tmp/grc-oscal-reports/` (local demo) or org-approved evidence store; link ticket ID in filename or metadata.
6. **Review** — Auditor validates OSCAL artifacts; HITL gate for any follow-up remediation (out of scope for GRCToolKit automation).

---

## Manual execution runbook (recommended for production)

Run from a **jump host** or authorized admin workstation — not from the GRCToolKit web UI against remote hosts in v1.

```bash
cd ansible/playbooks

# 1. Review playbook tasks before running
less ac-3-access-enforcement.yml

# 2. Set ITIL change ID for evidence metadata (wrapper scripts + OSCAL)
export GRCTOOLKIT_CHANGE_ID="CHG-2026-001"

# 3. Dry-run (read-only playbooks; verify connectivity and become)
ansible-playbook -i inventory.production.yml ac-3-access-enforcement.yml \
  --check --diff --limit prod_targets

# 4. After-hours execution — grc-audit NOPASSWD for GRC_AUDIT wrappers only
ansible-playbook -i inventory.production.yml ac-3-access-enforcement.yml \
  --limit prod_targets

# 5. Direct wrapper probe (optional; same sudoers entrypoints)
sudo -u grc-audit /usr/local/sbin/grc-audit-au-2

# 6. OWASP LLM read-only probe (app/HTTP checks; preferred low-risk profile)
cd llm
ansible-playbook -i inventory.yml owasp-llm-top-10-validate.yml
```

**Production inventory template:** [`ansible/playbooks/inventory.production.example.yml`](../ansible/playbooks/inventory.production.example.yml) — copy to a **private** repo; customize hosts and SSH.

See [`ansible/playbooks/inventory.yml`](../ansible/playbooks/inventory.yml) for **localhost lab** demo only.

### Windows targets (roadmap)

Linux `grc-audit` / SSH / sudoers paths above **do not** apply to Microsoft Windows. A parallel track will use:

- Inventory group `windows_targets` (WinRM or documented SSH-on-Windows)
- [Chocolatey](https://chocolatey.org/) for lab/QA bootstrap (HITL before package install/upgrade)
- Future playbooks under `ansible/playbooks/windows/`

See [ROADMAP — Windows OS Ansible validation](ROADMAP.md#windows-os-ansible-validation-chocolatey) and [PM-TODO P4](PM-TODO.md#p4--windows-ansible--chocolatey). Do not enable remote Windows from the v1 UI/runner without SysAdmin RACI.

---

## System Administrator checklist

Before IT Security runs playbooks:

- [ ] Change ticket approved and window scheduled; record ticket ID (e.g. `CHG-2026-001`)
- [ ] Create dedicated **`grc-audit`** UNIX account (no password login; SSH key from jump host only)
- [ ] Install probe wrappers to `/usr/local/sbin/` — see [`ansible/scripts/grc-audit-probes/README.md`](../ansible/scripts/grc-audit-probes/README.md)
- [ ] Deploy `/etc/sudoers.d/grc-audit` from [`ansible/templates/sudoers.d/grc-audit`](../ansible/templates/sudoers.d/grc-audit); validate with `visudo -cf /etc/sudoers.d/grc-audit`
- [ ] Grant **file read** via POSIX group/ACL on `/var/log/audit` where possible to reduce sudo surface
- [ ] Deny `grc-audit` write to `/etc`, `/usr`, and service management outside `GRC_AUDIT` Cmnd_Alias
- [ ] Production inventory in **private** config repo — never host IPs or keys in GRCToolKit git
- [ ] Confirm playbooks use `grc_audit_mode: read_only` ([`group_vars/all.yml`](../ansible/playbooks/group_vars/all.yml))
- [ ] **Do not** expose local runner API (`:8081`) beyond `127.0.0.1`

### grc-audit service account

| Property | Value |
|----------|--------|
| Login | SSH key from jump host only; no password |
| Shell | `/sbin/nologin` or restricted; operators run `ansible-playbook` from jump host |
| Sudo | **NOPASSWD** only for `GRC_AUDIT` wrapper scripts — never blanket `ALL` |
| Evidence | Wrappers emit JSON with `change_id` when `GRCTOOLKIT_CHANGE_ID` is set |

### Sudoers deployment (illustrative — org legal/security review required)

Template: [`ansible/templates/sudoers.d/grc-audit`](../ansible/templates/sudoers.d/grc-audit)

```sudoers
Cmnd_Alias GRC_AUDIT = /usr/local/sbin/grc-audit-ac-3, \
                        /usr/local/sbin/grc-audit-ac-6, \
                        /usr/local/sbin/grc-audit-au-2, \
                        /usr/local/sbin/grc-audit-sc-7

Defaults!GRC_AUDIT !authenticate

grc-audit ALL=(root) NOPASSWD: GRC_AUDIT
```

Per-command mapping (Option B interim): [ANSIBLE-AUDIT-COMMAND-MATRIX.md](ANSIBLE-AUDIT-COMMAND-MATRIX.md)

### ITIL / HITL change-ticket linkage

Sudoers cannot bind to a ticket UUID natively. For audit trail:

1. SysAdmin approves **Standard Change** (ticket ID e.g. `CHG-2026-001`).
2. Operator exports OSCAL plan from GRCToolKit; runs validation during the window.
3. Set `export GRCTOOLKIT_CHANGE_ID="CHG-2026-001"` before Ansible or wrapper runs.
4. Evidence JSON/PDF metadata should include `changeId` + timestamp.
5. Optional: SysAdmin drops `/etc/grc-audit/approved-run` with ticket ID at window start; wrappers may refuse if missing (org policy).

This is **audit trail**, not cryptographic enforcement — see [HITL Framework](HITL-FRAMEWORK.md).

---

## When automation is not allowed — manual validation alternative

If sudo or Ansible is prohibited on production:

1. Export **OSCAL assessment plan** from GRCToolKit (PDF via Validate → Download OSCAL Report).
2. IT Security Operator performs **equivalent manual checks** listed in the playbook task names (e.g. verify auditd running, review `/etc/audit/rules.d/audit.rules`).
3. Record outcomes in OSCAL **assessment-results** JSON (same structure as `generateComplianceReport` in [`ai-agent/grc-compliance-engine.js`](../ai-agent/grc-compliance-engine.js)).
4. Attach operator notes, ticket ID, and timestamps for auditor review.

---

## Local MVP demo (Mac mini / laptop)

For QA without GCP cost:

```bash
./scripts/run-local.sh
# UI: http://127.0.0.1:8080/local-index.html
# Runner API: http://127.0.0.1:8081/health (localhost only)
```

- **Validate Controls** executes against `localhost` only.
- macOS lacks Linux `systemd`/`auditd` — expect **real FAIL output**; that is honest lab behavior.
- Install Ansible: `brew install ansible`
- PDF reports: `pip` deps via `.venv-local-demo` (see `scripts/requirements-local-demo.txt`)

---

## Known limitations

| Limitation | Mitigation |
|------------|------------|
| Playbooks still use `become` for some probes | `grc-audit` limited to `GRC_AUDIT` wrappers; see command matrix |
| AC-6 scoped `find` can be expensive on large hosts | Limit `grc_audit_find_paths`; run in maintenance window |
| Browser cannot prompt for sudo | Production = CLI handoff from jump host, not UI |
| UI/API restricted to **localhost** | Remote inventory rejected by runner API |
| Sudoers template is illustrative | Org legal/security review before production deploy |

---

## Post-v1 roadmap

Tracked in [PM-TODO.md](PM-TODO.md):

- [x] Read-only refactor for AC-3, AC-6, AU-2, SC-7
- [x] `grc_audit_mode: read_only` group vars
- [x] Production inventory template (`inventory.production.example.yml`)
- [x] `grc-audit` sudoers template + probe wrappers + command matrix
- [ ] Jump-host runner with change-ticket gate (no browser-triggered prod scans)
- [ ] Pilot: one Linux host, one control (e.g. AU-2); validate `/var/log/secure` sudo audit log

---

## Support references

- Playbooks: [`ansible/playbooks/`](../ansible/playbooks/)
- OSCAL catalog: [`oscal/catalog/nist-800-53-r5-catalog.json`](../oscal/catalog/nist-800-53-r5-catalog.json)
- PDF reports: [`.cursor/skills/oscal-pdf-report/SKILL.md`](../.cursor/skills/oscal-pdf-report/SKILL.md) (agent skill)
