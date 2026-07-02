# GRCToolKit

**Version**: 2.1.0-dev  
**Status**: Development/QA Ready  
**Last Updated**: 2026-03-14

A comprehensive Governance, Risk, and Compliance (GRC) toolkit that provides AI-powered analysis of compliance scenarios and suggests relevant NIST SP 800-53 Rev. 5 Security and Privacy Controls. The application features OSCAL integration, Ansible automation, and a robust Post-Quantum Cryptography (PQC) migration management platform with Human-in-the-Loop (HITL) guardrails. Containerized and ready for deployment to Google Cloud Platform (GCP) Kubernetes environments.

## 🚀 Quick Start

### Local Development
1. Set up secrets (see [docs/SECRETS-SETUP.md](docs/SECRETS-SETUP.md)) – e.g. `export GEMINI_API_KEY` from [Google AI Studio](https://aistudio.google.com/).
2. **Quick local server (no Docker)** — serves the repo so `/ai-agent/` paths work; writes gitignored `local-index.html`:
   ```bash
   export GEMINI_API_KEY="your-key"
   ./scripts/run-local.sh
   ```
   Open **http://127.0.0.1:8080/local-index.html** (override port: `PORT=8090 ./scripts/run-local.sh`).
3. **Docker** — build and run:
   ```bash
   docker build -t grc-toolkit .
   docker run -p 8080:8080 -e GEMINI_API_KEY=$GEMINI_API_KEY grc-toolkit
   ```
4. Open `http://localhost:8080/` in your web browser (Docker) or the `local-index.html` URL above.
5. Enter a GRC scenario and click "Analyze Scenario"

### Containerized Deployment
- **Helm (recommended)**: [Helm & Terraform guide](docs/HELM-TERRAFORM.md) — chart in `charts/grc-toolkit/`.
- **GCP reference**: [Deployment Guide](docs/DEPLOYMENT.md), [GCP Deployment Checklist](docs/GCP-DEPLOYMENT-CHECKLIST.md) (GKE + secrets; use Terraform + Helm below for registry/bootstrap).
- **Legacy scripts** (flat `k8s/` manifests): `./scripts/setup-gcp.sh` then `./scripts/deploy.sh production`.

### GCP lower environment (sys admin)

Use this order so you do not duplicate Artifact Registry setup (Terraform already creates the Docker repo and enables core APIs).

1. **Org / project** — Create or choose a **non-production** GCP project, attach **billing**, and set a default region (e.g. `us-central1`). Resolve any **org policies** that block GKE, Artifact Registry, or Secret Manager.
2. **Terraform identity** — Decide who runs Terraform (your user or a dedicated SA). Grant at least **Service Usage Admin** and **Artifact Registry Admin** on that project (or broader **Editor** / **Owner** for a small dev tenant). Details: [`terraform/gcp-bootstrap/README.md`](terraform/gcp-bootstrap/README.md).
3. **Bootstrap with Terraform** — From [`terraform/gcp-bootstrap`](terraform/gcp-bootstrap): `terraform init` / `plan` / `apply` using `TF_VAR_project_id` or Secret Manager as documented there. Note the output **`artifact_registry_repository`** / **`helm_image_registry_hint`** (default repo id is `grc-toolkit`, not `grc-toolkit-repo`).
4. **GKE** — Terraform does **not** create a cluster. Create a **dev GKE** cluster (Console or `gcloud`; see [GCP Deployment Checklist](docs/GCP-DEPLOYMENT-CHECKLIST.md) “GKE Cluster Creation”), then `gcloud container clusters get-credentials …`.
5. **Registry auth** — `gcloud auth configure-docker REGION-docker.pkg.dev`, then build and push the image to the path from step 3 (same flow as [Helm & Terraform](docs/HELM-TERRAFORM.md)).
6. **App secrets** — Store **Gemini** (and any other keys) in **Secret Manager** or create a Kubernetes secret; follow [Secrets Setup](docs/SECRETS-SETUP.md). Do not commit keys.
7. **Install** — `helm upgrade --install` per [Helm & Terraform](docs/HELM-TERRAFORM.md) (use `examples/values-ingress-gke.yaml` or your ingress class).

CI/CD to this project uses GitHub secrets (e.g. `GCP_PROJECT_ID`, service account key or WIF) as described in [Secrets Setup](docs/SECRETS-SETUP.md).

## 📚 Documentation

Detailed documentation for the GRCToolKit can be found in the `docs/` directory:

- **Frameworks & Architecture**:
  - [HITL Framework](docs/HITL-FRAMEWORK.md) - Human-in-the-Loop guardrails and sentinel architecture.
  - [PQC Integration Summary](docs/PQC-INTEGRATION-SUMMARY.md) - Post-Quantum Cryptography migration strategy.
  - [OSCAL Integration](docs/OSCAL-INTEGRATION.md) - Open Security Controls Assessment Language implementation.
  - [Roadmap](docs/ROADMAP.md) - Project development phases and future enhancements.

- **Deployment & Operations**:
  - [Helm & Terraform](docs/HELM-TERRAFORM.md) - Helm chart for any Kubernetes; optional GCP Terraform bootstrap.
  - [Deployment Guide](docs/DEPLOYMENT.md) - General deployment instructions.
  - [GCP Deployment Checklist](docs/GCP-DEPLOYMENT-CHECKLIST.md) - Specific steps for Google Cloud Platform.
  - [Secrets Setup](docs/SECRETS-SETUP.md) - API keys and secrets (GitHub Actions, GCP Secret Manager, local).
  - [Security Policy](docs/SECURITY.md) - Security practices and reporting.
  - [Zero-Trust Agentic AI](ai-agent/openclaw/SOUL.md) - Our shift to autonomous, secret-less compliance auditing.

- **Testing & QA**:
  - [QA Testing Guide](docs/QA-TESTING-GUIDE.md) - Comprehensive testing procedures.
  - [Conference Demo Guide](docs/CONFERENCE-DEMO-GUIDE.md) - Script for live demonstrations.
  - [GCP Demo Guide](docs/GCP-DEMO-GUIDE.md) - Setting up a cloud-based demo environment.

- **Releases**:
  - [Changelog](docs/CHANGELOG.md) - History of changes and versions.
  - [Release Notes v2.0.0-dev](docs/RELEASE-NOTES-v2.0.0-dev.md) - Specific notes for the previous development release.

## 🏗️ Architecture

This application provides a modern UI for interacting with a GRC Compliance Engine. It uses the **Gemini API** (`generateContent` on **v1beta**) with a default model such as **`gemini-2.5-flash`** (supports structured JSON / `response_mime_type`). Avoid legacy IDs like **`gemini-pro`** for JSON mode. The engine integrates with Ansible playbooks for automated control validation and generates OSCAL-compliant documentation.

## ✨ Key Features

### 🤖 AI Compliance Engine
- **Gemini API integration**: **v1beta** `generateContent` with **`gemini-2.5-flash`** by default (configurable via `window.GEMINI_MODEL`); structured JSON output for GRC analysis.
- **Scenario Recognition**: Automatically detects PQC migration, quantum risk, and standard GRC scenarios.
- **Structured JSON Output**: AI responses include controls, CSF mappings, and implementation recommendations.

### 🛡️ Human-in-the-Loop (HITL) Guardrails
- **Three-Tier Model**: Automated, Human-Reviewed, and Human-Guided decision paths.
- **Confidence Scoring**: AI-generated recommendations include confidence levels to trigger human review.
- **Sentinel Architecture**: Policy Anchors and Context Filters ensure AI responses remain within safety boundaries.
- **Audit Trails**: Complete history of human overrides and approvals for compliance.

### 🔐 PQC Migration Management
- **Cryptographic Asset Inventory**: Automated discovery and cataloging of cryptographic implementations.
- **Quantum Risk Assessment**: Scoring based on algorithm vulnerability and data sensitivity.
- **Migration Roadmap**: Four-phase planning (Preparation, Baseline, Execution, Monitoring).
- **PQC Ansible Automation**: Playbooks for deploying ML-KEM (FIPS 203), ML-DSA (FIPS 204), and SLH-DSA (FIPS 205).
- **Compliance Timeline**: Tracking 2030/2035 deadlines for quantum readiness.

### 📄 OSCAL & Automation
- **OSCAL Integration**: Full NIST 800-53 R5 OSCAL catalog integration.
- **Ansible Playbooks**: Automated validation for AC-3, AC-6, AU-2, SC-7, and PQC controls.
- **Auditor Reports**: Automated generation of compliance test reports.

### 🚀 Cloud-Native Deployment
- **Hardened Containers**: Pinned nginx base image (port 8080), non-root user, and security headers.
- **Kubernetes Ready**: Manifests for GKE including HPA, Ingress, and Graceful Shutdown.
- **CI/CD Pipeline**: GitHub Actions with Docker Scout and Trivy scanning, image pin checks, and SARIF reporting.
- **Secrets**: No hardcoded keys; [SECRETS-SETUP.md](docs/SECRETS-SETUP.md) for GitHub Actions, GCP Secret Manager, and local dev.

## 🔮 Planned Enhancements & Roadmap

### Core Platform Enhancements

**Refine AI Prompting**: Enhanced prompt templates with CSF 2.0 mappings for more precise and structured responses from the AI.

**Structured Output**: JSON schema validation for AI responses with consistent control ID, name, and explanation structure.

**Actual GRC Data Integration**: Database integration (Firestore) for NIST 800-53 and CSF 2.0 data, enabling sophisticated backend control mapping and reasoning.

**User Authentication & Data Persistence**: Firebase Authentication and Firestore integration for user management, query history, and report storage.

**Advanced UI**: Enhanced filtering, control implementation tracking, interactive dashboards, and real-time collaboration features.

**Backend AI Logic**: Fine-tuned models for GRC scenarios, knowledge graph integration, and connections with other GRC tools.

**Integration APIs**: RESTful APIs for external tool integration, webhook support, and third-party connectors.

### 🚀 Post-Quantum Cryptography (PQC) Migration Features

GRCToolKit is evolving into a comprehensive PQC migration management platform, building on its existing NIST 800-53 R5 and OSCAL foundation.

#### Phase 1: Core PQC Capabilities (Q1 2026)
- **PQC Scenario Analysis**: AI-powered recognition of PQC migration scenarios with mapping to NIST 800-53 cryptographic controls (SC-12, SC-13, SC-17)
- **Cryptographic Asset Inventory**: Automated discovery and cataloging of cryptographic implementations with quantum vulnerability classification
- **PQC Risk Assessment Engine**: Quantum risk scoring based on algorithm type, data sensitivity, system criticality, and timeline to quantum threat
- **PQC Control Mapping**: Integration of NIST FIPS 203, 204, 205 with NIST 800-53 controls and CSF 2.0 functions

#### Phase 2: Migration Roadmap (Q2 2026)
- **Four-Phase Roadmap**: Structured PQC migration planning (Preparation → Baseline Understanding → Planning & Execution → Monitoring & Evaluation)
- **Timeline Management**: Progress tracking with 2030 deprecation and 2035 disallowance deadline monitoring
- **Automated Reporting**: Executive summaries and compliance status dashboards

#### Phase 3: Automation and Intelligence (Q3 2026)
- **Ansible PQC Automation**: Playbooks for deploying ML-KEM (FIPS 203), ML-DSA (FIPS 204), and SLH-DSA (FIPS 205)
- **Vendor Solution Database**: Catalog of PQC-ready vendors with cost estimation and ROI analysis
- **Continuous Threat Monitoring**: Real-time quantum computing threat intelligence and algorithm deprecation alerts
- **Cryptographic Agility Assessment**: Architecture flexibility evaluation and migration complexity scoring

#### Phase 4: Enterprise Features (Q4 2026)
- **Multi-Tenant Support**: Role-based access control and organization-specific compliance management
- **Advanced Analytics**: Compliance trend analysis, predictive analytics, and custom dashboards
- **API Integration**: RESTful APIs, webhooks, and SDK for third-party integrations
- **Mobile Application**: iOS and Android apps for executive access and reporting

**Post-production (planned):** [Shields Up — robotics security](docs/ROADMAP.md#post-production-shields-up--robotics-security-phase-4) — read-only OWASP/RSF routine checks for ROS 2 and robotic AI stacks (after core platform production release; see [PM-TODO.md](docs/PM-TODO.md)).

For detailed roadmap information, see [ROADMAP.md](docs/ROADMAP.md).

## 🎯 Use Cases

### Compliance Audits
- Automated control validation with Ansible playbooks
- Evidence collection and documentation
- OSCAL-compliant audit reports
- Risk assessment and prioritization

### Security Assessments
- Continuous compliance monitoring
- Control effectiveness measurement
- Gap analysis and remediation planning
- Real-time compliance validation

### PQC Migration Management
- Cryptographic asset discovery and inventory
- Quantum risk assessment and prioritization
- Four-phase migration roadmap tracking
- Automated PQC deployment with Ansible
- Compliance timeline monitoring (2030/2035 deadlines)

### Regulatory Reporting
- Standardized compliance reports (OSCAL format)
- Machine-readable documentation
- Automated evidence collection
- Complete audit trail maintenance
