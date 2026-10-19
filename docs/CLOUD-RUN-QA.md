# Cloud Run QA Environment

Cheap, IAM-gated QA/demo environment for GRCToolKit on Google Cloud Run. Access from anywhere with Identity-Aware Proxy (IAP) authentication.

## Architecture

- **Platform**: Google Cloud Run (serverless, scales to zero)
- **Security**: Identity-Aware Proxy (IAP) with Google account allowlist
- **Secrets**: GCP Secret Manager (Gemini API key never reaches browser)
- **Cost**: ~$0-20/month with the configured budget ($20 cap with alerts at 50%, 90%, 100%)
- **Deployment**: Automated via GitHub Actions on push to `main`

The container runs both nginx (static UI on port 8080) and a Python LLM proxy server (port 8081, proxied via `/api/llm/`). API keys stay server-side; the browser never sees them.

## Prerequisites

- GCP project with billing enabled
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) installed and authenticated
- Terraform >= 1.9.0
- GitHub repository admin access (for secrets/variables)
- Google account(s) or Google Group(s) for IAP allowlist (recommended: use a Google Group for easier access management)

## One-Time Setup

### 1. Bootstrap Artifact Registry (One-Time)

First, create the Artifact Registry repository that will hold the Docker images:

```bash
cd terraform/gcp-bootstrap

# Copy example config if needed
cp terraform.tfvars.example terraform.tfvars || true

# Edit terraform.tfvars with your values
nano terraform.tfvars

# Apply bootstrap (creates Artifact Registry repository)
terraform init
terraform plan
terraform apply
```

### 2. Cloud Run QA Infrastructure

```bash
cd ../cloudrun-qa

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values:
# - project_id: Your GCP project ID
# - github_repo: "iFocus-Innovations-LLC/GRCToolKit" (or your fork)
# - iap_allowed_users: ["group:qa-team@yourdomain.com"] (recommended) or ["user:admin@yourdomain.com"]
# - billing_account_id: Find via `gcloud billing accounts list`
# - budget_alert_emails: ["alerts@yourdomain.com"]
# - deletion_protection: true (default; set false only when running `terraform destroy`)
# - bootstrap_image: (optional) defaults to a public Cloud Run hello-world image
nano terraform.tfvars

# Initialize Terraform
terraform init

# First apply: Creates infrastructure with bootstrap placeholder image
# The secret is created empty; you'll add the API key in the next step
terraform plan
terraform apply

# Save the outputs (needed for GitHub Actions)
terraform output -raw workload_identity_provider > wif-provider.txt
terraform output -raw deployer_service_account > deployer-sa.txt
```

**Note on first apply**: Terraform uses a bootstrap placeholder image (`bootstrap_image` variable, defaults to `us-docker.pkg.dev/cloudrun/container/hello`) because `grc-toolkit:latest` doesn't exist until CI runs. After the first GitHub Actions push builds and deploys the real image, Terraform ignores image changes (lifecycle `ignore_changes`).

**Note on deletion_protection**: The Cloud Run service has `deletion_protection = true` by default to prevent accidental deletion. To destroy the infrastructure, set `deletion_protection = false` in `terraform.tfvars` first, then run `terraform apply` followed by `terraform destroy`.

### 3. Add Gemini API Key to Secret Manager

The Terraform created an empty secret. Add your Gemini API key:

```bash
# Set your project ID
export GCP_PROJECT_ID="your-project-id"

# Add the API key (secure input, not echoed)
read -rs GEMINI_API_KEY
echo -n "$GEMINI_API_KEY" | gcloud secrets versions add gemini-api-key \
  --data-file=- \
  --project=$GCP_PROJECT_ID

# Verify (doesn't show the value)
gcloud secrets versions list gemini-api-key --project=$GCP_PROJECT_ID
```

Get a Gemini API key from [Google AI Studio](https://aistudio.google.com/apikey).

**Important**: The Cloud Run service expects secret version `1` to exist. The placeholder bootstrap image may not start successfully until you add this version. After adding the secret, either wait for CI to deploy the real image, or manually update the service once.

### 4. Configure GitHub Actions

Add these **GitHub Actions secrets** in **Settings → Secrets and variables → Actions → Secrets**:

| Secret Name | Value | Where to find |
|-------------|-------|---------------|
| `WORKLOAD_IDENTITY_PROVIDER` | From `terraform output -raw workload_identity_provider` | Full resource path like `projects/123.../providers/github-provider` |
| `GCP_SA_EMAIL` | From `terraform output deployer_service_account` | Email like `cloudrun-deployer-sa@PROJECT_ID.iam.gserviceaccount.com` |
| `GCP_PROJECT_ID` | Your GCP project ID | Same as in terraform.tfvars |

Add these **Repository variables** in **Settings → Secrets and variables → Actions → Variables**:

| Variable Name | Value |
|---------------|-------|
| `ENABLE_CLOUD_RUN_DEPLOY` | `true` |
| `ENABLE_GCP_GAR_DEPLOY` | `true` (if not already set) |

**Important**: Ensure you have `gcloud auth application-default set-quota-project $GCP_PROJECT_ID` configured locally if you hit quota errors during testing.

### 5. Deploy

Push to `main` branch to trigger the first deployment:

```bash
git push origin main
```

Monitor the deployment in the **Actions** tab. Once complete, the Cloud Run service URL is in the workflow logs.

**Alternatively**, you can manually trigger the deploy job from the **Actions** tab using the **workflow_dispatch** trigger (useful for testing or re-deploying without pushing new code).

### 6. Enable IAP on Cloud Run

After the first deployment, enable IAP on the Cloud Run service. This is a **one-time manual step** via the GCP Console:

#### For Projects NOT in a Google Workspace Organization

1. Go to [Cloud Console → Cloud Run](https://console.cloud.google.com/run)
2. Click on the `grc-toolkit-qa` service
3. Click the **Security** tab
4. Under **Authentication**, click **Enable Identity-Aware Proxy**
5. When prompted to configure OAuth consent screen:
   - Choose **External** (since you're not in a Workspace org)
   - Fill in required fields (App name, User support email, Developer contact)
   - Add your domain to **Authorized domains** if prompted
   - Save the consent screen
6. IAP will auto-generate OAuth credentials for you
7. IAP is now enabled

**Note**: Without a Workspace organization, you must use the Console. The `gcloud` command path requires pre-existing OAuth brand/client setup, which was the stale documentation removed in PR #80.

#### For Projects in a Google Workspace Organization

If your project is part of a Workspace org, you can use `gcloud`:

```bash
# Set your project ID and region
export GCP_PROJECT_ID="your-project-id"
export REGION="us-central1"

# Enable IAP on the Cloud Run service
gcloud run services update grc-toolkit-qa \
  --region=$REGION \
  --iap \
  --project=$GCP_PROJECT_ID
```

**Note**: The GitHub Actions workflow runs this command on each deployment to ensure IAP remains enabled, but the **initial OAuth consent screen setup must be done manually** in the Console (one-time).

### 7. Access the Service

The service URL is shown in `terraform output cloudrun_service_url` or the GitHub Actions logs.

```bash
# Get the service URL
gcloud run services describe grc-toolkit-qa \
  --region=us-central1 \
  --project=$GCP_PROJECT_ID \
  --format='value(status.url)'
```

Open the URL in a browser. Only users/groups in `iap_allowed_users` (configured in Terraform) can access. First visit triggers Google OAuth consent.

## Managing IAP Access

### Add Users (Recommended: Use Google Groups)

**Best practice**: Use a Google Group for easier access management:

```hcl
iap_allowed_users = [
  "group:qa-team@yourdomain.com",  # Recommended: manage members in Google Groups
]
```

**Individual users** (less flexible):

```hcl
iap_allowed_users = [
  "user:admin@yourdomain.com",
  "user:qa-tester@yourdomain.com",
]
```

Apply changes:

```bash
cd terraform/cloudrun-qa
terraform plan
terraform apply
```

### Remove Users

Remove the user/group from `iap_allowed_users` in `terraform.tfvars` and run `terraform apply`.

### Temporary Access via gcloud

For quick testing, grant IAP access directly (bypasses Terraform, but will be **overwritten** on next `terraform apply`):

```bash
gcloud iap web add-iam-policy-binding \
  --resource-type=cloud-run \
  --service=grc-toolkit-qa \
  --region=us-central1 \
  --project=$GCP_PROJECT_ID \
  --member='user:tester@example.com' \
  --role='roles/iap.httpsResourceAccessor'
```

## Rotating the Gemini API Key

```bash
# Add new version (doesn't delete old versions)
read -rs GEMINI_API_KEY
echo -n "$GEMINI_API_KEY" | gcloud secrets versions add gemini-api-key \
  --data-file=- \
  --project=$GCP_PROJECT_ID

# Cloud Run automatically uses "latest" version
# Force immediate pickup (or wait for next deploy):
gcloud run services update grc-toolkit-qa \
  --region=us-central1 \
  --project=$GCP_PROJECT_ID
```

## Cost Expectations

**Monthly estimate** (low usage, QA/demo workload):

| Component | Cost |
|-----------|------|
| Cloud Run (0-2 instances, ~1h/day active) | ~$1-3 |
| Secret Manager (1 secret, <10 accesses/day) | ~$0.10 |
| Gemini API calls (~100-500 requests/month) | ~$5-15 |
| **Total** | **~$6-18/month** |

- Budget configured: $20/month (project-wide) with alerts at 50%, 90%, 100%
- Cloud Run scales to zero when idle (no requests = no compute cost)
- Each Cloud Run request ~$0.00002 (100,000 requests ≈ $2)
- **Note**: Gemini API spend lives on the API key's project, not the Cloud Run billing service

**Cost spikes** to avoid:
- Leaving `--min-instances=1` (charges 24/7, ~$15/month)
- Public access without IAP (bot traffic)
- Large images or long timeouts

## Custom Domain with IAP

Cloud Run provides a default URL like `https://grc-toolkit-qa-HASH-uc.a.run.app`. To use `grctoolkit.ai` or a subdomain:

### Option 1: Cloud Run Domain Mapping (Simple, IAP Compatible)

**Pros**: Simplest setup, works with IAP, no extra cost
**Cons**: Only supports Cloud Run services, limited to one region

```bash
# Verify domain ownership in Google Search Console first
gcloud domains verify grctoolkit.ai

# Map domain (or subdomain like qa.grctoolkit.ai)
gcloud run domain-mappings create \
  --service=grc-toolkit-qa \
  --domain=qa.grctoolkit.ai \
  --region=us-central1 \
  --project=$GCP_PROJECT_ID

# Add DNS records shown in output (A and AAAA records)
```

IAP continues to work. **Cost**: $0/month

**Documentation**: [Cloud Run Custom Domains](https://cloud.google.com/run/docs/mapping-custom-domains)

### Option 2: Global HTTPS Load Balancer + Serverless NEG + IAP (Advanced)

**Pros**: Multi-region, more routing options, global anycast IP
**Cons**: More complex, additional cost

**Architecture**:
1. Global external HTTPS load balancer
2. Serverless Network Endpoint Group (NEG) pointing to Cloud Run
3. IAP enabled on backend service (not the Cloud Run service)
4. SSL certificate for custom domain

**Cost**: ~$18-25/month
- Load balancer forwarding rules: ~$18/month (fixed)
- Egress and request charges: ~$1-7/month (usage)

**Setup**: See [IAP for External HTTPS Load Balancers](https://cloud.google.com/iap/docs/enabling-cloud-run) (complex, not shown here).

**Recommendation**: Use **Option 1 (Cloud Run domain mapping)** unless you need multi-region or complex routing. It's the cheapest supported option and keeps IAP enforcement.

## Infrastructure Ownership: Terraform vs CI

**Terraform owns** (initial setup, manual changes via `terraform apply`):
- Service account configuration
- IAP access control (`iap_allowed_users`)
- Budget and monitoring
- Secret creation (but CI manages secret access)

**CI/CD owns** (updated on every `git push` to `main`):
- Container image (`:latest` tag)
- Environment variables (`LLM_PROVIDER`, `GEMINI_MODEL`)
- Scaling configuration (`min-instances`, `max-instances`, `memory`, `cpu`)
- Timeout settings
- Secret version references (`GEMINI_API_KEY=gemini-api-key:latest`)

Terraform's `lifecycle.ignore_changes` ensures CI's changes survive `terraform apply`. The workflow uses `--update-env-vars` (not `--set-env-vars`) to preserve Terraform-managed env vars like `GRC_RUNNER_TRUST_PROXY`.

## Monitoring and Logs

### View Logs

```bash
# Recent logs
gcloud run services logs read grc-toolkit-qa \
  --region=us-central1 \
  --project=$GCP_PROJECT_ID \
  --limit=50

# Live tail
gcloud run services logs tail grc-toolkit-qa \
  --region=us-central1 \
  --project=$GCP_PROJECT_ID
```

### Metrics

View in [Cloud Console](https://console.cloud.google.com/run):
- Request count, latency, error rate
- Instance count (should be 0 when idle)
- Container CPU and memory usage

### Budget Alerts

Budget alerts are sent to `budget_alert_emails` (configured in Terraform) at 50%, 90%, and 100% of the $20 threshold.

The budget is **project-wide** (not scoped to a specific Cloud Run service ID) because:
1. Gemini API spend lives on the API key's project, not the Cloud Run service
2. Cloud Run billing service IDs vary by project and are hard to discover

Check current spend:

```bash
gcloud billing budgets list \
  --billing-account=$BILLING_ACCOUNT_ID \
  --project=$GCP_PROJECT_ID
```

## Troubleshooting

### 403 Forbidden (IAP)

**Symptom**: "You don't have access to this page"

**Solutions**:
1. Verify your Google account is in `iap_allowed_users` (Terraform)
2. Check IAM permissions:
   ```bash
   gcloud iap web get-iam-policy \
     --resource-type=cloud-run \
     --service=grc-toolkit-qa \
     --region=us-central1 \
     --project=$GCP_PROJECT_ID
   ```
3. Re-enable IAP (if disabled):
   ```bash
   gcloud run services update grc-toolkit-qa \
     --region=us-central1 \
     --iap \
     --project=$GCP_PROJECT_ID
   ```

### LLM Analysis Fails

**Symptom**: "API error: 400 - API key expired" or similar

**Solutions**:
1. Verify secret exists and has a version:
   ```bash
   gcloud secrets versions list gemini-api-key --project=$GCP_PROJECT_ID
   ```
2. Check runtime SA has access:
   ```bash
   gcloud secrets get-iam-policy gemini-api-key --project=$GCP_PROJECT_ID
   ```
3. Check Cloud Run service logs for secret mount errors:
   ```bash
   gcloud run services logs read grc-toolkit-qa \
     --region=us-central1 \
     --project=$GCP_PROJECT_ID \
     --limit=50 | grep -i secret
   ```
4. Verify the API key is valid in [Google AI Studio](https://aistudio.google.com/apikey)

### Container Startup Fails

**Symptom**: Service shows as "Revision failed" in Cloud Console

**Solutions**:
1. Check deployment logs in GitHub Actions
2. View Cloud Run logs for startup errors:
   ```bash
   gcloud run services logs read grc-toolkit-qa \
     --region=us-central1 \
     --project=$GCP_PROJECT_ID \
     --limit=100
   ```
3. Verify image was pushed to Artifact Registry:
   ```bash
   gcloud artifacts docker images list \
     us-central1-docker.pkg.dev/$GCP_PROJECT_ID/grc-toolkit/grc-toolkit \
     --project=$GCP_PROJECT_ID
   ```

### GitHub Actions Deployment Fails

**Symptom**: `deploy-cloudrun` job fails

**Solutions**:
1. Verify GitHub secrets are set correctly (especially `WORKLOAD_IDENTITY_PROVIDER`)
2. Check deployer SA has required roles:
   ```bash
   gcloud projects get-iam-policy $GCP_PROJECT_ID \
     --flatten="bindings[].members" \
     --filter="bindings.members:serviceAccount:cloudrun-deployer-sa@$GCP_PROJECT_ID.iam.gserviceaccount.com"
   ```
3. Verify Workload Identity Federation is configured:
   ```bash
   gcloud iam workload-identity-pools providers describe github-provider \
     --location=global \
     --workload-identity-pool=github-pool \
     --project=$GCP_PROJECT_ID
   ```

## Teardown

To completely remove the Cloud Run QA environment:

```bash
# Step 1: Disable deletion protection
cd terraform/cloudrun-qa
# Edit terraform.tfvars: set deletion_protection = false
nano terraform.tfvars

# Apply to remove deletion protection
terraform apply

# Step 2: Destroy Terraform resources
terraform destroy

# Step 3: Manually delete secret versions (Terraform doesn't delete secret data)
gcloud secrets delete gemini-api-key --project=$GCP_PROJECT_ID

# Step 4: (Optional) Destroy Artifact Registry repository
cd ../gcp-bootstrap
terraform destroy

# Step 5: Remove GitHub secrets/variables (manual in Settings UI)
```

## Security Notes

1. **API keys never reach the browser**: The Python proxy at `/api/llm/analyze` handles all LLM requests server-side
2. **Model pinning (G7)**: When using the server's Gemini key (no client `apiKey`), the server pins the model to the configured `GEMINI_MODEL` and ignores client-supplied `model` parameters. This prevents IAP-allowlisted viewers from using pricier models on the server key. BYOK (client supplies `apiKey`) honors the client's model choice.
3. **IAP enforces authentication**: All requests must authenticate via Google OAuth before reaching the service
4. **Least privilege**: Runtime SA only has `secretmanager.secretAccessor` for the Gemini key. Deployer SA has `run.admin`, `iam.serviceAccountUser`, and `artifactregistry.writer` (scoped to `grc-toolkit` repository only).
5. **No public access**: `--no-allow-unauthenticated` flag prevents anonymous requests
6. **Budget protection**: $20 cap with alerts prevents runaway costs

## Related Documentation

- [docs/SECRETS-SETUP.md](SECRETS-SETUP.md) - General secrets management
- [docs/GCP-DEPLOYMENT-CHECKLIST.md](GCP-DEPLOYMENT-CHECKLIST.md) - GKE deployment (production)
- [docs/HELM-TERRAFORM.md](HELM-TERRAFORM.md) - Helm charts for GKE
- [.github/workflows/ci-cd.yml](../.github/workflows/ci-cd.yml) - CI/CD pipeline

## References

- [Cloud Run Pricing](https://cloud.google.com/run/pricing)
- [Identity-Aware Proxy Documentation](https://cloud.google.com/iap/docs)
- [Cloud Run Custom Domains](https://cloud.google.com/run/docs/mapping-custom-domains)
- [Workload Identity Federation with GitHub](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-providers)
- [Secret Manager Pricing](https://cloud.google.com/secret-manager/pricing)
