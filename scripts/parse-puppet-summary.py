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
    
    report_file = vardir / "state" / "last_run_report.yaml"
    
    # Default finding
    finding = {
        "control": control_id,
        "status": "SKIP",
        "message": "Could not parse Puppet report",
        "evidence": f"Report file not found: {report_file}",
        "puppet_module": module,
        "timestamp": "",
        "grc_audit_mode": "read_only",
    }
    
    # Parse report file
    if not report_file.exists():
        return finding
    
    with report_file.open("r") as f:
        # Puppet reports contain Ruby objects, need full_load
        report = yaml.full_load(f)
    
    # Extract metrics from report
    metrics = report.get("metrics", {})
    
    # Resource metrics
    resources_metrics = metrics.get("resources", {})
    total = resources_metrics.get("total", 0)
    out_of_sync = resources_metrics.get("out_of_sync", 0)
    failed = resources_metrics.get("failed", 0)
    
    # Event metrics
    events_metrics = metrics.get("events", {})
    noop_events = events_metrics.get("noop", 0)
    
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
    
    # Extract out-of-sync resources
    resource_statuses = report.get("resource_statuses", {})
    for resource_name, resource_data in resource_statuses.items():
        if resource_data.get("out_of_sync", False) or resource_data.get("change_count", 0) > 0:
            events_list = resource_data.get("events", [])
            if events_list:
                event_details = []
                for event in events_list:
                    if event.get("status") == "noop":
                        # Extract check name from resource name (e.g. "check_password_auth")
                        resource_short = resource_name.split("/")[-1].replace("]", "")
                        desired = event.get("desired_value", [""])[0] if isinstance(event.get("desired_value"), list) else event.get("desired_value", "")
                        event_details.append(f"{resource_short}")
                if event_details:
                    evidence_parts.append(", ".join(event_details))
    
    evidence = " ".join(evidence_parts)
    
    # Get timestamp from report
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
