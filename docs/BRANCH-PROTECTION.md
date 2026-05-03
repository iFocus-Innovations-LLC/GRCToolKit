# Branch Protection Rules — GRCToolKit.ai
# ─────────────────────────────────────────────────────────────────────────────
# This document defines the required branch protection configuration for the
# `main` and `develop` branches. These rules enforce the Human-in-the-Loop
# (HITL) gate that mirrors the HITL guardrails in the application itself.
#
# Apply these settings at:
# GitHub → Settings → Branches → Add branch ruleset
# ─────────────────────────────────────────────────────────────────────────────

## `main` Branch — Production Gate (Strictest)

### How to configure
1. Go to **Settings → Branches → Add branch ruleset**
2. Name: `main-protection`
3. Target: `main`

### Required settings

| Setting | Value | Reason |
|---|---|---|
| Require a pull request before merging | ✅ Enabled | No direct pushes to main |
| Required approvals | **1** (increase to 2 as contributors grow) | Human sign-off required |
| Dismiss stale reviews on new commits | ✅ Enabled | Re-review after changes |
| Require review from Code Owners | ✅ Enabled | Enforces CODEOWNERS file |
| Require status checks to pass | ✅ Enabled | CI must be green |
| Required status checks | `test` (from ci-cd.yml), `ai-review` (from ai-pr-review.yml) | Both pipelines must pass |
| Require branches to be up to date | ✅ Enabled | No stale merges |
| Require conversation resolution | ✅ Enabled | All PR comments must be resolved |
| Restrict who can push to matching branches | ✅ Enabled → `@iFocus-Innovations-LLC` only | Only maintainer can merge |
| Allow force pushes | ❌ Disabled | Protects git history |
| Allow deletions | ❌ Disabled | main cannot be deleted |
| Block force pushes | ✅ Enabled | Extra safety |

---

## `develop` Branch — Integration Gate (Moderate)

### How to configure
1. Go to **Settings → Branches → Add branch ruleset**
2. Name: `develop-protection`
3. Target: `develop`

### Required settings

| Setting | Value | Reason |
|---|---|---|
| Require a pull request before merging | ✅ Enabled | All changes via PR |
| Required approvals | **1** | At least one human review |
| Require review from Code Owners | ✅ Enabled | CODEOWNERS applies here too |
| Require status checks to pass | ✅ Enabled | |
| Required status checks | `test` (from ci-cd.yml), `ai-review` (from ai-pr-review.yml) | |
| Require branches to be up to date | ✅ Enabled | |
| Allow force pushes | ❌ Disabled | |
| Allow deletions | ❌ Disabled | |

---

## PR Labels to Create
Before the AI review workflow can apply labels, create these in:
**GitHub → Issues → Labels → New label**

| Label name | Color | Description |
|---|---|---|
| `ai-review: approved` | `#0075ca` (blue) | Claude AI review passed |
| `ai-review: changes-needed` | `#e4e669` (yellow) | Claude AI flagged issues |
| `ai-review: critical` | `#d73a4a` (red) | CRITICAL security issue found |
| `needs-human-review` | `#6f42c1` (purple) | Awaiting maintainer approval |
| `pqc` | `#0052cc` (dark blue) | PQC migration related |
| `compliance` | `#1d76db` (blue) | NIST/OSCAL compliance related |
| `security` | `#d73a4a` (red) | Security-sensitive change |
| `infrastructure` | `#e4e669` (yellow) | K8s/Docker/GCP change |
| `good first issue` | `#7057ff` (purple) | Good for new contributors |
| `help wanted` | `#008672` (green) | Extra attention needed |

---

## Secrets Required
Ensure all of these are set under **Settings → Secrets and variables → Actions**:

| Name | Used by | Notes |
|---|---|---|
| `ANTHROPIC_API_KEY` | ai-pr-review.yml | Anthropic Console → API Keys |
| `GCP_PROJECT_ID` | ci-cd.yml | Your GCP project ID |
| `WORKLOAD_IDENTITY_PROVIDER` | ci-cd.yml | WIF OIDC provider resource (no long-lived JSON key) |
| `GCP_SA_EMAIL` | ci-cd.yml | Service account Actions impersonates |
| `GKE_CLUSTER_NAME` | ci-cd.yml | Your GKE cluster name |
| `DOCKER_SCOUT_TOKEN` | ci-cd.yml | Optional — Docker Scout token |

---

## The Complete Gate: How a PR flows to `main`

```
Developer opens PR (feature → develop or develop → main)
           │
           ├──[Automatic]──► AI PR Review Agent runs
           │                  └─ Posts structured review comment
           │                  └─ Labels PR
           │                  └─ FAILS if CRITICAL issue found ──► PR blocked
           │
           ├──[Automatic]──► CI/CD Pipeline runs
           │                  └─ Image pins check
           │                  └─ Container hardening check
           │                  └─ Docker build + health tests
           │                  └─ Docker Scout CVE scan
           │                  └─ Trivy security scan
           │                  └─ FAILS on critical/high CVEs ──► PR blocked
           │
           ├──[Human]──────► Maintainer (@iFocus-Innovations-LLC) reviews
           │                  └─ Reads Claude's AI review comment
           │                  └─ Resolves all conversations
           │                  └─ Approves PR
           │
           └──[Merge]──────► Squash merge to main → GCP deploy triggered
```

---

## As the Project Grows: Adding Contributors

When you onboard your first external contributors, update CODEOWNERS to add
trusted reviewers per domain:

```
# Example: add a PQC domain expert as co-owner of pqc/ and ansible/
pqc/        @iFocus-Innovations-LLC @new-pqc-contributor
ansible/    @iFocus-Innovations-LLC @new-pqc-contributor

# Example: add a frontend contributor for the UI
grctoolkit.html   @iFocus-Innovations-LLC @new-frontend-contributor
```

Increase required approvals on `main` to **2** once you have 3+ active contributors.
