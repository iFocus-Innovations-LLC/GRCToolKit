#!/usr/bin/env python3
"""
Puppet finding to OSCAL converter for GRCToolKit.
Converts Puppet noop findings to OSCAL assessment results format.

Usage:
  cat puppet-finding.json | python3 scripts/puppet-to-oscal.py > oscal-result.json
  python3 scripts/puppet-to-oscal.py puppet-finding.json oscal-result.json
"""
import json
import sys
from datetime import datetime
from pathlib import Path


def puppet_finding_to_oscal(finding: dict) -> dict:
    """Convert Puppet finding to OSCAL assessment result format."""
    # Map Puppet status to OSCAL status
    status_map = {
        "PASS": "pass",
        "WARN": "not-satisfied", 
        "FAIL": "fail",
        "SKIP": "not-applicable",
    }
    
    oscal_status = status_map.get(finding.get("status", "SKIP"), "not-applicable")
    
    # Extract timestamp
    timestamp = finding.get("timestamp", datetime.utcnow().isoformat() + "Z")
    
    # Build OSCAL observation
    observation = {
        "uuid": f"puppet-{finding.get('puppet_module', 'unknown')}-{timestamp}",
        "description": finding.get("message", "Puppet validation finding"),
        "methods": ["TEST-AUTOMATED"],
        "types": ["control-objective"],
        "collected": timestamp,
        "remarks": finding.get("evidence", ""),
    }
    
    # Build OSCAL finding
    oscal_finding = {
        "uuid": f"finding-{finding.get('control', 'UNKNOWN')}-{timestamp}",
        "title": f"{finding.get('control', 'UNKNOWN')}: {finding.get('message', '')}",
        "description": finding.get("message", ""),
        "related-observations": [observation["uuid"]],
        "target": {
            "type": "component",
            "title": finding.get("puppet_module", "unknown"),
            "description": f"Puppet module: {finding.get('puppet_module', 'unknown')}",
        },
    }
    
    # Build OSCAL result
    oscal_result = {
        "uuid": f"result-{timestamp}",
        "title": "Puppet Audit Engine Validation",
        "description": "Automated NIST 800-53 validation using Puppet noop mode",
        "start": timestamp,
        "end": timestamp,
        "reviewed-controls": {
            "control-selections": [
                {
                    "include-controls": [
                        {"control-id": finding.get("control", "UNKNOWN")}
                    ]
                }
            ]
        },
        "observations": [observation],
        "findings": [oscal_finding],
    }
    
    # Wrap in OSCAL assessment-results structure
    oscal_doc = {
        "assessment-results": {
            "uuid": f"assessment-{timestamp}",
            "metadata": {
                "title": "GRCToolKit Puppet Audit",
                "last-modified": timestamp,
                "version": "0.1-poc",
                "oscal-version": "1.0.4",
            },
            "results": [oscal_result],
        }
    }
    
    return oscal_doc


def main():
    if len(sys.argv) == 1:
        # Read from stdin
        finding = json.load(sys.stdin)
        oscal = puppet_finding_to_oscal(finding)
        print(json.dumps(oscal, indent=2))
    elif len(sys.argv) == 3:
        # Read from file, write to file
        input_path = Path(sys.argv[1])
        output_path = Path(sys.argv[2])
        
        with input_path.open("r") as f:
            finding = json.load(f)
        
        oscal = puppet_finding_to_oscal(finding)
        
        with output_path.open("w") as f:
            json.dump(oscal, f, indent=2)
        
        print(f"✅ OSCAL result written to {output_path}")
    else:
        print("Usage:", file=sys.stderr)
        print("  cat puppet-finding.json | python3 scripts/puppet-to-oscal.py", file=sys.stderr)
        print("  python3 scripts/puppet-to-oscal.py input.json output.json", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
