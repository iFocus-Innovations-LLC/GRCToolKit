#!/usr/bin/env python3
"""
Parse Puppet last_run_summary.yaml and last_run_report.yaml to determine
compliance status and extract evidence.

Usage:
  python3 parse-puppet-summary.py <vardir> <control_id> <module>

Outputs JSON finding to stdout.
"""
import json
import sys
from pathlib import Path
import yaml


def parse_puppet_summary(vardir: Path, control_id: str, module: str) -> dict:
    """Parse Puppet structured output and return GRCToolKit finding."""
    
    summary_file = vardir / "last_run_summary.yaml"
    report_file = vardir / "last_run_report.yaml"
    
    # Default finding
    finding = {
        "control": control_id,
        "status": "SKIP",
        "message": "Could not parse Puppet summary",
        "evidence": f"Summary file not found: {summary_file}",
        "puppet_module": module,
        "timestamp": "",
        "grc_audit_mode": "read_only",
    }
    
    # Parse summary file (resource counts)
    if not summary_file.exists():
        return finding
    
    with summary_file.open("r") as f:
        summary = yaml.safe_load(f)
    
    # Extract resource counts
    resources = summary.get("resources", {})
    events = summary.get("events", {})
    
    out_of_sync = resources.get("out_of_sync", 0)
    failed = resources.get("failed", 0)
    total = resources.get("total", 0)
    noop_events = events.get("noop", 0)
    
    # Determine status based on counts
    # FAIL: any failures
    # WARN: resources out of sync or noop events (drift detected)
    # PASS: no failures, no drift
    if failed > 0:
        status = "FAIL"
        message = f"Puppet validation failed: {failed} resource(s) failed"
    elif out_of_sync > 0 or noop_events > 0:
        status = "WARN"
        message = f"SSH configuration drift detected: {out_of_sync} resource(s) out of sync"
    else:
        status = "PASS"
        message = "All SSH hardening settings in desired state (no drift detected)"
    
    # Extract evidence from report (which resources were out of sync)
    evidence_parts = [
        f"Puppet noop run: {total} resources checked, {out_of_sync} out of sync, {failed} failed."
    ]
    
    if report_file.exists():
        with report_file.open("r") as f:
            report = yaml.safe_load(f)
        
        # Extract out-of-sync resources
        resource_statuses = report.get("resource_statuses", {})
        for resource_name, resource_data in resource_statuses.items():
            if resource_data.get("out_of_sync", False) or resource_data.get("change_count", 0) > 0:
                events_list = resource_data.get("events", [])
                if events_list:
                    event_details = []
                    for event in events_list:
                        if event.get("status") == "noop":
                            prop = event.get("property", "unknown")
                            desired = event.get("desired_value", "")
                            previous = event.get("previous_value", "")
                            event_details.append(
                                f"{prop}: was {previous}, should be {desired}"
                            )
                    if event_details:
                        evidence_parts.append(
                            f"{resource_name}: {'; '.join(event_details)}"
                        )
    
    evidence = " ".join(evidence_parts)
    
    # Get timestamp from report
    timestamp = ""
    if report_file.exists():
        with report_file.open("r") as f:
            report = yaml.safe_load(f)
            timestamp = report.get("time", "")
    
    finding.update({
        "status": status,
        "message": message,
        "evidence": evidence[:1000],  # Truncate to 1000 chars
        "timestamp": str(timestamp) if timestamp else "",
    })
    
    return finding


def main():
    if len(sys.argv) != 4:
        print("Usage: parse-puppet-summary.py <vardir> <control_id> <module>", file=sys.stderr)
        sys.exit(1)
    
    vardir = Path(sys.argv[1])
    control_id = sys.argv[2]
    module = sys.argv[3]
    
    finding = parse_puppet_summary(vardir, control_id, module)
    print(json.dumps(finding, indent=2))


if __name__ == "__main__":
    main()
