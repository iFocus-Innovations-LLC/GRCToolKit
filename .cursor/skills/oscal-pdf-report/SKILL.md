---
name: oscal-pdf-report
description: >-
  Generate downloadable PDF OSCAL compliance reports from GRCToolKit validation
  results. JSON is stored in /tmp/grc-oscal-reports; PDF served via local runner
  API. Use when implementing or debugging OSCAL report download, PDF export, or
  local MVP demo reporting.
---
# OSCAL PDF Report (local MVP)

## Purpose

Convert GRCToolKit **OSCAL JSON** assessment output into a **human-readable PDF** for demo and QA. Files are written under **`/tmp/grc-oscal-reports/`** on the local Mac (not committed to git). For production Ansible handoff (manual CLI, change window), see **`docs/ANSIBLE-AUDIT-OPERATIONS.md`**.

## Architecture

```text
Validate Controls (browser)
  → POST http://127.0.0.1:8081/api/reports/oscal-pdf
  → scripts/oscal_pdf.py (fpdf2)
  → /tmp/grc-oscal-reports/oscal-assessment-{id}.json
  → /tmp/grc-oscal-reports/oscal-assessment-{id}.pdf
  → GET /api/reports/download/{filename}
  → browser downloads PDF
```

## Prerequisites

```bash
pip3 install -r scripts/requirements-local-demo.txt   # fpdf2 (or let run-local.sh create .venv-local-demo)
./scripts/run-local.sh                                 # starts UI :8080 + API :8081
```

## API

| Method | Path | Body | Response |
|--------|------|------|----------|
| POST | `/api/reports/oscal-pdf` | `{ "complianceReport": {...}, "validationResults": {...} }` | `{ reportId, pdfPath, jsonPath, downloadUrl }` |
| GET | `/api/reports/download/{filename}` | — | PDF bytes (`application/pdf`) |

## Key files

- `scripts/oscal_pdf.py` — JSON → PDF + `/tmp` storage
- `scripts/ansible-runner-api.py` — local API (Ansible + reports)
- `grctoolkit.html` — `downloadOscalReportPdf()` client
- `ai-agent/grc-compliance-engine.js` — builds `complianceReport` OSCAL payload

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Button does nothing | Hard-refresh; ensure `run-local.sh` regenerated `local-index.html` |
| `fpdf2 is required` | `pip3 install -r scripts/requirements-local-demo.txt` |
| Port 8081 in use | Restart `./scripts/run-local.sh` (frees stale runner) |
| Empty findings | Run **Validate Controls** first so `complianceReport` is populated |

## Security (local demo)

- API binds **127.0.0.1** only
- Download filenames must match `oscal-assessment-*.pdf` under `/tmp/grc-oscal-reports`
- Do not expose runner API on LAN or production without auth
