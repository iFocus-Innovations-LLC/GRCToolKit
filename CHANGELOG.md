# Changelog

All notable changes to GRCToolKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0-dev] - 2025-01-XX

### Added - Post-Quantum Cryptography (PQC) Migration Features

#### Core PQC Capabilities
- **PQC Compliance Engine**: Extended GRC compliance engine with PQC-specific scenario analysis
- **PQC Asset Inventory Module**: Automated discovery and cataloging of cryptographic implementations
- **Quantum Risk Assessment**: Risk scoring based on algorithm vulnerability, data sensitivity, and system criticality
- **PQC Control Mapping**: Integration of NIST FIPS 203, 204, 205 with NIST 800-53 controls

#### Ansible Automation
- **PQC Inventory Playbook**: Automated cryptographic asset discovery (`ansible/playbooks/pqc/inventory.yml`)
- **PQC Risk Assessment Playbook**: Quantum risk assessment automation (`ansible/playbooks/pqc/assess.yml`)
- **ML-KEM Deployment**: Automated ML-KEM (FIPS 203) deployment (`ansible/playbooks/pqc/deploy-mlkem.yml`)
- **ML-DSA Deployment**: Automated ML-DSA (FIPS 204) deployment (`ansible/playbooks/pqc/deploy-mldsa.yml`)
- **SLH-DSA Deployment**: Automated SLH-DSA (FIPS 205) deployment (`ansible/playbooks/pqc/deploy-slhdsa.yml`)
- **Hybrid Crypto Deployment**: Hybrid classical + PQC cryptographic approach (`ansible/playbooks/pqc/hybrid-crypto.yml`)
- **PQC Validation**: PQC implementation testing and validation (`ansible/playbooks/pqc/validate.yml`)

#### Documentation
- **ROADMAP.md**: Comprehensive development roadmap with PQC migration strategy
- **PQC-INTEGRATION-SUMMARY.md**: Summary of all PQC integration changes
- **pqc/DATABASE-SCHEMA.md**: Complete database schema for PQC features
- **Updated README.md**: Added PQC migration features and roadmap sections
- **Updated CONFERENCE-DEMO-GUIDE.md**: Added 4 PQC demo scenarios (Scenarios 5-8)
- **Updated OSCAL-INTEGRATION.md**: Added PQC extensions and use cases

#### Code Enhancements
- **PQC Scenario Detection**: AI engine now recognizes PQC migration scenarios
- **PQC Playbook Integration**: All PQC playbooks properly loaded and mapped
- **Quantum Risk Scoring**: Algorithm-based risk assessment with timeline calculations
- **Migration Roadmap Structure**: Four-phase roadmap framework (Preparation → Baseline → Planning → Monitoring)

### Changed
- **GRC Compliance Engine**: Extended with PQC scenario mappings and playbook loading
- **Playbook Loading**: Now loads both standard GRC and PQC playbooks
- **Control Mapping**: Added PQC-specific control extraction methods

### Fixed
- **Playbook References**: Fixed PQC playbook name references to match actual file structure
- **Playbook Loading**: PQC playbooks now properly loaded into ansiblePlaybooks Map
- **Scenario Mappings**: Corrected playbook paths in PQC scenario mappings

### Technical Details
- **Version**: 2.0.0-dev
- **Target Environment**: GCP Kubernetes (GKE)
- **Deployment Status**: Development/QA Ready
- **Breaking Changes**: None (backward compatible with v1.1)

---

## [1.1.0] - 2024-XX-XX

### Added - OSCAL Integration
- OSCAL Compliance: Full NIST 800-53 R5 OSCAL catalog integration
- AI Compliance Engine: Automated assessment and control mapping
- Ansible Automation: Automated compliance control implementation
- Auditor Reports: Automated compliance documentation generation
- Enterprise Security: Enhanced security documentation and best practices

---

## [1.0.0] - 2024-XX-XX

### Added - Initial Release
- AI-powered GRC scenario analysis
- NIST 800-53 R.5 control recommendations
- Gemini 2.0 Flash integration
- Responsive web interface
- Containerized deployment
- Kubernetes manifests for GCP

