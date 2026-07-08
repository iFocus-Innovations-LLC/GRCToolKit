# Conference & Customer Demo Guide (CISO / C-Suite)

**Audience:** CISO, VP Risk, GRC leads, technical evaluators  
**Duration:** 12–18 minutes (live) + 5 minutes Q&A  
**Last updated:** 2026-07-07

---

## Executive summary (30 seconds)

> *"GRCToolKit turns a plain-language risk question into NIST 800-53 controls, runs read-only validation, and produces auditor-ready OSCAL evidence — in minutes, not months. Today you’ll see the lab demo on a laptop; production uses approved change windows and least-privilege audit accounts — never unattended browser scans."*

**Three outcomes to land:**

| Outcome | What they see |
|---------|----------------|
| **Speed** | Scenario → controls in under a minute |
| **Evidence** | Live Ansible validation + OSCAL JSON/PDF |
| **Trust** | HITL guardrails, read-only production posture, no auto-remediation |

---

## Pre-demo setup (5 minutes before)

```bash
export GEMINI_API_KEY="your-key-from-google-ai-studio"
./scripts/run-local.sh
```

Open **http://127.0.0.1:8080/local-index.html** (not the raw `grctoolkit.html` — the script injects your key into `local-index.html` only).

**Optional:** `brew install ansible` so **Validate Controls** runs real playbooks (runner API on `127.0.0.1:8081`).

**Docker alternative:**

```bash
docker build -t grc-toolkit .
docker run -p 8080:8080 -e GEMINI_API_KEY=$GEMINI_API_KEY grc-toolkit
# Open http://localhost:8080/
```

---

## Demo script

### 1. Frame the problem (2 min)

**CISO talking points:**

- Control mapping is still manual: analysts grep spreadsheets, consultants bill hours.
- Evidence collection is inconsistent across teams and environments.
- Auditors want **standardized artifacts** (OSCAL), not slide decks.

**Do not lead with:** Ansible modules, Gemini model IDs, or container UID details.

---

### 2. Scenario → controls (3 min)

1. Enter: *"How do you enforce least privilege on my system?"*
2. Click **Analyze Scenario**.
3. Show recommended controls (expect **AC-6**, often **AC-3**, **AU-2**).

**Say:**

> *"The engine maps natural language to NIST SP 800-53 Rev. 5 — the same catalog federal agencies use. Your team reviews recommendations; nothing is applied automatically."*

**If asked about AI risk:** Point to [HITL Framework](HITL-FRAMEWORK.md) — human review tiers, confidence scoring, audit trail for overrides.

---

### 3. Validate controls (4 min)

1. Click **Validate Controls**.
2. Show **Live Ansible on localhost** — playbooks execute read-only probes.
3. Walk through **Validation Summary** (pass/fail, findings).

**Say:**

> *"This is evidence collection, not remediation. Playbooks are read-only in our current profile — they don’t start services or change configs. On macOS lab hosts you’ll see honest gaps for Linux-only checks; production targets Linux with a dedicated `grc-audit` account and least-privilege sudo."*

**Production handoff (one sentence):** See [ANSIBLE-AUDIT-OPERATIONS.md](ANSIBLE-AUDIT-OPERATIONS.md) — ITIL change window, jump host, SysAdmin RACI.

---

### 4. OSCAL evidence package (3 min)

1. After validation, click **Download OSCAL Report (PDF)**.
2. Briefly show JSON structure + PDF sections (assessment plan, findings, manual-validation notes where sudo is required).

**Say:**

> *"OSCAL is NIST’s machine-readable compliance language. Your auditors and GRC tools can ingest this without a custom export. Ticket ID and change-window metadata can be bound in production runs."*

---

### 5. Close — business value (2 min)

| Stakeholder | Value |
|-------------|--------|
| **GRC / Risk** | Faster control selection, consistent evidence |
| **Security ops** | Read-only validation, `grc-audit` sudo model, no silent mutation |
| **Audit** | OSCAL JSON/PDF, traceable run metadata |
| **Executive** | Shorter assessment cycles; defensible artifacts for board/regulators |

**Call to action:**

- Try locally: `./scripts/run-local.sh`
- Contribute: [CONTRIBUTING.md](../CONTRIBUTING.md) · [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md)
- Enterprise path: GCP/Kubernetes per [OVERVIEW.md](OVERVIEW.md) and [DEPLOYMENT.md](DEPLOYMENT.md)

---

## Recommended demo scenarios

### Primary (least privilege — tested locally)

**Input:** *"How do you enforce least privilege on my system?"*  
**Controls:** AC-6, AC-3, AU-2  
**Why:** Maps to live playbooks; validation passes on macOS lab with Linux gaps noted.

### Cloud / data access

**Input:** *"How do I secure access to our cloud database containing customer financial data?"*  
**Controls:** AC-3, AC-6, SC-7, AU-2

### Audit logging

**Input:** *"How do I implement audit logging for our financial transaction system?"*  
**Controls:** AU-2, AU-3, AU-4, AU-5

### PQC (differentiator)

**Input:** *"We're a financial services organization with 20-year data retention. How do we prepare for post-quantum cryptography migration?"*  
**Controls:** SC-12, SC-13, SC-17, SC-28 — tie to [PQC Integration Summary](PQC-INTEGRATION-SUMMARY.md).

---

## CISO Q&A cheat sheet

| Question | Short answer |
|----------|----------------|
| **Does this auto-fix findings?** | No. HITL Tier 3 — remediation requires documented human approval. |
| **Can we run this against production from the browser?** | No in v1. UI/API are localhost lab only; production = jump host + change ticket. |
| **How is privilege limited on targets?** | Dedicated `grc-audit` account; sudo limited to fixed probe scripts — [command matrix](ANSIBLE-AUDIT-COMMAND-MATRIX.md). |
| **What frameworks besides NIST?** | OSCAL catalog is NIST 800-53 R5 today; architecture is framework-agnostic. |
| **How do we integrate with ServiceNow / Archer?** | OSCAL JSON export; APIs and connectors on roadmap — [ROADMAP.md](ROADMAP.md). |
| **What about false positives?** | Human review of AI recommendations; read-only probes collect evidence for analyst judgment. |

---

## Technical appendix (for evaluators)

- **UI:** `grctoolkit.html` → `local-index.html` via `scripts/run-local.sh`
- **Engine:** Gemini v1beta structured JSON (`gemini-2.5-flash` default)
- **Validation:** `ansible/playbooks/` — AC-3, AC-6, AU-2, SC-7 (read-only)
- **Skills:** `skills/nist-validator/` — K8s-scoped control validation (explore for cluster audits)
- **Reports:** `scripts/oscal_pdf.py` + local runner API

---

## Demo checklist

- [ ] `GEMINI_API_KEY` exported
- [ ] `./scripts/run-local.sh` running; browser on `local-index.html`
- [ ] Ansible installed (optional but recommended for live validation)
- [ ] Scenario rehearsed once end-to-end
- [ ] PDF download tested (runner API healthy: `curl http://127.0.0.1:8081/health`)
- [ ] Production handoff talking point ready ([ANSIBLE-AUDIT-OPERATIONS.md](ANSIBLE-AUDIT-OPERATIONS.md))

---

**Related:** [GCP Demo Guide](GCP-DEMO-GUIDE.md) · [QA Testing Guide](QA-TESTING-GUIDE.md) · [Project Overview](OVERVIEW.md)
