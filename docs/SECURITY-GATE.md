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

**Configuration:** `.github/workflows/codeql.yml`

**How it blocks:**
CodeQL uploads SARIF results to GitHub Security. Blocking is enforced via GitHub's native 'Require code scanning results' ruleset rule (Settings → Rules → Rulesets). Set the severity threshold to 'High or higher' to block PRs with HIGH/CRITICAL findings. This native enforcement correctly handles alert dismissals and provides consistent merge blocking across all code scanning tools.

### 2. Trivy (Container & Infrastructure Scanning)

**When it runs:**
- On every pull request (via `pr-test.yml`)
- On pushes to `main` (via `ci-cd.yml`)

**What it scans:**
- Container images for known vulnerabilities (OS packages, language dependencies)
- Note: Trivy scans the Docker image only. It does not scan Kubernetes manifests, Terraform, or Helm charts in this configuration.

**Blocking threshold:**
- **HIGH**: CVSS ≥ 7.0
- **CRITICAL**: CVSS ≥ 9.0
- With `ignore-unfixed: true`, only vulnerabilities with available patches block merges

**Configuration:**
- `.github/workflows/ci-cd.yml` (Security scan with Trivy step)
- `.github/workflows/pr-test.yml` (Security scan with Trivy step)

**Key settings:**
```yaml
uses: aquasecurity/trivy-action@0.35.0
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

### 4. OpenSCAP Compliance Scanning

**When it runs:**
- On every pull request to `main`, `dev`, or `qa` branches
- On pushes to `main`, `dev`, or `qa` branches
- Can be triggered manually via workflow_dispatch

**What it scans:**
- **CI runner baseline** (Ubuntu 24.04) against SCAP Security Guide (SSG) profiles
- Uses CIS Level 1 Server benchmark for NIST 800-53 alignment
- Generates XCCDF results (ARF) and HTML compliance reports

**Scanning scope:**
This workflow scans the **build environment** (GitHub Actions runner), not the Alpine container itself. This design choice reflects a technical constraint: Alpine Linux lacks comprehensive SCAP Security Guide profile coverage because it uses musl libc instead of glibc and apk instead of apt/yum package managers.

The CI runner baseline scan provides:
- NIST 800-53 compliance evidence for the build infrastructure
- CIS benchmark validation of the CI environment
- Compliance baseline that can be used for FedRAMP and CMMC evidence

Container security remains covered by existing Trivy and Docker Scout vulnerability scanning.

**Blocking threshold:**
- **HIGH severity rule failures**: SCAP rules marked as high severity that fail the compliance check
- The scan gates merges when high-severity compliance failures are detected
- Lower severity failures (medium, low) are reported but don't block

**Configuration:** `.github/workflows/openscap-compliance.yml`

**Key settings:**
```yaml
oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis_level1_server \
  --results openscap-reports/results.xml \
  --report openscap-reports/report.html
```

**Output artifacts:**
- `openscap-reports/report.html` - Human-readable compliance report
- `openscap-reports/results.xml` - XCCDF results in ARF (Asset Reporting Format)
- `openscap-reports/summary.txt` - Quick summary of pass/fail/error counts

**How it blocks:**
The workflow step fails when high-severity compliance rule failures are detected, blocking the required status check.

**Alpine container limitation:**
The container base image (nginx:alpine-slim) cannot be meaningfully scanned with OpenSCAP SSG profiles. Future enhancement options include:
1. Migrating to RHEL Universal Base Image (UBI) for full SCAP coverage
2. Custom OVAL vulnerability definitions for Alpine packages
3. Accepting CI runner baseline as the compliance boundary (current approach)

**Reading the report:**
1. Download the workflow artifact `openscap-compliance-reports`
2. Open `report.html` in a browser
3. Review failed rules, especially those marked "high severity"
4. Each rule includes:
   - NIST 800-53 control mapping (e.g., AC-6, IA-5)
   - Rule description and rationale
   - Remediation guidance (commands or configuration changes)
   - Pass/Fail/Not Applicable status

## Severity Thresholds

| Scanner | LOW | MEDIUM | HIGH | CRITICAL |
|---------|-----|---------|------|----------|
| **CodeQL** | Advisory | Advisory | **BLOCKS** | **BLOCKS** |
| **Trivy** | Silent | Advisory | **BLOCKS** | **BLOCKS** |
| **Docker Scout** | Silent | Advisory | **BLOCKS*** | **BLOCKS*** |
| **OpenSCAP** | Advisory | Advisory | **BLOCKS** | N/A** |

\* Only when `DOCKER_SCOUT_TOKEN` is configured  
\*\* OpenSCAP uses SCAP severity levels (low/medium/high), not CVSS scoring, so "CRITICAL" doesn't directly apply

## Merge Requirements

A pull request can only be merged when:

1. ✅ All required CI status checks pass:
   - `pr-test` (from pr-test.yml) or `ci-test` (from ci-cd.yml)
   - CodeQL analysis completes: `Analyze (javascript-typescript)`, `Analyze (python)`
   - GitHub's code scanning ruleset enforces no HIGH/CRITICAL unresolved alerts
   - Trivy scan completes with no HIGH/CRITICAL unfixed vulnerabilities
   - Docker Scout passes (if enabled)
   - OpenSCAP compliance scan completes with no high-severity rule failures

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

1. Go to the alert in **Security → Code scanning alerts** tab
2. Click **Dismiss alert**
3. Select reason:
   - **False positive** — The code is safe; the scanner misunderstood the context
   - **Won't fix** — The risk is accepted (document why in the PR)
   - **Used in tests** — Test code only, not in production
4. **Required:** Add a detailed comment explaining:
   - Why this is safe
   - What protections exist
   - Who approved the dismissal
5. After dismissal, the GitHub code scanning ruleset will allow the PR to merge (the alert is now in a non-blocking state)

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

### Step 4b: Resolve OpenSCAP Compliance Failures

If OpenSCAP blocks on high-severity compliance rule failures:

1. **Download the report artifact:**
   - Go to the failed workflow run
   - Download `openscap-compliance-reports` artifact
   - Open `report.html` in a browser

2. **Identify the failing rules:**
   - Look for rules marked **"high"** severity with **"fail"** result
   - Note the rule ID (e.g., `xccdf_org.ssgproject.content_rule_accounts_password_minlen_login_defs`)
   - Review the rule description, rationale, and NIST 800-53 mapping

3. **Understand the failure context:**
   - OpenSCAP scans the **CI runner** (Ubuntu 24.04), not your application code
   - Failures typically indicate baseline security configuration issues in the build environment
   - Some rules may be pre-existing environment conditions (not caused by your PR)

4. **Resolution options:**

   **Option A: Fix is not applicable to CI environment (most common)**
   
   Many CIS benchmark rules target production servers, not ephemeral CI runners. If a rule failure is:
   - Not relevant to CI/CD security posture
   - Caused by GitHub Actions runner defaults
   - Outside the control of this repository
   
   Then document why it's not applicable and continue with the PR. The repository maintainers can adjust the OpenSCAP profile or accept the baseline.

   **Option B: Fix applies to repository configuration**
   
   If the failure relates to repository security configuration (e.g., workflow permissions, secret handling), fix it:
   
   ```bash
   # Example: If OpenSCAP flags overly permissive workflow permissions
   # Edit .github/workflows/*.yml to use minimal permissions
   permissions:
     contents: read
     security-events: write
   ```

   **Option C: Fix applies to container/application security**
   
   If the failure relates to your application's runtime security:
   
   ```bash
   # Example: If OpenSCAP flags weak crypto settings
   # Update application configuration or Dockerfile
   ```

5. **Note on CI runner baseline failures:**
   
   If your PR introduces no security-relevant changes but OpenSCAP still blocks:
   - This may indicate a pre-existing baseline issue
   - Maintainers should review if the profile is appropriate for CI runners
   - Consider excluding non-applicable rules or documenting accepted risks

6. **Testing locally:**
   
   You cannot easily replicate the exact CI runner environment locally. Instead:
   - Review the HTML report to understand the failure
   - Fix issues in your repository files (workflows, Dockerfiles, configs)
   - Push changes and let CI re-run the OpenSCAP scan

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

**When:** Every Saturday at 9:00 AM America/Phoenix (currently ~5:00 PM UTC during standard time)

**Who:** Kevin (security lead) + automated weekly CodeQL scan

**Process:**
1. **Automated scan:** Weekly CodeQL scan runs Saturday morning (currently ~5:00 PM UTC during standard time / 9:00 AM America/Phoenix)
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

⚠️ **Action required (admin only):** Once the advanced CodeQL workflow (`.github/workflows/codeql.yml`) is merged, disable GitHub's default setup to prevent upload conflicts:

1. Go to **Settings → Security and quality → Advanced Security**
2. Under **Code scanning**, find "CodeQL analysis"
3. If "Default" is enabled, click the **⋮** menu and select **Disable CodeQL**

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
- ✅ Require status checks to pass before merging
  - ✅ Require branches to be up to date before merging
  - **Required checks:**
    - `ci-test` (from ci-cd.yml on push to branches)
    - `pr-test` (from pr-test.yml on pull requests)
    - `Analyze (javascript-typescript)` (from codeql.yml)
    - `Analyze (python)` (from codeql.yml)
    - `openscap-scan` (from openscap-compliance.yml)
- ✅ **Require code scanning results** (GitHub native enforcement):
  - Tools: All tools
  - Security alerts: High or higher
  - This blocks PRs with unresolved HIGH/CRITICAL CodeQL alerts
- ✅ Require conversation resolution before merging
- ✅ Block force pushes
- ✅ Restrict deletions

**Note:** Do NOT enable "Require review from code owners" in a solo-maintainer repository (you cannot self-approve).

**Alternative: Branch Protection Rules (legacy)**

If using legacy branch protection instead of rulesets:

**Settings → Branches → Branch protection rules → Add rule**

Branch name pattern: `main` (repeat for `dev`, `qa`)

- ✅ Require a pull request before merging (1 approval)
- ✅ Require status checks to pass before merging
  - ✅ Require branches to be up to date
  - **Status checks:**
    - `ci-test` (or `pr-test` depending on which applies)
    - `Analyze (javascript-typescript)`
    - `Analyze (python)`
    - `openscap-scan`
- ✅ Require conversation resolution
- ✅ Include administrators (recommended)
- ✅ Restrict who can push (maintainers only)

**Note:** Legacy branch protection does not support GitHub's native 'Require code scanning results' rule. Consider using rulesets for full code scanning enforcement.

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

- [ ] Merge the security gate fix PR
- [ ] Disable GitHub default CodeQL setup (Settings → Security and quality → Advanced Security → CodeQL analysis → ⋮ menu → Disable CodeQL)
- [ ] Create branch protection ruleset `main-security-gate` targeting `main`, `dev`, `qa`
  - [ ] Require pull request reviews (1 approval; do NOT enable code owners requirement in solo-maintainer repo)
  - [ ] Require status checks: `ci-test`, `pr-test`, `Analyze (javascript-typescript)`, `Analyze (python)`, `openscap-scan`
  - [ ] Require code scanning results: High or higher (native GitHub enforcement)
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
