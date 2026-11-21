# 🚀 GRCToolKit Development Roadmap

## Executive Summary

GRCToolKit is an open-source **Community Edition** toolkit for automated NIST validation, OSCAL evidence, and HITL-guarded PQC workflows, building on its existing NIST 800-53 R5 and OSCAL foundation. This roadmap outlines technical enhancements and PQC integration for the public Community Edition.

A commercial Enterprise edition built on this Community core is planned; details are not part of this public roadmap.

### What we are not claiming (today)

- Replacement for enterprise GRC workflow suites (Archer-class IRM, broad risk registers, vendor management)
- FedRAMP-ready by design; no active FedRAMP authorization or alignment claimed
- Fully autonomous remediation (HITL is required by design)
- Complete CSF 2.0 database or multi-tenant SaaS at launch
- NSA Type 1 / High Assurance ECU (HA-ECU) certification, NSA Key Management Infrastructure (KMI), or government pre-deployment approval authority

---

## Current Strengths & Foundation

### ✅ v1.1 OSCAL Integration Features (Confirmed)
- **OSCAL Compliance**: Full NIST 800-53 R5 OSCAL catalog integration
- **AI Compliance Engine**: Automated assessment and control mapping
- **Ansible Automation**: Automated compliance control implementation
- **Auditor Reports**: Automated compliance documentation generation
- **Enterprise Security**: Enhanced security documentation and best practices

### ✅ Production-Ready Deployment Features
- **Containerized**: Docker-based deployment with nginx
- **Kubernetes Ready**: Complete K8s manifests for GCP deployment
- **CI/CD Pipeline**: Automated testing and deployment with GitHub Actions
- **Auto-scaling**: Horizontal Pod Autoscaler for dynamic scaling
- **Security**: Non-root containers, security headers, vulnerability scanning
- **Monitoring**: Health checks, logging, and observability features

### ✅ Technology Stack
- **Frontend**: HTML, Tailwind CSS
- **AI Model**: Gemini 2.0 Flash
- **Automation**: Ansible playbooks
- **Deployment**: Docker, Kubernetes (GCP)
- **CI/CD**: GitHub Actions
- **Standards**: NIST 800-53 R5, OSCAL format

---

## Planned Enhancements (Core Platform)

### 1. Refine AI Prompting
- **Objective**: More detailed prompts for precise responses
- **Features**:
  - Enhanced prompt templates with CSF 2.0 mappings
  - Context-aware scenario analysis
  - Multi-turn conversation support
  - Domain-specific knowledge injection

### 2. Structured Output with JSON Schema
- **Objective**: Consistent, parseable AI responses
- **Features**:
  - JSON schema validation for AI responses
  - Control ID, name, explanation structure
  - CSF 2.0 mapping integration
  - Error handling and fallback mechanisms

### 3. Actual GRC Data Integration
- **Objective**: Database-backed control mapping
- **Features**:
  - Firestore integration for NIST 800-53 data
  - CSF 2.0 database schema
  - Real-time control catalog updates
  - Offline capability with local caching

### 4. User Authentication & Data Persistence
- **Objective**: Multi-user support with data persistence
- **Features**:
  - Firebase Authentication integration
  - Firestore for user queries and reports
  - User preferences and saved scenarios
  - Audit trail for compliance activities

### 5. Advanced UI Features
- **Objective**: Enhanced user experience
- **Features**:
  - Advanced filtering and sorting
  - Control implementation tracking
  - Direct links to NIST documentation
  - Interactive compliance dashboards
  - Real-time collaboration features

### 6. Backend AI Logic
- **Objective**: Sophisticated AI capabilities
- **Features**:
  - Fine-tuned models for GRC scenarios
  - Knowledge graph integration
  - Integration with other GRC tools
  - Custom model training capabilities

### 7. Integration with Other GRC Tools
- **Objective**: Ecosystem connectivity
- **Features**:
  - RESTful APIs for external integrations
  - Webhook support for event notifications
  - Import/export capabilities
  - Third-party tool connectors

---

## PQC Migration Integration Strategy

### Alignment with PQC Migration Framework

GRCToolKit's existing capabilities provide an ideal foundation for PQC migration:

- ✅ **NIST 800-53 Integration**: Foundation for PQC controls (SC-12, SC-13, SC-17, etc.)
- ✅ **OSCAL Compliance Engine**: Extensible for PQC assessment
- ✅ **Ansible Automation**: Can deploy PQC configurations
- ✅ **Report Generation**: Can produce PQC migration documentation
- ✅ **AI Agent**: Can be trained on PQC scenarios

**PQC standards reference:** GRCToolKit tracks published PQC standards (NIST FIPS 203, 204, 205) and PQC migration deadlines (2030, 2035) as compliance data. The toolkit does not simulate Type 1 certification or claim HA-ECU, NSA KMI, or government approval authority.

---

## MVP Development Priorities

### Phase 1: Core PQC Capabilities (Q1 2026)

#### 1.1 PQC Scenario Analysis Module
- **Objective**: Extend AI agent to recognize PQC migration scenarios
- **Features**:
  - PQC-specific prompt templates
  - Gemini model training on PQC scenarios
  - Mapping PQC requirements to NIST 800-53 cryptographic controls
  - Quantum risk keyword detection

#### 1.2 Cryptographic Asset Inventory
- **Objective**: Discover and catalog cryptographic implementations
- **Features**:
  - Automated cryptographic asset discovery
  - Integration with OSCAL catalog structure
  - Asset classification by quantum vulnerability
  - Data shelf-life assessment for prioritization
  - Algorithm type detection (RSA, ECC, DSA, AES, etc.)
  - Pathway completeness fields (transit, at-rest, signing, supply-chain hops)

#### 1.3 PQC Risk Assessment Engine
- **Objective**: Quantum risk scoring and prioritization
- **Features**:
  - Algorithm-based risk scoring (RSA, ECC, DSA = high risk)
  - Data sensitivity and confidentiality assessment
  - System criticality and business impact analysis
  - Timeline to quantum threat evaluation
  - "Harvest now, decrypt later" (HNDL) risk identification
  - Integration with existing AI compliance engine

#### 1.4 PQC Control Mapping
- **Objective**: Map PQC standards to NIST 800-53 controls
- **Features**:
  - NIST FIPS 203, 204, 205 to NIST 800-53 mapping
  - CSF 2.0 integration for PQC-related functions
  - OSCAL-formatted PQC control catalog
  - Control priority and dependency mapping

### Phase 2: Migration Roadmap (Q2 2026)

#### 2.1 Four-Phase Roadmap Implementation
- **Objective**: Structured PQC migration planning
- **Features**:
  - **Phase 1: Preparation**
    - Stakeholder alignment tools
    - Team formation tracking
    - Budget planning
  - **Phase 2: Baseline Understanding**
    - Inventory management
    - Asset prioritization
    - Gap analysis
  - **Phase 3: Planning and Execution**
    - Solution selection guidance
    - Implementation tracking
    - Testing and validation
  - **Phase 4: Monitoring and Evaluation**
    - Validation workflows
    - Continuous monitoring
    - Performance metrics

#### 2.2 Timeline and Milestone Management
- **Objective**: Track PQC migration progress
- **Features**:
  - Progress tracking dashboard
  - Milestone and deadline management
  - Automated deadline alerts
  - Gantt chart visualization

#### 2.3 Automated Progress Reporting
- **Objective**: Executive and compliance reporting
- **Features**:
  - Executive summary reports
  - Compliance status dashboards
  - Risk trend analysis
  - Migration progress metrics
  - Board-ready documentation

### Phase 3: Automation and Intelligence (Q3 2026)

#### 3.1 Ansible Automation for PQC
- **Objective**: Automated PQC deployment
- **Features**:
  - Playbooks for deploying ML-KEM (FIPS 203)
  - Playbooks for deploying ML-DSA (FIPS 204)
  - Playbooks for deploying SLH-DSA (FIPS 205)
  - Hybrid cryptographic approach automation
  - Testing and validation scripts
  - Rollback capabilities

#### 3.2 Vendor Solution Database
- **Objective**: PQC solution catalog and evaluation
- **Features**:
  - Catalog of PQC-ready vendors and solutions
  - Integration points for vendor APIs
  - Cost estimation and ROI analysis
  - Solution comparison tools
  - Vendor certification tracking

#### 3.3 Continuous Quantum Threat Monitoring
- **Objective**: Real-time threat intelligence
- **Features**:
  - Track quantum computing advances
  - Alert on new vulnerabilities
  - Algorithm deprecation notifications
  - Risk assessment updates
  - Threat intelligence feeds

#### 3.4 Cryptographic Agility Assessment
- **Objective**: Evaluate architecture flexibility
- **Features**:
  - Architecture flexibility evaluation
  - Hardcoded dependency identification
  - Agility improvement recommendations
  - Migration complexity scoring
  - Technical debt analysis

### Phase 4: Enterprise Features (Q4 2026)

#### 4.1 Multi-Tenant Support
- **Objective**: Enterprise deployment capabilities
- **Features**:
  - Role-based access control (RBAC)
  - Multi-tenant compliance management
  - Organization-specific playbooks
  - Custom compliance frameworks
  - Data isolation and security

#### 4.2 Advanced Analytics and Dashboards
- **Objective**: Comprehensive compliance insights
- **Features**:
  - Compliance trend analysis
  - Predictive compliance analytics
  - Risk heat maps
  - Custom dashboard creation
  - Real-time monitoring views

#### 4.3 API for Third-Party Integrations
- **Objective**: Ecosystem connectivity
- **Features**:
  - RESTful API for external tools
  - Webhook support
  - GraphQL API option
  - SDK for common languages
  - Integration marketplace

---

## Technical Implementation

### Database Schema Extensions

```sql
-- PQC Assets Table
pqc_assets (
  id, asset_name, asset_type, algorithm_type, 
  quantum_vulnerability, data_shelf_life, 
  business_criticality, migration_priority, 
  discovered_date, last_assessed
)

-- PQC Risks Table
pqc_risks (
  id, asset_id, risk_score, risk_level, 
  algorithm_risk, data_sensitivity, 
  system_criticality, timeline_to_threat, 
  harvest_now_risk, assessment_date
)

-- PQC Milestones Table
pqc_milestones (
  id, roadmap_phase, milestone_name, 
  target_date, actual_date, status, 
  dependencies, progress_percentage
)

-- PQC Vendors Table
pqc_vendors (
  id, vendor_name, solution_name, 
  fips_compliance, integration_type, 
  cost_estimate, roi_analysis, 
  certification_status
)
```

### AI Model Training

- Fine-tune Gemini on PQC-specific scenarios
- Create prompt templates for common PQC questions
- Develop structured JSON schemas for PQC responses
- Train on NIST IR 8547 and related guidance documents
- Build knowledge base of PQC migration patterns

### OSCAL Extensions

- Create PQC-specific OSCAL catalog
- Map FIPS 203/204/205 to OSCAL control format
- Extend existing NIST 800-53 catalog with PQC annotations
- PQC assessment results in OSCAL format
- PQC migration plans in OSCAL structure

### Ansible Playbook Structure

```
ansible/playbooks/pqc/
├── inventory.yml          # Discover cryptographic assets
├── assess.yml            # Quantum risk assessment
├── deploy-mlkem.yml      # Deploy ML-KEM (FIPS 203)
├── deploy-mldsa.yml      # Deploy ML-DSA (FIPS 204)
├── deploy-slhdsa.yml     # Deploy SLH-DSA (FIPS 205)
├── hybrid-crypto.yml     # Deploy hybrid approaches
└── validate.yml          # Test PQC implementations
```

**Planned (Windows track):** `ansible/playbooks/windows/` — see [Windows OS Ansible validation](#windows-os-ansible-validation-chocolatey).

---

## Windows OS Ansible validation (Chocolatey)

**Goal:** Extend automated NIST control validation beyond Linux/localhost to **Microsoft Windows** targets, using [Chocolatey](https://chocolatey.org/) to simplify lab/QA bootstrap.

**Honesty:** Linux `grc-audit` probes and systemd/auditd-oriented AC/AU/SC playbooks **do not** apply to Windows. Windows is a **parallel** track with its own inventory group and playbook tree.

### Bootstrap (Chocolatey)

- Use **Chocolatey Open Source** for package-manager simplicity on Windows lab and QA hosts ([chocolatey.org](https://chocolatey.org/))
- Bootstrap installs only **approved** prerequisites (e.g. OpenSSH / WinRM-related tooling as needed for Ansible connectivity)
- Any Chocolatey **install or upgrade** on a target requires **HITL** approval and AU-2 audit trail — same rule as Linux remediations

### Inventory

- Add group **`windows_targets`** with `ansible_connection: winrm` (or documented SSH-on-Windows alternative), `ansible_user`, and connection vars
- Real hostnames, IPs, and credentials stay in a **private** inventory — never commit secrets to GRCToolKit git
- Local MVP inventory ([ansible/playbooks/inventory.yml](../ansible/playbooks/inventory.yml)) remains Linux/macOS localhost for demos

### Future playbook tree

```
ansible/playbooks/windows/
├── bootstrap.yml       # Ensure Chocolatey present; HITL-gated package installs
├── validate-ac.yml     # Read-only access-control oriented checks → JSON evidence
├── validate-au.yml     # Read-only audit/logging oriented checks → JSON evidence
└── (map probes → NIST 800-53 + OSCAL export patterns)
```

### Out of scope (this track)

- Replacing Intune / MECM
- Chocolatey for Business Central Management as a product dependency
- Unattended Chocolatey upgrades on production
- Claiming full CIS / Windows Benchmark coverage in MVP

---

## GenAI model and agent market research

**Objective:** Stay informed on GenAI development without expanding MVP token spend.

- Monitor commercial and open models/agents beyond Gemini for cost efficiency, HITL fitness, and hosting constraints
- Do **not** add a second LLM vendor to product or CI until research + budget policy approve it
- Optional outcomes: alternate runtime adapters; optional multi-model PR review (post-MVP)

**OSS security framing:** Align toward [CISA OSS Security Principles and Practices](https://www.cisa.gov/resources-tools/resources/open-source-software-security-principles-and-practices) — see [SECURITY.md](SECURITY.md#cisa-open-source-software-security-alignment).

---

## Conclusion

GRCToolKit is positioned as open-source **infrastructure for automated NIST validation, OSCAL evidence, and HITL-guarded PQC workflows**. Existing OSCAL integration, AI-assisted control mapping, and Ansible automation provide a foundation for that evidence path.

---

**Last Updated**: 2026-11-21  
**Version**: 2.7  
**Status**: Active Development  
**Agent framework reference**: [Google ADK](https://adk.dev/)  
**Windows bootstrap reference**: [Chocolatey](https://chocolatey.org/)  
**OSS security reference**: [CISA OSS Security Principles and Practices](https://www.cisa.gov/resources-tools/resources/open-source-software-security-principles-and-practices)
