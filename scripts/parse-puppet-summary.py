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
    
    import subprocess
    import re
    
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
    
    if not report_file.exists():
        return finding
    
    # Extract metrics using text processing (avoid Ruby class instantiation issues)
    try:
        with report_file.open("r") as f:
            content = f.read()
        
        # Extract resource metrics using regex
        total = 0
        out_of_sync = 0
        failed = 0
        noop_events = 0
        
        # Look for metrics section in YAML
        resources_match = re.search(r'resources:\s+!ruby/object:Puppet::Util::Metric.*?values:\s+(.*?)(?=\w+:|$)', content, re.DOTALL)
        if resources_match:
            values_text = resources_match.group(1)
            total_match = re.search(r'total:\s+(\d+)', values_text)
            out_of_sync_match = re.search(r'out_of_sync:\s+(\d+)', values_text)
            failed_match = re.search(r'failed:\s+(\d+)', values_text)
            if total_match:
                total = int(total_match.group(1))
            if out_of_sync_match:
                out_of_sync = int(out_of_sync_match.group(1))
            if failed_match:
                failed = int(failed_match.group(1))
        
        events_match = re.search(r'events:\s+!ruby/object:Puppet::Util::Metric.*?values:\s+(.*?)(?=\w+:|$)', content, re.DOTALL)
        if events_match:
            values_text = events_match.group(1)
            noop_match = re.search(r'noop:\s+(\d+)', values_text)
            if noop_match:
                noop_events = int(noop_match.group(1))
        
        # Extract out-of-sync resource names
        failing_checks = []
        resource_statuses_match = re.search(r'resource_statuses:(.*)', content, re.DOTALL)
        if resource_statuses_match:
            statuses_text = resource_statuses_match.group(1)
            # Find Exec[check_*] resources that are out of sync
            for match in re.finditer(r'Exec\[([^\]]+)\]:.*?out_of_sync:\s*true', statuses_text, re.DOTALL):
                check_name = match.group(1)
                if 'check_' in check_name:
                    failing_checks.append(check_name)
        
    except Exception as e:
        finding["evidence"] = f"Failed to parse report text: {type(e).__name__}: {e}"
        return finding
    
    # Determine status based on counts
    if failed > 0:
        status = "FAIL"
        message = f"Puppet validation failed: {failed} resource(s) failed"
    elif out_of_sync > 0 or noop_events > 0:
        status = "WARN"
        message = f"SSH configuration drift detected: {out_of_sync} resource(s) out of sync"
    else:
        status = "PASS"
        message = "All SSH hardening settings in desired state (no drift detected)"
    
    # Extract evidence
    evidence_parts = [
        f"Puppet noop run: {total} resources checked, {out_of_sync} out of sync, {failed} failed."
    ]
    
    if failing_checks:
        evidence_parts.append("Failing checks: " + ", ".join(failing_checks))
    
    evidence = " ".join(evidence_parts)
    
    finding.update({
        "status": status,
        "message": message,
        "evidence": evidence[:1000],
        "timestamp": "",  # Extract timestamp if needed
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
