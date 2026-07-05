# Ansible Audit Operations — Safe Validation Handoff (v1)

**Version:** 1.0 (v1 release)  
**Audience:** GRC analysts, system administrators, IT security operators, auditors  
**Related:** [HITL Framework](HITL-FRAMEWORK.md) · [OSCAL Integration](OSCAL-INTEGRATION.md) · [Security](SECURITY.md)

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
| **No silent mutation** | Current AC/AU/SC playbooks may change service state if run without `--check` — treat as **pre-production / lab** until read-only refactor ships |

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

# 2. Dry-run where supported (does not execute mutating tasks; verify behavior per module)
ansible-playbook -i inventory.yml ac-3-access-enforcement.yml \
  --check --diff --limit target_host

# 3. After-hours execution with interactive sudo (operator present)
ansible-playbook -i inventory.yml ac-3-access-enforcement.yml \
  --limit target_host --ask-become-pass

# 4. OWASP LLM read-only probe (app/HTTP checks; preferred low-risk profile)
cd llm
ansible-playbook -i inventory.yml owasp-llm-top-10-validate.yml
```

**Inventory example (production — template only; customize per org):**

```yaml
all:
  hosts:
    target_host:
      ansible_host: 10.0.1.50
      ansible_user: grc-audit
      ansible_become: true
      ansible_connection: ssh
```

See [`ansible/playbooks/inventory.yml`](../ansible/playbooks/inventory.yml) for **localhost lab** demo only.

---

## System Administrator checklist

Before IT Security runs playbooks:

- [ ] Change ticket approved and window scheduled
- [ ] Dedicated **audit service account** (no interactive login; SSH key from jump host only)
- [ ] Operator can read: `/etc`, `/var/log/audit`, `systemctl status` (read-only)
- [ ] **Optional:** `/etc/sudoers.d/grc-audit` with explicit command allow-list (legal/security review required — template below is illustrative only)
- [ ] Inventory file committed to **private** config repo — never secrets in GRCToolKit git
- [ ] Confirm playbooks reviewed for mutating tasks (`systemd: state: started` etc.) — use `--check` first
- [ ] **Do not** expose local runner API (`:8081`) beyond `127.0.0.1`

**Illustrative sudoers snippet (org must review):**

```sudoers
# Example only — replace user, host, and commands per policy
grc-audit ALL=(root) NOPASSWD: /bin/systemctl status *, /usr/bin/stat, /bin/grep
```

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

## Known v1 limitations

| Limitation | Mitigation |
|------------|------------|
| Core playbooks use `become: yes` | Manual `--ask-become-pass`; post-v1 read-only refactor |
| AC-3 may **start/enable** services via `systemd` | Use `--check` first; do not run unattended on production |
| AC-6 `find /` can be expensive | Scope to lab hosts; post-v1 path limits |
| Browser cannot prompt for sudo | Production = CLI handoff, not UI |
| UI/API v1 restricted to **localhost** | Remote inventory rejected by runner API |

---

## Post-v1 roadmap (not in first release)

Tracked in [PM-TODO.md](PM-TODO.md):

- Read-only refactor for AC-3, AC-6, AU-2, SC-7
- `grc_audit_mode: read_only` group vars
- Production inventory templates (SSH, become, change window vars)
- Jump-host runner with change-ticket gate (no browser-triggered prod scans)

---

## Support references

- Playbooks: [`ansible/playbooks/`](../ansible/playbooks/)
- OSCAL catalog: [`oscal/catalog/nist-800-53-r5-catalog.json`](../oscal/catalog/nist-800-53-r5-catalog.json)
- PDF reports: [`.cursor/skills/oscal-pdf-report/SKILL.md`](../.cursor/skills/oscal-pdf-report/SKILL.md) (agent skill)
