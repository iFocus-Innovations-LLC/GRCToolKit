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
    
    # Parse report file using Ruby (since Puppet YAML contains Ruby objects)
    if not report_file.exists():
        return finding
    
    # Use Ruby to parse Puppet YAML and extract metrics as JSON
    ruby_script = """
require 'yaml'
require 'json'
report = YAML.unsafe_load_file(ARGV[0])
metrics = {}
['resources', 'events'].each do |category|
  if report.metrics && report.metrics[category]
    metrics[category] = report.metrics[category].values.to_h
  end
end
# Extract resource statuses
statuses = {}
if report.resource_statuses
  report.resource_statuses.each do |name, status|
    if status.out_of_sync || status.change_count > 0
      statuses[name] = {
        'out_of_sync' => status.out_of_sync,
        'change_count' => status.change_count,
        'events' => status.events.map { |e| {'status' => e.status} }
      }
    end
  end
end
puts JSON.generate({
  'metrics' => metrics,
  'resource_statuses' => statuses,
  'time' => report.time.to_s
})
"""
    
    try:
        result = subprocess.run(
            ['ruby', '-e', ruby_script, str(report_file)],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode != 0:
            finding["evidence"] = f"Ruby script failed (exit {result.returncode}): {result.stderr[:500]}"
            return finding
        
        import json
        data = json.loads(result.stdout)
    except subprocess.TimeoutExpired:
        finding["evidence"] = "Ruby script timed out after 5 seconds"
        return finding
    except FileNotFoundError:
        finding["evidence"] = "Ruby not found in PATH"
        return finding
    except json.JSONDecodeError as e:
        finding["evidence"] = f"Failed to parse Ruby JSON output: {e}. Output: {result.stdout[:500]}"
        return finding
    except Exception as e:
        finding["evidence"] = f"Failed to parse report: {type(e).__name__}: {e}"
        return finding
    
    # Extract metrics
    metrics = data.get("metrics", {})
    resources_metrics = metrics.get("resources", {})
    events_metrics = metrics.get("events", {})
    
    total = resources_metrics.get("total", 0)
    out_of_sync = resources_metrics.get("out_of_sync", 0)
    failed = resources_metrics.get("failed", 0)
    noop_events = events_metrics.get("noop", 0)
    
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
    
    resource_statuses = data.get("resource_statuses", {})
    failing_checks = []
    for resource_name in resource_statuses.keys():
        # Extract check name from resource (e.g. "Exec[check_password_auth]" -> "check_password_auth")
        resource_short = resource_name.split("[")[-1].replace("]", "")
        failing_checks.append(resource_short)
    
    if failing_checks:
        evidence_parts.append("Failing checks: " + ", ".join(failing_checks))
    
    evidence = " ".join(evidence_parts)
    
    finding.update({
        "status": status,
        "message": message,
        "evidence": evidence[:1000],
        "timestamp": str(data.get("time", "")),
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
