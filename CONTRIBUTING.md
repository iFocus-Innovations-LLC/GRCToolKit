# Contributing to GRCToolKit.ai

Thank you for your interest in contributing to **GRCToolKit.ai** — an open source GRC platform with NIST SP 800-53 Rev. 5, OSCAL, PQC migration tooling, and Human-in-the-Loop (HITL) guardrails.

This project is maintained by [iFocus Innovations LLC](https://github.com/iFocus-Innovations-LLC). We welcome bug reports, documentation improvements, and well-scoped feature contributions.

## Before you start

1. Read the [README](README.md) for architecture and quick start.
2. Review [docs/SECURITY.md](docs/SECURITY.md) — **never commit API keys, tokens, or credentials**.
3. Read [docs/HITL-FRAMEWORK.md](docs/HITL-FRAMEWORK.md) if you are changing AI agent logic, confidence scoring, or remediation flows.
4. Agree to our [Code of Conduct](CODE_OF_CONDUCT.md).

## Reporting security issues

**Do not open a public GitHub issue for vulnerabilities.**

Follow the process in [docs/SECURITY.md](docs/SECURITY.md). Security reports are handled privately by the maintainers.

## Branch workflow

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready releases. Protected — merge via PR only. |
| `dev` | Integration branch for ongoing development (see also [docs/BRANCH-PROTECTION.md](docs/BRANCH-PROTECTION.md), which references `develop` — use `dev` as the live integration branch in this repo). |
| `feature/*`, `fix/*`, `chore/*` | Short-lived topic branches off `dev` |

Typical flow:

```bash
git checkout dev
git pull origin dev
git checkout -b feature/your-change
# ... make changes, test locally ...
git push -u origin feature/your-change
# Open a PR targeting dev (or main for release-critical hotfixes, with maintainer approval)
```

## Local development

### Prerequisites

- Docker (optional, for container tests)
- `bash`, `curl`, `git`
- A [Gemini API key](https://aistudio.google.com/) for AI features (local only — do not commit it)

### Quick local run

```bash
export GEMINI_API_KEY="your-key"
./scripts/run-local.sh
# Open http://127.0.0.1:8080/local-index.html
```

### Running tests

```bash
# Shell script syntax (CI runs these)
bash -n scripts/deploy.sh
bash -n scripts/test-mvp-demo.sh

# MVP demo smoke tests (requires running app or Docker)
BASE_URL=http://localhost:8080 ./scripts/test-mvp-demo.sh

# Container hardening / image pin checks
./scripts/check-container-hardening.sh
./scripts/check-image-pins.sh
```

See [docs/QA-TESTING-GUIDE.md](docs/QA-TESTING-GUIDE.md) for full QA procedures.

## Pull request guidelines

1. **One logical change per PR** — keep diffs focused and reviewable.
2. **Fill out the PR template** — describe what changed, why, and how you tested it.
3. **No secrets in code or logs** — use environment variables, Kubernetes Secrets, or GCP Secret Manager as documented in [docs/SECRETS-SETUP.md](docs/SECRETS-SETUP.md).
4. **Preserve HITL guardrails** — automated remediation without human approval is not acceptable. See [docs/HITL-FRAMEWORK.md](docs/HITL-FRAMEWORK.md).
5. **Match existing style** — follow patterns in the files you edit; avoid drive-by refactors.
6. **Update docs** when you change behavior, deployment steps, or public APIs.

### What runs on your PR

| Check | Source | Notes |
|-------|--------|-------|
| AI peer review | `.github/workflows/ai-pr-review.yml` | Automated GRC/security review comment; blocks on CRITICAL findings |
| PR tests | `.github/workflows/pr-test.yml` | Syntax checks, hardening, MVP demo script validation |
| CI/CD | `.github/workflows/ci-cd.yml` | Build, scan, deploy (varies by branch and repo secrets) |

All required checks must pass before merge. A **human maintainer approval** is also required for `main` and `dev`. See [docs/BRANCH-PROTECTION.md](docs/BRANCH-PROTECTION.md).

### CODEOWNERS

Changes to security-sensitive paths (`pqc/`, `ansible/`, `ai-agent/`, `terraform/`, `charts/`, etc.) require review from owners listed in [.github/CODEOWNERS](.github/CODEOWNERS).

## Contribution areas

We especially welcome contributions in these domains:

| Area | Path | Notes |
|------|------|-------|
| NIST / OSCAL | `oscal/`, `compliance-docs/` | Control mappings, catalog updates |
| PQC migration | `pqc/`, `ansible/playbooks/pqc/` | FIPS 203/204/205 references |
| AI compliance engine | `ai-agent/` | Prompting, validation, HITL thresholds |
| Infrastructure | `charts/`, `terraform/`, `k8s/` | Helm, GCP bootstrap, K8s manifests |
| Documentation | `docs/` | Guides, demos, deployment checklists |
| UI | `grctoolkit.html` | Demo and analyst workflows |

## Code of conduct

All participants must follow our [Code of Conduct](CODE_OF_CONDUCT.md). Maintainers may remove, edit, or reject contributions that violate it.

## Questions

- Open a [GitHub Discussion](https://github.com/iFocus-Innovations-LLC/GRCToolKit/discussions) or issue for general questions.
- Tag maintainers on PRs for review when checks are green.

Thank you for helping make compliance automation more accessible and trustworthy.
