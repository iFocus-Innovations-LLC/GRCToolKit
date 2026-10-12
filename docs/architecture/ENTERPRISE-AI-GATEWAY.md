# GRCToolKit Enterprise: AI Gateway Architecture

**Status:** DRAFT / Planning document for Shields Up Enterprise  
**Date:** 2026-10-12  
**Owner:** Shields Up LLC  
**Scope:** Not Sprint 2 scope  
**Related Issues:** [#68 - LLM Proxy](https://github.com/iFocus-Innovations-LLC/GRCToolKit/issues/68), [#69 - Enterprise Platform](https://github.com/iFocus-Innovations-LLC/GRCToolKit/issues/69)

---

## 1. Goal

The report is only as good as its sources. Facts come from authoritative backend data (NIST SP 800-53 / OSCAL catalogs, CISA advisories, STIX 2.1 IOCs), never from the model's memory. Any LLM, whether local or in the cloud, is swappable.

---

## 2. Topology

```
Clients (web, desktop, mobile thin client)
    ↓
Edge: Apache/nginx (TLS, mTLS, WAF, IP allowlist, rate limit)
    ↓
GRCToolKit API (auth, tenancy, RAG over source catalogs)
    ↓
AI Gateway: LiteLLM (OpenAI-compatible)
    ↓
    ├── Ollama (local / on-prem GPU)            [default for Enterprise]
    └── Cloud providers (Gemini, OpenAI, Anthropic, Bedrock)  [opt-in per tenant]
```

**Key principles:**

- Only the gateway host may egress to model providers (firewall allowlist)
- Mobile clients never call a model directly; they sync through the edge

---

## 3. Grounding ("reports facts")

**Source store:**

- Versioned NIST 800-53 Rev5 OSCAL catalog and baselines
- CISA advisories and STIX bundles
- Each record hashed and stamped with retrieval timestamp

**Retrieval-first workflow:**

- Candidate controls are retrieved by ID/text
- The model may select only from retrieved IDs
- Structured JSON output validated against a schema
- Unknown control IDs are rejected

**Citation and traceability:**

- Every finding cites a source ID, version, and URL
- Reports show the source and catalog versions they were built from
- Human analyst approval required before any report is final

**Quality assurance:**

- Eval set: fixed regression suite (e.g., AA26-281A) run on every model or version change

---

## 4. Tiers and Model Policy

| Tier | Models | Cloud Egress |
|------|--------|--------------|
| **Community (MIT)** | BYOK or BYO Ollama | User's choice |
| **Enterprise** | Vetted local model bundle; optional cloud | Off by default, per-tenant toggle |
| **Enterprise air-gapped** | Local only, offline install | Blocked |

---

## 5. Gateway Controls

**Access control:**

- Virtual keys per tenant
- Budgets and rate limits per tenant

**Security and compliance:**

- Prompt/response logging to tenant-scoped, encrypted store
- PII/secret redaction before cloud egress
- Model allowlist with pinned versions and checksums (supply chain protection)
- Fallback order defined per tenant
- Never fall back from local to cloud unless the tenant allows it

**Audit:**

- Audit events map to AU-2/AU-12
- The gateway itself in the SSP boundary

---

## 6. Mobile

**Current approach:**

- Thin client architecture
- Offline queue syncs to the edge when connected

**Future considerations:**

- On-device models (llama.cpp/MLC, Apple on-device) are optional later
- On-device results must still be checked against the server-side catalog

---

## 7. Sizing (Initial Estimates)

**To be validated:**

- 7-8B model: 16 GB RAM, CPU acceptable for low volume
- 14-32B model: 24-48 GB VRAM GPU for team use

---

## 8. Open Questions

1. **Default local model and evaluation criteria** — Which model(s) should ship as the Enterprise default?
2. **LiteLLM vs Portkey vs Envoy AI Gateway final pick** — Gateway technology selection pending evaluation
3. **Hosting model** — Customer on-prem vs Shields Up managed hardened tenant ([#69](https://github.com/iFocus-Innovations-LLC/GRCToolKit/issues/69))
4. **Relationship to [#68 - LLM proxy](https://github.com/iFocus-Innovations-LLC/GRCToolKit/issues/68)** — Likely: #68 becomes LiteLLM implementation

---

## 9. Implementation Roadmap

See [ROADMAP.md](../ROADMAP.md) for post-production implementation phases and priorities.

---

## Related Documentation

- [ROADMAP.md](../ROADMAP.md) — Development roadmap and priorities
- [BRAND-AND-EDITIONS.md](../BRAND-AND-EDITIONS.md) — Product tiers and commercial model
- [PM-TODO.md](../PM-TODO.md) — Product management backlog
- [Issue #68 - Server-side LLM proxy](https://github.com/iFocus-Innovations-LLC/GRCToolKit/issues/68)
- [Issue #69 - Shields Up Enterprise platform](https://github.com/iFocus-Innovations-LLC/GRCToolKit/issues/69)

---

**Last Updated:** 2026-10-12  
**Version:** 0.1 DRAFT
