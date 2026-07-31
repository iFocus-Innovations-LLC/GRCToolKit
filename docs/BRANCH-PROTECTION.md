# Branch Protection Rules — GRCToolKit.ai
# ─────────────────────────────────────────────────────────────────────────────
# Required branch protection for `main` and `dev`. These rules enforce the
# Human-in-the-Loop (HITL) gate that mirrors HITL guardrails in the application.
#
# Branching model and QA/Demo freeze: [RELEASE-BRANCHING.md](RELEASE-BRANCHING.md)
#
# Apply at: GitHub → Settings → Branches → Add branch ruleset
# ─────────────────────────────────────────────────────────────────────────────

## `main` Branch — Production Gate (Strictest)

### How to configure
1. Go to **Settings → Branches → Add branch ruleset**
2. Name: `main-protection`
3. Target: `main`

### Required settings

| Setting | Value | Reason |
|---|---|---|
| Require a pull request before merging | Enabled | No direct pushes to main |
| Required approvals | **1** (increase to 2 as contributors grow) | Human sign-off required |
| Dismiss stale reviews on new commits | Enabled | Re-review after changes |
| Require review from Code Owners | Enabled | Enforces CODEOWNERS file |
| Require status checks to pass | Enabled | CI must be green |
| Required status checks | `test` (from ci-cd.yml / pr-test.yml) | Hardening, pins, Trivy, MVP tests — **no LLM peer-review job in MVP** |
| Require branches to be up to date | Enabled | No stale merges |
| Require conversation resolution | Enabled | All PR comments must be resolved |
| Restrict who can push to matching branches | Enabled → `@iFocus-Innovations-LLC` only | Only maintainer can merge |
| Allow force pushes | Disabled | Protects git history |
| Allow deletions | Disabled | main cannot be deleted |
| Block force pushes | Enabled | Extra safety |

> **Maintainer action:** If GitHub still lists `ai-review` as a required check, remove it from the ruleset after this MVP change (workflow removed).

---

## `dev` Branch — Integration Gate (Moderate)

> The live integration branch is **`dev`**. Apply the same rules to `dev`.

### How to configure
1. Go to **Settings → Branches → Add branch ruleset**
2. Name: `dev-protection`
3. Target: `dev`

### Required settings

| Setting | Value | Reason |
|---|---|---|
| Require a pull request before merging | Enabled | All changes via PR |
| Required approvals | **1** | At least one human review |
| Require review from Code Owners | Enabled | CODEOWNERS applies here too |
| Require status checks to pass | Enabled | |
| Required status checks | `test` (from ci-cd.yml / pr-test.yml) | Same scanners as main; no Anthropic CI |
| Require branches to be up to date | Enabled | |
| Allow force pushes | Disabled | |
| Allow deletions | Disabled | |

---

## PR Labels to Create

**GitHub → Issues → Labels → New label**

| Label name | Color | Description |
|---|---|---|
| `needs-human-review` | `#6f42c1` (purple) | Awaiting maintainer approval |
| `pqc` | `#0052cc` (dark blue) | PQC migration related |
| `compliance` | `#1d76db` (blue) | NIST/OSCAL compliance related |
| `security` | `#d73a4a` (red) | Security-sensitive change |
| `infrastructure` | `#e4e669` (yellow) | K8s/Docker/GCP change |
| `good first issue` | `#7057ff` (purple) | Good for new contributors |
| `help wanted` | `#008672` (green) | Extra attention needed |

Legacy `ai-review:*` labels (Claude CI) are **retired** for MVP. Optional multi-model review may return after GenAI research (PM-TODO P6).

---

## Secrets Required

**Settings → Secrets and variables → Actions**:

| Name | Used by | Notes |
|---|---|---|
| `GCP_PROJECT_ID` | ci-cd.yml | Your GCP project ID |
| `WORKLOAD_IDENTITY_PROVIDER` | ci-cd.yml | WIF OIDC provider resource (no long-lived JSON key) |
| `GCP_SA_EMAIL` | ci-cd.yml | Service account Actions impersonates |
| `GKE_CLUSTER_NAME` | ci-cd.yml | Your GKE cluster name |
| `DOCKER_SCOUT_TOKEN` | ci-cd.yml | Optional — Docker Scout token |
| `DOCKER_PAT` | build.yml (`ci` workflow) | Docker Hub — only if `ENABLE_DOCKERHUB_CI` is enabled |

`ANTHROPICAPI` is **not required** for MVP CI (AI peer-review workflow removed).

### Variables (optional — keep `main` green without registry secrets)

| Name | Set to | Effect |
|---|---|---|
| `ENABLE_DOCKERHUB_CI` | `true` | Runs `build.yml` Docker Hub login + build on `main` |
| `ENABLE_GCP_GAR_DEPLOY` | `true` | Runs `ci-cd.yml` `build-and-push` and deploy jobs |

---

## The Complete Gate: How a PR flows to `main`

```
   Developer opens PR (feature → dev, or release/hotfix → main)
           │
           ├──[Automatic]──► CI/CD / PR test pipeline
           │                  └─ Image pins check
           │                  └─ Container hardening check
           │                  └─ Docker build + health tests (as configured)
           │                  └─ Docker Scout / Trivy security scan
           │                  └─ FAILS on critical/high CVEs ──► PR blocked
           │
           ├──[Human]──────► Maintainer (@iFocus-Innovations-LLC) reviews
           │                  └─ CODEOWNERS paths
           │                  └─ Resolves conversations
           │                  └─ Approves PR
           │
           └──[Merge]──────► Squash merge → tag releases / QA freeze per RELEASE-BRANCHING.md
```

---

## As the Project Grows: Adding Contributors

When you onboard external contributors, update CODEOWNERS per domain and increase required approvals on `main` to **2** once you have 3+ active contributors.
