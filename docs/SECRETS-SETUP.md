# Secrets Setup Guide

Zero-trust secrets management for GRC Toolkit. **Never commit API keys, tokens, or passwords.**

## Required Secrets by Environment

| Secret / variable | Used By | Purpose |
|--------|---------|---------|
| **GEMINI_API_KEY** | App (Docker, K8s) | Gemini AI API for GRC recommendations |
| **DOCKER_SCOUT_TOKEN** | GitHub Actions | Docker image vulnerability scanning (optional) |
| **GCP_PROJECT_ID** | GitHub Actions, scripts | GCP project identifier |
| **WORKLOAD_IDENTITY_PROVIDER** | GitHub Actions | WIF provider resource name for OIDC federation |
| **GCP_SA_EMAIL** | GitHub Actions | GCP service account that GitHub impersonates via WIF |
| **GKE_CLUSTER_NAME** | GitHub Actions | GKE cluster name for deploy |
| **ANTHROPIC_API_KEY** | nist-validator skill | Anthropic API (optional) |
| **Firebase config** | grctoolkit.html | Firebase (optional, for future features) |

Prefer **Workload Identity Federation (OIDC)** for Actions so you do **not** store long‑lived `GCP_SA_KEY` JSON keys in GitHub. Legacy setups may still reference `GCP_SA_KEY`; migrate to WIF when possible (see [`.github/workflows/ci-cd.yml`](../.github/workflows/ci-cd.yml)).

---

## 1. GitHub Actions Secrets

Add these in **Settings → Secrets and variables → Actions**:

| Name | Kind | How to create |
|------|------|---------------|
| `DOCKER_SCOUT_TOKEN` | Secret | [Docker Scout](https://scout.docker.com/) → Account → Access Tokens (optional) |
| `GCP_PROJECT_ID` | Secret | Your GCP project ID |
| `WORKLOAD_IDENTITY_PROVIDER` | Secret | Full provider resource string from GCP WIF (see Google doc [Workload Identity Federation with GitHub](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-providers)) |
| `GCP_SA_EMAIL` | Secret | Deploy SA email (e.g. `grc-deploy@YOUR_PROJECT_ID.iam.gserviceaccount.com`) |
| `GKE_CLUSTER_NAME` | Secret | Your GKE cluster name (e.g. `grc-toolkit-cluster`) |

The Actions workflow authenticates via `google-github-actions/auth@v3` using **`workload_identity_provider`** + **`service_account`** (matches `GCP_SA_EMAIL`). Ensure the workflow **`permissions`** include **`id-token: write`** for OIDC.

### GCP Service Account Permissions

**Workload Identity Federation does not replace this service account** — Actions still obtains credentials **as** that SA; WIF only removes the need for a downloaded **JSON key** in GitHub (`GCP_SA_KEY`).

The impersonated GCP service account needs:

- `roles/artifactregistry.writer` (push images)
- `roles/container.developer` (deploy to GKE)
- `roles/secretmanager.secretAccessor` (if using Secret Manager sync)

---

## 2. Local Development

### Option A: Environment Variable

```bash
export GEMINI_API_KEY="your-gemini-api-key"
docker run -p 8080:8080 -e GEMINI_API_KEY=$GEMINI_API_KEY grc-toolkit
```

**If the app shows `API error: 400 - API key expired`:** Google uses that wording for several failures—not only clock expiry. Typical causes: key deleted or rotated in [Google AI Studio](https://aistudio.google.com/); API key **restrictions** in GCP (Credentials) blocking **Generative Language API** or the wrong **HTTP referrer** (browser vs `file://`); or the page still has an **old embedded key** (restart `./scripts/run-local.sh` or the container, then hard-refresh). Verify the value the browser uses: DevTools → Console → `window.GEMINI_API_KEY` (check length/prefix only; do not paste the full key into chat).

### Option B: Kubernetes Secret (for K8s deploy)

```bash
./scripts/update-secret.sh "YOUR_GEMINI_API_KEY"
./scripts/deploy.sh staging
```

---

## 3. GCP Secret Manager (Recommended for Production)

### Create the secret in GCP

```bash
# Enable Secret Manager API
gcloud services enable secretmanager.googleapis.com --project=$GCP_PROJECT_ID

# Create secret (paste key when prompted, or use file)
echo -n "YOUR_GEMINI_API_KEY" | gcloud secrets create gemini-api-key \
  --data-file=- \
  --project=$GCP_PROJECT_ID
```

### Sync to Kubernetes

```bash
export GCP_PROJECT_ID="YOUR_REAL_PROJECT_ID"
./scripts/sync-secret-from-gcp.sh gemini-api-key
./scripts/deploy.sh staging
```

---

## 4. First-Time Repo Setup

If `k8s/secret.yaml` was previously committed with a real key:

1. **Rotate the key** in [Google AI Studio](https://aistudio.google.com/apikey) – the old key is compromised.
2. **Remove from git tracking** (keeps file locally, stops tracking):
   ```bash
   git rm --cached k8s/secret.yaml
   git commit -m "chore: stop tracking k8s/secret.yaml"
   ```
3. **Create new secret** using one of the methods above.

---

## 5. Skills (nist-validator)

The `nist-control-validator` skill expects these in GCP Secret Manager:

| Secret Ref | Env Var | Purpose |
|------------|---------|---------|
| `anthropic-api-key` | ANTHROPIC_API_KEY | Anthropic API |
| `grc-api-key` | CLOUD_API_KEY | Cloud/Gemini API |
| `firebase-service-account` | GCP_SERVICE_ACCOUNT_KEY | Firebase SA JSON |

Create in GCP:

```bash
echo -n "YOUR_ANTHROPIC_KEY" | gcloud secrets create anthropic-api-key --data-file=-
echo -n "YOUR_GEMINI_KEY" | gcloud secrets create grc-api-key --data-file=-
```

---

## 6. Verification

```bash
# Kubernetes
kubectl get secret grc-toolkit-secrets -n grc-toolkit

# GCP Secret Manager
gcloud secrets list --project=$GCP_PROJECT_ID
```

---

## Reference

- [GCP Secret Manager](https://cloud.google.com/secret-manager)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
