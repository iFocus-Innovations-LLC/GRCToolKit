# 🚀 GRCToolKit Development Roadmap

## Executive Summary

GRCToolKit is evolving into a comprehensive Post-Quantum Cryptography (PQC) migration management platform, building on its existing NIST 800-53 R5 and OSCAL foundation. This roadmap outlines the strategic enhancements and PQC integration strategy to position GRCToolKit as the leading platform for automated PQC migration compliance.

**Market thesis:** Most GRC applications optimize for governance workflows and attestations. GRCToolKit optimizes for **automated control validation**, **OSCAL-native evidence**, and **HITL-guarded AI** in environments engineers actually run — cloud, Kubernetes, and (post-production) Physical AI / robotics. See [Market positioning](#market-positioning-grctoolkit-vs-traditional-grc) and the [Executive Overview](OVERVIEW.md#why-grctoolkit-vs-traditional-grc).

---

## Market positioning: GRCToolKit vs traditional GRC

### Where GRCToolKit differentiates

| Dimension | Traditional GRC suite | GRCToolKit direction |
|-----------|----------------------|----------------------|
| Primary user | GRC analyst, audit PM | Security engineer, auditor, platform team |
| Control evidence | Documents, tickets, manual attestation | OSCAL artifacts + Ansible probe output |
| NIST 800-53 | Reference libraries, manual mapping | AI scenario mapping + catalog integration |
| Automation | Limited or proprietary | Open Ansible playbooks (AC/AU/SC, PQC, OWASP LLM) |
| AI role | Policy chat, generic assistants | Structured control recommendations with **HITL** gates |
| PQC migration | Emerging slide-deck topic | Playbooks, inventory, FIPS 203/204/205 roadmap |
| Deployment model | Vendor-hosted SaaS | Open source; self-hosted Docker/GKE/Helm |
| Physical AI / robots | Out of scope | **Shields Up** (Phase 4+): RSF, OWASP LLM, routine read-only scans |

### What we are not claiming (today)

- Replacement for enterprise GRC workflow suites (Archer-class IRM, broad risk registers, vendor management)
- FedRAMP- or IL-authorized managed service
- Fully autonomous remediation (HITL is required by design)
- Complete CSF 2.0 database or multi-tenant SaaS at launch

### Strategic narrative (for partners and evaluators)

> Legacy GRC tools excel at governance workflows. **GRCToolKit.ai** is open source infrastructure for **automated NIST 800-53 validation**, **OSCAL evidence**, and **HITL-guarded AI** — with a roadmap into PQC and robotic / Physical AI security. We give engineers and auditors something they can **run, inspect, and extend**.

### Roadmap alignment

| Phase | Focus | Market message |
|-------|--------|----------------|
| **Now — production gate** | OSCAL, Ansible, HITL, PQC core, GCP deploy | Prove the automatable GRC stack |
| **Phase 4+ — Shields Up** | Robotics, OWASP LLM, RSF | Extend validation to Physical AI |
| **Future — sim / ovrtx** | Synthetic lab, sensor evidence (post v0.1) | Demo and train without production robot risk |

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

#### 1.3 PQC Risk Assessment Engine
- **Objective**: Quantum risk scoring and prioritization
- **Features**:
  - Algorithm-based risk scoring (RSA, ECC, DSA = high risk)
  - Data sensitivity and confidentiality assessment
  - System criticality and business impact analysis
  - Timeline to quantum threat evaluation
  - "Harvest now, decrypt later" risk identification
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
  - 2030 deprecation deadline tracking
  - 2035 disallowance deadline tracking
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

#### 4.4 Mobile Application for Executives
- **Objective**: Executive access and reporting
- **Features**:
  - iOS and Android apps
  - Executive dashboards
  - Push notifications for critical issues
  - Offline report viewing
  - Mobile-optimized workflows

#### 4.5 GRCToolKit Enterprise (commercial)

- **Objective**: Commercial destination after Community adoption — support, training, agentic token economics
- **Brand model**: Module names (Shields Up, Sentinel/HITL) **build up to Enterprise**; see [BRAND-AND-EDITIONS.md](BRAND-AND-EDITIONS.md)
- **Tiers**: Bronze, Silver, Gold, Platinum (support + training; pricing TBD)
- **Features** (roadmap):
  - Enterprise support portal and SLAs
  - Training catalog (HITL, OSCAL auditor, Shields Up operator)
  - **Usage metering API** for agentic token workflows (BYOK + bundled pools)
  - Optional hosted agent runtime (future)
  - Shields Up fleet architecture assist (Gold+)

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

---

## Market Positioning

### Target Market Segments

1. **Federal Government**
   - FISMA compliance
   - Classified systems
   - NIST SP 800-53 requirements

2. **Financial Services**
   - Long-term data retention
   - Regulatory requirements (SOX, PCI-DSS)
   - Customer data protection

3. **Healthcare**
   - HIPAA compliance
   - Patient data protection
   - PHI security requirements

4. **Critical Infrastructure**
   - NERC CIP compliance
   - ICS/SCADA security
   - Operational technology protection

5. **Enterprise**
   - Fortune 500 companies
   - Sensitive IP protection
   - Customer data security

### Pricing and editions

Commercial model: **open core + GRCToolKit Enterprise**. Community Edition remains MIT with BYOK for AI.

Full tier definitions, brand ladder, and token economics: **[BRAND-AND-EDITIONS.md](BRAND-AND-EDITIONS.md)** and **[PM-TODO.md](PM-TODO.md)** (P2–P4).

| Edition | Purpose |
|---------|---------|
| **Community** | OSS adoption — self-host, contribute, BYOK |
| **Enterprise Bronze** | Entry support + onboarding |
| **Enterprise Silver** | Business-hours support + analyst training |
| **Enterprise Gold** | Priority support + HITL/OSCAL workshops + Shields Up assist |
| **Enterprise Platinum** | Custom SLA + gov-style engagement + large token pools |
| **Government** | Custom procurement (GSA Schedule, on-premise options) — pricing TBD |

**Agentic pricing:** Token-metered workflows (scenario analysis, AI review, Shields Up triage). Community = BYOK only; Enterprise = optional bundled pools + overage policy. Dollar amounts **TBD** pending pilot customers and quarterly macro review (see PM-TODO P3/P4).

*Legacy placeholder tiers (Starter $5k / Professional $25k / Enterprise $100k) are retired — use Bronze–Platinum model above.*

### Go-to-Market Strategy

1. **NIST Conference Presentation**
   - Establish thought leadership
   - Demonstrate PQC capabilities
   - Generate leads

2. **Free PQC Readiness Assessment**
   - Lead generation tool
   - Market education
   - Brand awareness

3. **Partnership with PQC Vendors**
   - Co-marketing opportunities
   - Solution integration
   - Referral programs

4. **Government Contracting**
   - GSA Schedule
   - SEWP contracts
   - Federal procurement

5. **Industry Associations**
   - ISACA membership
   - (ISC)² partnerships
   - Cloud Security Alliance

---

## Value Propositions

### For CISOs and Security Leaders
- Automated PQC Readiness Assessment
- Risk Quantification with clear scoring
- Compliance Tracking for NIST PQC standards
- Executive Reporting with board-ready documentation

### For Compliance Officers
- NIST Alignment (800-53 R5, FIPS 203/204/205)
- Audit-Ready Documentation
- Timeline Management (2030/2035 deadlines)
- Regulatory Intelligence monitoring

### For IT Directors and Architects
- Asset Discovery across infrastructure
- Migration Planning with structured roadmap
- Ansible Automation for deployment
- Vendor Evaluation and comparison

### For Risk Managers
- "Harvest Now, Decrypt Later" Protection
- Data Shelf-Life Analysis
- Business Impact Assessment
- Continuous Monitoring with threat intelligence

---

## Competitive Differentiation

- ✅ Only GRC platform with integrated PQC migration capabilities
- ✅ AI-powered automation reduces manual effort by 80%
- ✅ OSCAL-compliant for government and enterprise adoption
- ✅ Ansible automation for hands-free deployment
- ✅ Production-ready with Kubernetes scalability
- ✅ Comprehensive four-phase migration roadmap
- ✅ Real-time quantum threat monitoring

---

## Demo Scenarios for NIST Conference

### Scenario 1: Financial Services Organization
- **Context**: 20-year data retention requirements
- **Focus**: Long-term cryptographic protection
- **Controls**: SC-12, SC-13, SC-17, SC-28

### Scenario 2: Healthcare Provider
- **Context**: HIPAA compliance obligations
- **Focus**: Patient data protection
- **Controls**: SC-12, SC-13, SC-28, AC-3

### Scenario 3: Federal Agency
- **Context**: Classified information systems
- **Focus**: FISMA compliance
- **Controls**: SC-12, SC-13, SC-17, SC-28, AU-2

### Scenario 4: Critical Infrastructure Operator
- **Context**: OT/ICS environments
- **Focus**: Operational technology security
- **Controls**: SC-7, SC-12, SC-13, SC-17

---

## Success Metrics

### Technical Metrics
- AI response accuracy: >90%
- Ansible playbook success rate: >95%
- OSCAL report generation time: <30 seconds
- System uptime: >99.9%

### Business Metrics
- Customer acquisition: 50+ in Year 1
- Revenue growth: $2M+ in Year 1
- Customer retention: >90%
- Net Promoter Score: >50

### Compliance Metrics
- PQC migration completion: Track by organization
- Compliance score improvement: Average 30% increase
- Time to compliance: 80% reduction
- Audit readiness: 100% of assessments

---

## Post-Production: Shields Up — Robotics Security (Phase 4+)

**Status:** Planned — starts after GRCToolKit production release on `main`  
**Branch:** `feature/shields-up-robotics` (doc/planning stub; not merged until production gate)  
**Tracker:** [PM-TODO.md](PM-TODO.md)  
**Vision:** [SHIELDS-UP-ROBOTICS.md](SHIELDS-UP-ROBOTICS.md)

### Prerequisite gate

Do not begin Shields Up implementation until:

- GRCToolKit production release is tagged on `main`
- Helm/GKE deployment path is stable and governance docs are live
- MVP demo and CI pipelines are green on `main`
- PM sign-off on P0 items in [PM-TODO.md](PM-TODO.md)

### Vision

**Shields Up** adds AI-assisted, **read-only** routine security checks for robotic AI operating stacks (ROS 2, Linux edge, web/API surfaces). Findings map to:

- [Robot Security Framework (RSF)](https://github.com/aliasrobotics/RSF) layers
- OWASP Web, API, IoT, and LLM Top 10 (where applicable)
- NIST SP 800-53 Rev. 5 controls (SC, AC, AU families)
- OSCAL-style assessment evidence (reuse existing compliance-docs patterns)

All remediation requires **Human-in-the-Loop (HITL)** approval — no silent changes on robots that move.

### MVP scope (v0.1)

- ROS 2 + Linux lab environment (Dockerized test target)
- 10–15 read-only probes from [awesome-ros-security](https://github.com/iotsrg/awesome-ros-security) checklists
- JSON findings → AI security summary → Markdown/OSCAL report
- Per-layer Shields Up / Shields Down status
- OWASP LLM Top 10 read-only playbook: `ansible/playbooks/llm/owasp-llm-top-10-validate.yml` ([OWASP GenAI / LLM Top 10](https://genai.owasp.org/llm-top-10/))

### Deferred (post v0.1)

- Vendor-specific robot platforms
- NVIDIA ovrtx / Isaac sim integration
- Fleet schedulers and continuous monitoring at scale
- Automated remediation on production systems

### Brand

Optional product name **Shields Up** under the GRCToolKit / future sentinel brand line. Module lives inside this repository (not a separate repo for v1).

---

## Conclusion

GRCToolKit is uniquely positioned to become the leading platform for PQC migration management. The existing OSCAL integration, AI-powered compliance engine, and Ansible automation provide a solid foundation for rapid PQC capability development. By targeting the NIST conference presentation as a launch vehicle and positioning the MVP as the first comprehensive PQC GRC solution, iFocus Innovations can capture significant market share in this emerging space.

The alignment between the PQC Migration GRC Framework and GRCToolKit's technical capabilities creates a powerful narrative: the framework provides the strategic vision, and GRCToolKit provides the tactical execution platform. This combination addresses the complete PQC migration lifecycle from assessment through implementation to continuous monitoring.

---

**Last Updated**: 2026-07-02  
**Version**: 2.1  
**Status**: Active Development


