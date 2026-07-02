# GRCToolKit — Product Management TODO

Lightweight backlog for post-production initiatives and cross-cutting release gates.
For technical roadmap detail, see [ROADMAP.md](ROADMAP.md).

**Last updated:** 2026-07-02

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

---

## Production gate (Shields Up implementation)

Start Shields Up **code** (probes, scripts, CI) only when all P0 items above are complete and P1 planning docs are reviewed.

Branch: `feature/shields-up-robotics` — **do not merge to `main` until production gate passes.**
