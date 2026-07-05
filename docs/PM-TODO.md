# GRCToolKit — Product Management TODO

Lightweight backlog for post-production initiatives and cross-cutting release gates.
For technical roadmap detail, see [ROADMAP.md](ROADMAP.md).  
For brand ladder and Enterprise tiers, see [BRAND-AND-EDITIONS.md](BRAND-AND-EDITIONS.md).

**Last updated:** 2026-07-05

---

## Ansible audit safety (v1 + post-v1)

- [x] v1: [ANSIBLE-AUDIT-OPERATIONS.md](ANSIBLE-AUDIT-OPERATIONS.md) + localhost-only runner API + sudo manual steps in OSCAL JSON/PDF
- [ ] Post-v1: read-only refactor AC/AU/SC playbooks (acceptance: no `systemd state:` mutations; `grc_audit_mode: read_only`; scoped `find` paths; align with OWASP LLM playbook pattern)
- [ ] Post-v1: inventory templates for production (SSH, become, change-window vars, audit service account + optional sudoers allow-list)

---

## Post-production backlog

### P0 — GRCToolKit production (blocker for robotics)

- [ ] Merge `dev` → `main` with governance, CI green, GCP QA path validated
- [ ] Production release tag (e.g. v2.1.0 or v3.0.0)
- [ ] Open-source governance live on `main` (CONTRIBUTING, CODEOWNERS, issue/PR templates)
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
- [ ] Conference / DoW demo narrative (optional Phase 2)
- [ ] PM sign-off before merge to `main`

### P2 — Branding ladder and Enterprise edition (commercial planning)

- [x] Draft [BRAND-AND-EDITIONS.md](BRAND-AND-EDITIONS.md) — brand builds up to Enterprise
- [ ] iFocus sign-off on brand ladder and tier definitions
- [ ] Document **conversion triggers** (audit prep, training, token pools, Shields Up fleet) in sales collateral
- [ ] Define Bronze / Silver / Gold / Platinum **support SLAs** (response times, channels)
- [ ] Define **training catalog** per tier (onboarding, HITL, OSCAL auditor, Shields Up operator)
- [ ] Map Shields Up inclusion by tier (Community OSS → Silver guidance → Gold+ hands-on)
- [ ] Legal: Enterprise EULA, support agreement, token usage terms (separate from MIT LICENSE)
- [ ] Sales one-pager derived from [OVERVIEW.md](OVERVIEW.md)
- [ ] **Pricing dollars TBD** after pilot customers and macro review (replace any legacy Starter/Professional tables)

### P3 — Agentic AI token economics (product + pricing)

- [ ] Document **token pricing model**: input/output tokens per workflow
  - GRC scenario analysis (`ai-agent/grc-compliance-engine.js`)
  - CI AI PR review (`.github/workflows/ai-pr-review.yml`)
  - nist-validator skill (`skills/nist-validator/`)
  - Shields Up AI triage report step
  - OpenClaw / sentinel agents (future)
- [ ] **BYOK vs bundled pools** per Enterprise tier (Gemini, Anthropic, Vertex)
- [ ] Define **metering points** in codebase (future implementation)
- [ ] **Usage caps and HITL alerts** when Tier-3 (human-guided) scenarios spike token use
- [ ] Overage billing rules and audit log fields (who, scenario, tokens, model ID) — align with [HITL-FRAMEWORK.md](HITL-FRAMEWORK.md)
- [ ] Cost pass-through vs margin on bundled tokens (macro-sensitive; review quarterly under P4)

### P4 — AI macro and competitive intelligence (quarterly review)

Review **quarterly**; update ROADMAP and token economics when provider pricing shifts.

| Track | Leaders / signals to monitor |
|-------|------------------------------|
| **Hyperscaler AI** | Google (Gemini, Vertex, GCP), Microsoft/OpenAI, Amazon Bedrock |
| **Agentic platforms** | Anthropic (Claude, MCP), OpenAI agents, Cursor / agent SDKs |
| **Physical AI / sim** | NVIDIA (ovrtx, Isaac, Omniverse), PTC, Siemens |
| **GRC / compliance AI** | OSCAL adoption, FedRAMP/RMF automation vendors |
| **Macro** | Enterprise AI spend surveys, token list price changes, inference cost curves |

- [ ] Schedule first **Q3 2026** macro review
- [ ] Track repo model defaults (`gemini-2.5-flash`, Claude in ai-pr-review) vs market best practice
- [ ] Revisit bundled token pool sizing when Gemini/Anthropic pricing changes

---

## Production gate (Shields Up implementation)

Start Shields Up **code** (probes beyond LLM playbook, fleet schedulers) only when all P0 items above are complete and P1 planning docs are reviewed.

Branch: `feature/shields-up-robotics` — **do not merge to `main` until production gate passes.**

Enterprise commercial launch is **not blocked** on Shields Up code — but brand docs should stay aligned with [BRAND-AND-EDITIONS.md](BRAND-AND-EDITIONS.md).
