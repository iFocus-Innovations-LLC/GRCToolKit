# GRC Toolkit - Security Implementation

## 🔐 Secure API Key Management

This document outlines the secure implementation of the GEMINI API key using Kubernetes Secrets and environment variable injection.

## 🏗️ Architecture

### Security Components

1. **Kubernetes Secret**: Stores the GEMINI API key securely
2. **Environment Variable Injection**: Runtime injection via startup script
3. **No Hardcoded Keys**: API key is never stored in source code
4. **Container Security**: Non-root user, minimal privileges

### File Structure

```
k8s/
├── secret.yaml          # Kubernetes Secret for API key
├── deployment.yaml      # Updated to mount secret as env var
└── ...

scripts/
├── update-secret.sh     # Helper script to update API key
└── deploy.sh           # Updated to apply secret

startup.sh              # Runtime injection script
Dockerfile              # Updated to use startup script
```

## 🚀 Deployment Process

### 1. Update API Key Secret

```bash
# Update the secret with your API key
./scripts/update-secret.sh "YOUR_GEMINI_API_KEY"
```

### 2. Deploy Application

```bash
# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh production
```

## 🔧 How It Works

### Runtime Injection Process

1. **Container Startup**: The `startup.sh` script runs on container initialization
2. **Environment Check**: Script checks for `GEMINI_API_KEY` environment variable
3. **HTML Injection**: Uses `sed` to replace the placeholder with the actual API key
4. **Nginx Start**: Starts nginx with the modified HTML file

### Security Features

- ✅ **No Hardcoded Keys**: API key never appears in source code
- ✅ **Kubernetes Secrets**: Secure storage using K8s native secret management
- ✅ **Runtime Injection**: Key injected only when container starts
- ✅ **Environment Variables**: Standard K8s environment variable pattern
- ✅ **Non-Root Container**: Runs as non-privileged user (UID 1001)
- ✅ **Minimal Attack Surface**: Only necessary files in container
- ✅ **Graceful Shutdown**: Proper signal handling for clean container termination
- ✅ **Temporary File Cleanup**: Automatic cleanup of sensitive files on shutdown

## 📋 Security Best Practices Implemented

### 1. Secret Management
- API key stored in Kubernetes Secret (base64 encoded)
- Secret mounted as environment variable
- No secret data in container images

### 2. Container Security
- Non-root user execution
- Minimal base image (nginx:alpine)
- Security context with dropped capabilities
- Read-only filesystem where possible

### 3. Runtime Security
- API key injected at runtime only
- No persistent storage of secrets
- Environment variable isolation

### 4. Graceful Shutdown
- Proper SIGTERM signal handling
- Clean nginx shutdown process
- Temporary file cleanup on exit
- Kubernetes termination grace period

### 5. Secure Coding Rules (Version Hygiene)
- **Pin base images and runners**: Use specific versions (e.g., `ubuntu-24.04`, `nginx:alpine`) instead of floating tags.
- **Track CVE exposure**: Run container scans on every PR and on a scheduled cadence.
- **Stay ahead of industry**: Prefer newest stable LTS/patch releases unless blocked by compatibility.
- **No unpinned dependencies**: Avoid `latest` or wildcard dependency versions in build/test tooling.

### 6. OpenSCAP Compliance Scanning

GRCToolKit uses OpenSCAP (Open Security Content Automation Protocol) to validate compliance against NIST 800-53, FedRAMP, and CMMC requirements.

**What is scanned:**
- CI/CD build environment (GitHub Actions Ubuntu 24.04 runner)
- SCAP Security Guide (SSG) CIS Level 1 Server benchmark profile
- Baseline security configuration compliance

**Why CI runner, not the container?**

The container base image (nginx:alpine-slim) uses Alpine Linux, which has limited SCAP Security Guide profile support. Alpine uses musl libc instead of glibc and the apk package manager instead of apt/yum, which are not covered by standard SSG content.

The CI runner baseline scan provides:
- **NIST 800-53 compliance evidence** for the build infrastructure
- **CIS benchmark validation** of the CI environment
- **FedRAMP/CMMC supporting evidence** showing secure build practices

Container vulnerability scanning is handled by Trivy and Docker Scout.

**Reading the OpenSCAP report:**

1. Download the `openscap-compliance-reports` artifact from a workflow run
2. Open `report.html` in a browser
3. The report shows:
   - **Overall compliance score** (% of rules passed)
   - **Rule results** (pass/fail/error/notapplicable)
   - **NIST 800-53 control mappings** (e.g., AC-3, AC-6, AU-2, IA-5, SC-8)
   - **Severity levels** (low/medium/high)
   - **Remediation guidance** for failed rules

**Key compliance controls checked:**
- **AC-3, AC-6**: Access control and least privilege
- **AU-2, AU-12**: Audit logging and record generation
- **IA-5**: Authenticator management (password policies)
- **SC-8**: Transmission confidentiality and integrity
- **CM-6**: Configuration settings

**Using reports for compliance evidence:**

The OpenSCAP reports can be used as evidence for:
- FedRAMP Low/Moderate/High authorization packages
- CMMC Level 2/3 assessments
- NIST 800-53 control validation
- SOC 2 Type II audits (supporting evidence for secure development)

The ARF (Asset Reporting Format) XML file (`results.xml`) is machine-readable and can be ingested by GRC platforms.

**Compliance baseline approach:**

The CI runner scan establishes a **secure build environment baseline**:
- Every build occurs in a known, validated environment
- Configuration drift is detected automatically
- High-severity compliance failures block merges

This approach aligns with NIST 800-171 § 3.4.1 (establish baseline configurations) and NIST 800-53 CM-2 (baseline configuration).

## 🔍 Verification

### Check Secret Status
```bash
kubectl get secret grc-toolkit-secrets -n grc-toolkit
```

### Verify API Key Injection
```bash
# Check if API key is properly injected
curl -s http://localhost:8080/ | grep -o 'window.GEMINI_API_KEY = "[^"]*"'
```

### Container Logs
```bash
docker logs <container-name>
# Should show: "✅ API key found, injecting into HTML..."
```

### Test Graceful Shutdown
```bash
# Test graceful shutdown functionality
./scripts/test-graceful-shutdown.sh

# Manual test
docker run -d -p 8080:8080 -e GEMINI_API_KEY="test-key" --name test-container grc-toolkit
docker stop test-container
docker logs test-container
# Should show graceful shutdown messages
```

### Verify CI runner pinning
```bash
# Confirm pinned runners in workflows
grep -R "runs-on: ubuntu-" .github/workflows
```

### Verify OpenSCAP compliance scan
```bash
# Download the latest OpenSCAP report artifact from GitHub Actions
# Extract and open report.html to review compliance status

# Check XCCDF results for high-severity failures
xmllint --xpath 'count(//rule-result[result="fail" and @severity="high"])' results.xml
```

## 🛡️ Security Considerations

### Production Deployment
- Use proper RBAC for secret access
- Enable network policies
- Use TLS for all communications
- Regular secret rotation

### Monitoring
- Monitor for unauthorized access attempts
- Log API key usage patterns
- Alert on secret access anomalies

---

## CISA Open Source Software security alignment

GRCToolKit aims to **align toward** [CISA Open Source Software: Security Principles and Practices](https://www.cisa.gov/resources-tools/resources/open-source-software-security-principles-and-practices) (July 2026). This is **not** a CISA certification claim.

| CISA theme | MVP posture | Gap / backlog |
|------------|-------------|----------------|
| Responsible OSS publish/consume | MIT license, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY reporting | Keep governance current on `main` |
| Secure development / CI | Non-root containers, image pin checks, Trivy/Scout, human CODEOWNERS review | No LLM-based CI reviewer in MVP (token cost) |
| Vulnerability management | Private reporting via SECURITY.md; scanner workflows on PRs | Formal response SLAs as project grows |
| SBOM | Aspirational (noted in Shields Up / robotics docs) | Generate/publish SBOM for release images (see [2026 Minimum Elements for an SBOM](https://www.cisa.gov/resources-tools/resources/2026-minimum-elements-software-bill-materials-sbom)) — PM-TODO |
| Trust assessment (C4-oriented) | Transparent repo, CODEOWNERS, HITL before remediation | Document consumer trust checklist as needed |
| Open source AI | Multi-LLM Community BYOK (Gemini default); HITL; no silent auto-remediation; secrets via env/Secret Manager | Multi-model **CI** peer review still deferred (PM-TODO P6) |

Branching and release hygiene supporting secure OSS practice: [RELEASE-BRANCHING.md](RELEASE-BRANCHING.md).

## 🔄 Secret Rotation

To rotate the API key:

1. **Update Secret**:
   ```bash
   ./scripts/update-secret.sh "NEW_API_KEY"
   ```

2. **Restart Deployment**:
   ```bash
   kubectl rollout restart deployment grc-toolkit -n grc-toolkit
   ```

## 📚 Additional Resources

- [Kubernetes Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Container Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CISA Open Source Software: Security Principles and Practices](https://www.cisa.gov/resources-tools/resources/open-source-software-security-principles-and-practices)
