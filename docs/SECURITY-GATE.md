# Security Gate — GRCToolKit

## Overview

GRCToolKit enforces a multi-layered security gate that blocks pull request merges when HIGH or CRITICAL severity vulnerabilities are detected. This document describes the automated security scanning tools, severity thresholds, merge requirements, and how developers resolve blocked PRs.

## Security Scanners

### 1. CodeQL (Static Application Security Testing)

**When it runs:**
- On every pull request to `main`, `dev`, or `qa` branches
- On pushes to `main`, `dev`, or `qa` branches
- Weekly scheduled scan (Saturdays at 4:00 PM UTC / 9:00 AM America/Phoenix)

**What it scans:**
- JavaScript/TypeScript code
- Python code
- Security and quality queries

**Blocking threshold:**
- **HIGH**: Security severity ≥ 7.0/10
- **CRITICAL**: Security severity ≥ 9.0/10
- **Error-level rules**: Any rule with severity "error"

**Configuration:** `.github/workflows/codeql.yml`

**How it blocks:**
The CodeQL workflow fails the CI check when HIGH/CRITICAL alerts are found in pull requests, preventing merge until issues are resolved.

### 2. Trivy (Container & Infrastructure Scanning)

**When it runs:**
- On every pull request (via `pr-test.yml`)
- On pushes to `main` (via `ci-cd.yml`)

**What it scans:**
- Container images for known vulnerabilities
- Kubernetes manifests for misconfigurations
- Infrastructure-as-Code (Terraform, Helm charts)
- Secrets in code

**Blocking threshold:**
- **HIGH**: CVSS ≥ 7.0
- **CRITICAL**: CVSS ≥ 9.0

**Configuration:**
- `.github/workflows/ci-cd.yml` (lines 91-99)
- `.github/workflows/pr-test.yml` (lines 88-96)

**Key settings:**
```yaml
uses: aquasecurity/trivy-action@0.29.0
with:
  severity: 'HIGH,CRITICAL'
  ignore-unfixed: true      # Ignore issues without available patches
  exit-code: '1'            # Fail the job on findings
```

**How it blocks:**
The Trivy step fails with exit code 1 when HIGH/CRITICAL vulnerabilities are detected, blocking the CI check.

### 3. Docker Scout (Optional Supply Chain Analysis)

**When it runs:**
- Only when `DOCKER_SCOUT_TOKEN` secret is configured
- On pull requests and pushes to `main`

**What it scans:**
- Base image vulnerabilities
- Supply chain security
- Policy violations

**Current status:**
- **Optional** — gate only active when token is set
- To make mandatory: Set the `DOCKER_SCOUT_TOKEN` repository secret in GitHub Settings → Secrets and variables → Actions

**Configuration:** `.github/workflows/ci-cd.yml` and `.github/workflows/pr-test.yml` (Docker Scout steps)

## Severity Thresholds

| Scanner | LOW | MEDIUM | HIGH | CRITICAL |
|---------|-----|---------|------|----------|
| **CodeQL** | Advisory | Advisory | **BLOCKS** | **BLOCKS** |
| **Trivy** | Silent | Advisory | **BLOCKS** | **BLOCKS** |
| **Docker Scout** | Silent | Advisory | **BLOCKS*** | **BLOCKS*** |

\* Only when `DOCKER_SCOUT_TOKEN` is configured

## Merge Requirements

A pull request can only be merged when:

1. ✅ All required CI status checks pass:
   - `test` (from pr-test.yml or ci-cd.yml)
   - CodeQL analysis completes with no HIGH/CRITICAL alerts
   - Trivy scan completes with no HIGH/CRITICAL vulnerabilities
   - Docker Scout passes (if enabled)

2. ✅ At least 1 human approval from a code owner

3. ✅ All PR conversations resolved

4. ✅ Branch is up to date with base branch

See [BRANCH-PROTECTION.md](BRANCH-PROTECTION.md) for complete branch protection rules.

## How Developers Resolve a Blocked PR

### Step 1: Identify the Issue

When a security gate blocks your PR, the CI check will fail with details:

```
❌ BLOCKING: Found 2 HIGH/CRITICAL security alerts
Alert details:
  - js/sql-injection: SQL query built from user-controlled sources (src/api/search.js:45)
  - py/path-injection: User-controlled file path (scripts/report.py:123)

Please fix these security issues before merging.
See the Code Scanning alerts tab for full details: https://github.com/iFocus-Innovations-LLC/GRCToolKit/security/code-scanning
```

### Step 2: Review the Alert

1. Click the failed check in your PR
2. Navigate to **Security → Code scanning alerts** in the repository
3. Review the alert details, including:
   - Vulnerability description
   - Affected file and line number
   - Recommended fix
   - CWE/CVE references

### Step 3: Fix the Issue

**Option A: Fix in source code (preferred)**

Fix the root cause by updating your code:

```bash
# Make the fix in your branch
git checkout your-feature-branch
# Edit the affected file(s)
git add .
git commit -m "fix: resolve SQL injection vulnerability in search API"
git push
```

The CI will re-run automatically. If the fix is correct, the alert will be resolved and the check will pass.

**Option B: Dismiss as false positive (requires justification)**

Only dismiss an alert if you're confident it's a false positive or won't-fix:

1. Go to the alert in GitHub Security tab
2. Click **Dismiss alert**
3. Select reason:
   - **False positive** — The code is safe; the scanner misunderstood the context
   - **Won't fix** — The risk is accepted (document why in the PR)
   - **Used in tests** — Test code only, not in production
4. **Required:** Add a detailed comment in your PR explaining:
   - Why this is safe
   - What protections exist
   - Who approved the dismissal

**Who can dismiss alerts:**
- Repository maintainers with write access
- Requires human approval from a code owner before merge

**Dismissal review process:**
Dismissals are logged in the audit trail and reviewed during weekly security reviews (see below).

### Step 4: Update Dependencies (for Trivy vulnerabilities)

If Trivy blocks on a vulnerable dependency:

```bash
# For Python
pip install --upgrade <package-name>
pip freeze > requirements-gcp-dev.txt

# For Node.js
npm update <package-name>

# Rebuild and test
docker build -t grc-toolkit:test .
trivy image --severity HIGH,CRITICAL grc-toolkit:test
```

Commit the updated dependency files.

### Step 5: Verify Locally

Before pushing, verify the fix locally:

```bash
# Run CodeQL locally (if using CodeQL CLI)
codeql database create /tmp/db --language=python
codeql database analyze /tmp/db --format=sarif-latest --output=/tmp/results.sarif

# Run Trivy locally
trivy fs --severity HIGH,CRITICAL --exit-code 1 .
trivy image --severity HIGH,CRITICAL --exit-code 1 grc-toolkit:test
```

## Weekly Alert Review Cadence

**When:** Every Saturday at 9:00 AM America/Phoenix (4:00 PM UTC)

**Who:** Kevin (security lead) + automated weekly review

**Process:**
1. **Automated scan:** Weekly CodeQL scan runs Saturday morning (4:00 PM UTC / 9:00 AM America/Phoenix)
2. **Review:** Kevin reviews all open HIGH/CRITICAL alerts in the Security tab
3. **Triage new alerts:**
   - Assign to owners
   - Set target resolution date
   - Document risk acceptance if needed
4. **Review dismissed alerts from the past week:**
   - Verify justifications are sound
   - Re-open if needed
5. **Update the security dashboard**
6. **Escalate unresolved critical alerts to management**

**Alert aging policy:**
- CRITICAL: Must be resolved within 7 days or risk-accepted by management
- HIGH: Must be resolved within 30 days or risk-accepted by Kevin (security lead)

## Repository Configuration

### Required GitHub Settings

Most security gate configuration is in code (workflows), but some settings require repository admin access.

#### 1. Enable Code Scanning

**GitHub Default Setup (must be DISABLED after adding advanced workflow):**

⚠️ **Action required:** Once the advanced CodeQL workflow (`.github/workflows/codeql.yml`) is merged, disable GitHub's default setup to prevent upload conflicts:

1. Go to **Settings → Code security and analysis**
2. Under **Code scanning**, find "CodeQL analysis"
3. If "Default" is enabled, click **Disable**

The advanced workflow now handles all CodeQL scanning and uploads.

#### 2. Branch Protection Ruleset

A ruleset must be configured to make security checks required for merge.

**Settings → Rules → Rulesets → New branch ruleset**

Create a ruleset named `main-security-gate`:

**Target branches:** `main`, `dev`, `qa`

**Rules:**
- ✅ Require a pull request before merging
  - Required approvals: 1
  - Dismiss stale reviews: enabled
  - Require review from code owners: enabled
- ✅ Require status checks to pass before merging
  - ✅ Require branches to be up to date before merging
  - **Required checks:**
    - `test` (from ci-cd.yml / pr-test.yml)
    - `Analyze (javascript-typescript)` (from codeql.yml)
    - `Analyze (python)` (from codeql.yml)
- ✅ Require conversation resolution before merging
- ✅ Block force pushes
- ✅ Restrict deletions

**Alternative: Branch Protection Rules (legacy)**

If using legacy branch protection instead of rulesets:

**Settings → Branches → Branch protection rules → Add rule**

Branch name pattern: `main` (repeat for `dev`, `qa`)

- ✅ Require a pull request before merging (1 approval)
- ✅ Require status checks to pass before merging
  - ✅ Require branches to be up to date
  - **Status checks:**
    - `test`
    - `Analyze (javascript-typescript)`
    - `Analyze (python)`
- ✅ Require conversation resolution
- ✅ Include administrators (recommended)
- ✅ Restrict who can push (maintainers only)

#### 3. Code Scanning Alert Dismissal Permissions

**Settings → Code security and analysis → Code scanning**

Under "Alert dismissal permissions":
- ✅ Repository administrators
- ✅ Users with write access (for false positive marking; still requires PR approval)

#### 4. Required Secrets

**Settings → Secrets and variables → Actions**

| Secret | Required | Purpose | How to obtain |
|--------|----------|---------|---------------|
| `GCP_PROJECT_ID` | For GCP deploy | GCP project identifier | Your GCP project |
| `WORKLOAD_IDENTITY_PROVIDER` | For GCP deploy | OIDC authentication | GCP WIF setup |
| `GCP_SA_EMAIL` | For GCP deploy | Service account | GCP IAM service account |
| `DOCKER_SCOUT_TOKEN` | Optional* | Docker Scout scanning | [Docker Scout setup](https://docs.docker.com/scout/) |

\* Set `DOCKER_SCOUT_TOKEN` to make Docker Scout scanning mandatory

### Admin Setup Checklist

If you don't have admin access to the repository, provide this checklist to your administrator:

- [ ] Merge the security gate PR (this PR)
- [ ] Disable GitHub default CodeQL setup (Settings → Code security → CodeQL analysis → Disable)
- [ ] Create branch protection ruleset `main-security-gate` targeting `main`, `dev`, `qa`
  - [ ] Require pull request reviews (1 approval, code owners)
  - [ ] Require status checks: `test`, `Analyze (javascript-typescript)`, `Analyze (python)`
  - [ ] Require branches up to date
  - [ ] Block force pushes
- [ ] (Optional) Set `DOCKER_SCOUT_TOKEN` secret to enable Docker Scout mandatory scanning
- [ ] Verify: Open a test PR, confirm security checks appear and are required
- [ ] Schedule weekly security review (Saturdays 9:00 AM America/Phoenix, owned by Kevin)

## Testing the Security Gate

After configuration, verify the gate works:

### Test 1: Create a PR with a Known Vulnerability

```bash
git checkout -b test-security-gate

# Introduce a test vulnerability (DO NOT MERGE)
echo "import subprocess; subprocess.call(user_input, shell=True)" >> test_vuln.py

git add test_vuln.py
git commit -m "test: verify security gate blocks vulnerable code"
git push origin test-security-gate
```

Open a PR. Expected result:
- ✅ CodeQL should detect command injection (HIGH severity)
- ❌ PR should be blocked from merging
- The failed check should show: "BLOCKING: Found 1 HIGH/CRITICAL security alerts"

Delete the test branch after verification.

### Test 2: Verify Trivy Blocks Vulnerable Images

Add a known vulnerable base image to `Dockerfile`:

```dockerfile
FROM node:14-alpine  # Known vulnerabilities
```

Expected result:
- ❌ Trivy should fail with HIGH/CRITICAL vulnerabilities
- ❌ PR blocked from merging

Revert the change after verification.

### Test 3: Verify Merge Requirements

Create a clean PR:

Expected flow:
1. All security scans pass ✅
2. Code owner review required (blocks merge until approved)
3. After approval → merge allowed ✅

## Troubleshooting

### CodeQL workflow doesn't run

**Symptoms:** CodeQL check doesn't appear in PR

**Fixes:**
1. Verify `.github/workflows/codeql.yml` exists on the base branch
2. Check GitHub Actions are enabled: Settings → Actions → General → "Allow all actions"
3. Verify branch is one of: `main`, `dev`, `qa` (check workflow `on:` triggers)

### Trivy fails with "TOOMANYREQUESTS"

**Symptoms:** Trivy scan fails with rate limit errors

**Fix:** Add GitHub token to Trivy action:
```yaml
env:
  TRIVY_USERNAME: ${{ github.actor }}
  TRIVY_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
```

### Security check required but not appearing

**Symptoms:** PR shows "Required status checks: test, Analyze (python) — Waiting"

**Fix:**
1. Push a new commit to trigger the check
2. Verify the workflow runs: Actions tab
3. If workflow fails, check logs for errors
4. Ensure branch is up to date with base

### False positive can't be dismissed

**Symptoms:** Dismissed alert still blocks PR

**Fix:**
1. Dismiss the alert in GitHub Security tab (not in the PR)
2. Wait 1-2 minutes for GitHub to sync the dismissal
3. Re-run the failed CodeQL check
4. If still blocked, close and reopen the PR to trigger a fresh scan

## Further Reading

- [BRANCH-PROTECTION.md](BRANCH-PROTECTION.md) — Complete branch protection rules
- [SECURITY.md](SECURITY.md) — Security implementation and secret management
- [CONTRIBUTING.md](../CONTRIBUTING.md) — Contributing guidelines
- [CodeQL Documentation](https://codeql.github.com/docs/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
