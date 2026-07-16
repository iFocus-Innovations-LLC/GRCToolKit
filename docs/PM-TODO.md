# GRCToolKit — Product Management TODO

Lightweight backlog for post-production initiatives and cross-cutting release gates.
For technical roadmap detail, see [ROADMAP.md](ROADMAP.md).

**Last updated:** 2026-07-16

---

## Ansible audit / grc-audit sudoers (post-v1)

- [x] Read-only refactor: AC-3, AC-6, AU-2, SC-7 (`grc_audit_mode: read_only`)
- [x] [ANSIBLE-AUDIT-COMMAND-MATRIX.md](ANSIBLE-AUDIT-COMMAND-MATRIX.md)
- [x] Probe wrappers: `ansible/scripts/grc-audit-probes/`
- [x] Sudoers template: `ansible/templates/sudoers.d/grc-audit`
- [x] Production inventory example: `ansible/playbooks/inventory.production.example.yml`
- [x] Ops guide: [ANSIBLE-AUDIT-OPERATIONS.md](ANSIBLE-AUDIT-OPERATIONS.md) — grc-audit handoff
- [ ] Pilot one Linux host (AU-2); confirm sudo audit log in `/var/log/secure`

---

## Post-production backlog

### P0 — GRCToolKit production (blocker for robotics)

- [ ] Merge `dev` → `main` with governance, CI green, GCP QA path validated
- [ ] Production release tag (e.g. v2.1.0 or v3.0.0)
- [ ] Open-source governance live on `main` (CONTRIBUTING, CODE_OF_CONDUCT on `main` since #35 — confirm GitHub sidebar badges on public repo)
- [ ] GCP dev path documented and tested per [SECRETS-SETUP.md](SECRETS-SETUP.md)

### P1 — Shields Up robotics (after production)

- [x] Create branch `feature/shields-up-robotics` from `main`
- [x] Add [SHIELDS-UP-ROBOTICS.md](SHIELDS-UP-ROBOTICS.md) vision + MVP spec
- [x] Define `ansible/playbooks/llm/` OWASP LLM Top 10 read-only probe playbook
- [ ] Define `ansible/playbooks/robot/` probe catalog (read-only)
- [ ] Map probes → OWASP categories + NIST SC/AC/AU controls + RSF layers
- [ ] AI report template (reuse `compliance-docs/` patterns)
- [ ] HITL gate: no remediation without human approval
- [ ] Lab environment: Dockerized ROS 2 + rosbridge test target
- [ ] Conference / DoW demo narrative (optional Phase 2) — see **P2** DoW Commercial Solutions demo
- [ ] PM sign-off before merge to `main`

### P2 — DoW PQC Strategy alignment

**Source:** [DoW Post Quantum Cryptography Strategy](https://dowcio.war.gov/Portals/0/Documents/Library/DoW-PQC-Strategy.pdf)  
**Roadmap:** [ROADMAP.md — DoW PQC Strategy alignment](ROADMAP.md#dow-pqc-strategy-alignment)

GRCToolKit aligns to the **Commercial Solutions** track and **LOE 2 / LOE 5** evidence workflows. HA-ECU / Type 1 / KMI are out of scope.

#### Docs / positioning (immediate)

- [x] ROADMAP DoW LOE map + multi-mandate deadline model published
- [x] OVERVIEW + README deadline language updated to multi-mandate (DoW 2030/2031 + CNSA; retain 2030/2035 as civilian track)
- [ ] Conference / DoW demo narrative written against LOE 2/5 Commercial Solutions track (inventory → risk → support/use gates → OSCAL; HITL before deploy)

#### Product backlog (post–production gate or parallel on `dev`)

- [ ] Timeline engine: DoW support/use gates (2030/2031) + CNSA 2.0 category dates + optional NIST 2030/2035 civilian track
- [ ] Inventory schema: NSS/non-NSS, algorithm suite (NIST vs CNSA 2.0), pathway completeness
- [ ] Risk scoring: HNDL + forged-signature/TNFL; fail “PQC complete” if auth/signatures not migrated
- [ ] Policy guardrails in AI prompts + playbook docs: reject QKD / PSK-without-PQC as quantum resistance
- [ ] OSCAL properties for DoW gates and CNSA awareness
- [ ] Wire `pqc/` modules into UI or fold logic into active `grc-compliance-engine.js`
- [ ] HITL gate remains mandatory for all PQC deploy playbooks (AU-2 audit trail)

#### Explicit out of scope

- HA-ECU / Type 1 / KMI certification workflows
- Claiming DoW CIO pre-deployment approval authority
- FedRAMP / IL-authorized managed service claims

### P3 — Agentic tokens, ADK runtime, GCP throttle

**Framework:** [Agent Development Kit (ADK)](https://adk.dev/)  
**Roadmap:** [ROADMAP.md — Agentic GRC runtime (ADK) + token throttling](ROADMAP.md#agentic-grc-runtime-adk--token-throttling)  
**Brand / economics:** [BRAND-AND-EDITIONS.md](BRAND-AND-EDITIONS.md) agentic token economics

“Autonomous GRC” = scheduled **assessment/triage** with HITL before remediation. Python ADK for hosted runtime; Community stays browser BYOK.

#### Docs / policy

- [x] ROADMAP ADK + throttle section published
- [ ] Document GCP QA budget + scheduler defaults in [SECRETS-SETUP.md](SECRETS-SETUP.md) / [DEPLOYMENT.md](DEPLOYMENT.md) cross-link

#### Product (after P0 or parallel on `dev` — not before GCP budget alerts exist)

- [ ] Prototype Python ADK agent: scenario analysis → read-only Ansible tool → OSCAL artifact
- [ ] ADK HITL `RequestInput` / tool confirmation before any remediate tool
- [ ] Token metering: capture usage metadata; log model ID + tokens to AU-2 audit trail
- [ ] Throttle stack for GCP QA: Scheduler cadence (daily default / hourly max), concurrency = 1, daily token budget, 429 exponential backoff
- [ ] Circuit breaker: pause scheduled runs when budget exceeded
- [ ] Enterprise metering API stub (pool vs BYOK) — pricing TBD

#### Explicit out of scope

- Fully autonomous remediation
- Unbounded multi-agent loops in shared GCP QA project

---

## Production gate (Shields Up implementation)

Start Shields Up **code** (probes, scripts, CI) only when all P0 items above are complete and P1 planning docs are reviewed.

Branch: `feature/shields-up-robotics` — **do not merge to `main` until production gate passes.**
