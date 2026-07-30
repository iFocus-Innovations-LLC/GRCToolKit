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
| Open source AI | Gemini BYOK; HITL; no silent auto-remediation; secrets via env/Secret Manager | Multi-model evaluation deferred (PM-TODO P6) |

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
