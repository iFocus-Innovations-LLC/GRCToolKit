#!/usr/bin/env python3
"""Convert OSCAL JSON assessment data to a human-readable PDF (local MVP demo)."""
from __future__ import annotations

import json
import re
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

REPORT_DIR = Path("/tmp/grc-oscal-reports")
SUDO_PATTERN = re.compile(
    r"BECOME|sudo password|Missing sudo|permission denied|Authentication failure|Incorrect sudo",
    re.I,
)
MANUAL_OPS_DOC = "docs/ANSIBLE-AUDIT-OPERATIONS.md"


def _manual_validation_steps(playbook: str) -> list[str]:
    return [
        f"Review playbook: ansible/playbooks/{playbook}.yml",
        "Schedule ITIL change window; obtain SysAdmin approval",
        f"Dry-run: ansible-playbook -i inventory.yml {playbook}.yml --check --diff --limit <target_host>",
        f"Execute: ansible-playbook -i inventory.yml {playbook}.yml --limit <target_host> --ask-become-pass",
        "Attach stdout and OSCAL assessment results to change ticket",
    ]


def _needs_manual_validation(
    compliance_report: dict,
    validation_results: dict | None,
) -> tuple[bool, list[str]]:
    """Return whether manual validation is required and affected playbook stems."""
    manual_from_findings = any(
        f.get("status") == "MANUAL_REQUIRED"
        for f in _extract_findings(compliance_report)
    )
    playbooks: set[str] = set()
    if validation_results:
        for pb in validation_results.get("playbookResults") or []:
            combined = "\n".join(
                part for part in (pb.get("output"), pb.get("stderr")) if part
            )
            findings = pb.get("findings") or []
            if any(f.get("status") == "MANUAL_REQUIRED" for f in findings) or SUDO_PATTERN.search(
                combined
            ):
                playbooks.add(str(pb.get("playbook") or "unknown"))
    manual_required = manual_from_findings or bool(playbooks)
    return manual_required, sorted(playbooks) if playbooks else (["unknown"] if manual_required else [])


def _safe_text(value: Any, limit: int = 2000) -> str:
    text = str(value or "").replace("\r", "")
    text = text.replace("—", "-").replace("–", "-").replace(""", '"').replace(""", '"')
    text = re.sub(r"[^\x09\x0a\x0d\x20-\x7e]", "?", text)
    if len(text) > limit:
        return text[: limit - 3] + "..."
    return text


def _extract_findings(compliance_report: dict) -> list[dict]:
    findings: list[dict] = []
    root = compliance_report.get("assessment-results") or compliance_report
    for result in root.get("results") or []:
        for item in result.get("findings") or []:
            props = {p.get("name"): p.get("value") for p in item.get("props") or []}
            findings.append(
                {
                    "control": props.get("control-id", "N/A"),
                    "status": props.get("status", "UNKNOWN"),
                    "title": item.get("title", ""),
                    "description": item.get("description", ""),
                }
            )
    return findings


def generate_oscal_report_files(
    compliance_report: dict,
    validation_results: dict | None = None,
    report_dir: Path | None = None,
) -> dict[str, str]:
    """
    Write OSCAL JSON + PDF to report_dir (default /tmp/grc-oscal-reports).
    Returns paths and report id.
    """
    try:
        from fpdf import FPDF
    except ImportError as exc:
        raise RuntimeError(
            "fpdf2 is required for PDF reports. Install: pip3 install -r scripts/requirements-local-demo.txt"
        ) from exc

    out_dir = (report_dir or REPORT_DIR).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    report_id = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:8]
    json_path = out_dir / f"oscal-assessment-{report_id}.json"
    pdf_path = out_dir / f"oscal-assessment-{report_id}.pdf"

    payload = {
        "complianceReport": compliance_report,
        "validationResults": validation_results,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
    }
    json_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    root = compliance_report.get("assessment-results") or compliance_report
    meta = root.get("metadata") or {}
    title = meta.get("title") or "GRC Compliance Assessment Results"
    oscal_version = meta.get("oscal-version") or "1.0.0"

    pdf = FPDF()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()
    line_w = pdf.epw

    pdf.set_font("Helvetica", "B", 16)
    pdf.cell(0, 10, _safe_text(title, 120), ln=True)
    pdf.set_font("Helvetica", "", 10)
    pdf.cell(0, 6, f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S %Z')}", ln=True)
    pdf.cell(0, 6, f"OSCAL version: {oscal_version}", ln=True)
    pdf.ln(4)

    if validation_results:
        pdf.set_font("Helvetica", "B", 12)
        pdf.cell(0, 8, "Validation Summary", ln=True)
        pdf.set_font("Helvetica", "", 10)
        pdf.cell(0, 6, f"Overall status: {_safe_text(validation_results.get('overallStatus', 'n/a'))}", ln=True)
        pdf.cell(0, 6, f"Target hosts: {_safe_text(', '.join(validation_results.get('targetHosts') or []))}", ln=True)
        pdf.cell(0, 6, f"Playbooks run: {len(validation_results.get('playbookResults') or [])}", ln=True)
        pdf.ln(3)

        for pb in validation_results.get("playbookResults") or []:
            pdf.set_font("Helvetica", "B", 11)
            live = "LIVE" if pb.get("live") else "SIMULATED"
            pdf.cell(0, 7, f"Playbook: {_safe_text(pb.get('playbook', ''))} [{live}]", ln=True)
            pdf.set_font("Helvetica", "", 9)
            pdf.multi_cell(line_w, 5, _safe_text(pb.get("output") or pb.get("stderr") or "", 1500))
            pdf.ln(2)

    manual_required, manual_playbooks = _needs_manual_validation(
        compliance_report, validation_results
    )
    if manual_required:
        pdf.set_font("Helvetica", "B", 12)
        pdf.cell(0, 8, "Manual Validation Required", ln=True)
        pdf.set_font("Helvetica", "", 10)
        pdf.multi_cell(
            line_w,
            5,
            _safe_text(
                "Automated validation could not obtain root/sudo via the browser runner. "
                "Complete the manual CLI handoff below per "
                f"{MANUAL_OPS_DOC}."
            ),
        )
        pdf.ln(2)
        for playbook in manual_playbooks:
            pdf.set_font("Helvetica", "B", 10)
            pdf.cell(0, 6, f"Playbook: {_safe_text(playbook)}", ln=True)
            pdf.set_font("Helvetica", "", 9)
            for step in _manual_validation_steps(playbook):
                pdf.multi_cell(line_w, 5, f"- {_safe_text(step)}")
            pdf.ln(1)
        pdf.ln(2)

    findings = _extract_findings(compliance_report)
    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(0, 8, "OSCAL Findings", ln=True)
    pdf.set_font("Helvetica", "", 10)
    if not findings:
        pdf.multi_cell(line_w, 5, "No findings recorded in OSCAL payload.")
    else:
        for f in findings:
            pdf.set_font("Helvetica", "B", 10)
            manual_prefix = "[MANUAL] " if f.get("status") == "MANUAL_REQUIRED" else ""
            pdf.cell(
                0,
                6,
                f"{manual_prefix}{_safe_text(f['control'])} - {_safe_text(f['status'])}",
                ln=True,
            )
            pdf.set_font("Helvetica", "", 9)
            pdf.multi_cell(line_w, 5, _safe_text(f["title"], 500))
            if f.get("description"):
                pdf.multi_cell(line_w, 5, _safe_text(f["description"], 1200))
            pdf.ln(2)

    pdf.set_font("Helvetica", "I", 8)
    pdf.ln(4)
    pdf.multi_cell(
        line_w,
        4,
        f"JSON source: {json_path} | Machine-readable OSCAL JSON stored alongside this PDF.",
    )
    pdf.output(str(pdf_path))

    return {
        "reportId": report_id,
        "jsonPath": str(json_path),
        "pdfPath": str(pdf_path),
        "pdfFilename": pdf_path.name,
    }
