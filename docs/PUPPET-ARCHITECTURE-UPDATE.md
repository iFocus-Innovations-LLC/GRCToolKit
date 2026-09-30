# Architecture Diagram Updates - Puppet Audit Integration

## Overview

Updated `docs/OVERVIEW.md` to reflect the experimental Puppet noop audit engine as an optional validation path driven by Ansible.

## Changes Made

### 1. Mermaid Diagram ✅

**Added Node:**
```mermaid
P[Puppet Modules<br/>puppet/modules/<br/><i>experimental</i>]
```

**Added Flows:**
```mermaid
E -.optional.-> P     # Ansible optionally invokes Puppet
P -.noop audit.-> I   # Puppet runs noop checks on targets
P -.OSCAL.-> F        # Results exported as OSCAL
```

**Design Decisions:**
- ✅ Dashed lines (`-.->`) indicate experimental/optional path
- ✅ Italic text `<i>experimental</i>` clearly marks status
- ✅ No new k8s components or sidecars shown
- ✅ Maintains GitHub Mermaid rendering compatibility

### 2. Workflow Documentation ✅

**Added to Step 4:**
> **Experimental:** Ansible playbook can optionally invoke `puppet apply --noop` on targets that already have Puppet/OpenVox installed (SKIP if not found; never installs Puppet). Fetches `last_run_report.yaml`, parses via `parse-puppet-summary.py`, generates PASS/WARN/FAIL findings and OSCAL exports. **No sidecar, DaemonSet, or k8s changes** — pure read-only validation driven by Ansible runner.

**Key messaging:**
- Optional execution model
- SKIP behavior if Puppet not installed
- Never installs Puppet
- No infrastructure changes required
- Ansible-driven (not standalone)

### 3. Capabilities Section ✅

**Added to "OSCAL & automation":**
> **Experimental:** Puppet noop audit engine — Ansible-driven read-only validation using `puppet apply --noop` on targets with Puppet/OpenVox already installed. Parses structured reports (`last_run_report.yaml`) for drift detection. SKIP if Puppet not found (never installs it). No k8s/sidecar changes. See [docs/PUPPET-AUDIT-ENGINE.md](PUPPET-AUDIT-ENGINE.md)

### 4. Technology Stack ✅

**Updated table row:**
| Automation | Ansible (primary); Puppet noop (experimental, Ansible-driven) |

**Emphasis:**
- Ansible remains primary
- Puppet clearly marked experimental
- Clarifies Ansible-driven execution

### 5. Related Documentation ✅

**Added link:**
- [Puppet Audit Engine](PUPPET-AUDIT-ENGINE.md) — experimental read-only validation (Ansible-driven)

## Validation Checklist

- [x] Mermaid syntax valid
- [x] Dashed lines for optional/experimental paths
- [x] No new k8s components shown
- [x] Clear "experimental" labeling
- [x] Documentation links added
- [x] GitHub rendering compatible
- [x] Consistent messaging across sections
- [x] SKIP behavior documented
- [x] No installation claims

## Architectural Principles Maintained

### 1. No Infrastructure Changes
- No sidecar containers
- No DaemonSets
- No Helm chart modifications
- No k8s component additions

### 2. Ansible-Driven Execution
- Puppet never runs standalone
- Ansible playbook orchestrates execution
- Results flow back through Ansible
- Same OSCAL export path as native checks

### 3. Optional/Experimental Status
- Clearly marked in all contexts
- Default behavior unchanged
- SKIP if Puppet not available
- Never auto-installs dependencies

### 4. Visual Clarity
- Dashed lines distinguish from core paths
- Italic styling for experimental components
- Consistent with existing diagram style
- GitHub-compatible Mermaid syntax

## GitHub Rendering Test

The diagram uses standard Mermaid features supported by GitHub:
- ✅ `flowchart LR` (left-to-right flow)
- ✅ Subgraphs for logical grouping
- ✅ Solid arrows (`-->`) for core paths
- ✅ Dashed arrows (`-.->`) for optional paths
- ✅ HTML tags in labels (`<br/>`, `<i>`)
- ✅ No custom themes or plugins

**Expected rendering:** Clean, readable diagram with experimental Puppet path clearly distinguished from core validation flows.

## Summary

Architecture documentation successfully updated to show:
1. **Puppet modules** as experimental component
2. **Optional execution** via Ansible orchestration
3. **Read-only validation** with noop mode
4. **OSCAL export** integration
5. **No infrastructure changes** required

All updates maintain consistency with GRCToolKit's existing documentation style and architectural principles.
