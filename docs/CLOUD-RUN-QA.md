# Cloud Run QA Environment

Cheap, IAM-gated QA/demo environment for GRCToolKit on Google Cloud Run. Access from anywhere with Identity-Aware Proxy (IAP) authentication.

## Architecture

- **Platform**: Google Cloud Run (serverless, scales to zero)
- **Security**: Identity-Aware Proxy (IAP) with Google account allowlist (automatically enabled via IAM bindings)
- **Secrets**: GCP Secret Manager (Gemini API key never reaches browser)
- **Cost**: ~$0-5/month with the configured budget ($5 cap with alerts at 50%, 90%, 100%)
- **Deployment**: Automated via GitHub Actions on push to `main`

The container runs both nginx (static UI on port 8080) and a Python LLM proxy server (port 8081, proxied via `/api/llm/`). API keys stay server-side; the browser never sees them.

## Prerequisites

- GCP project with billing enabled
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) installed and authenticated
- Terraform >= 1.9.0 (Homebrew's default terraform is stuck at 1.5.7; install from `hashicorp/tap` instead: `brew tap hashicorp/tap && brew install hashicorp/tap/terraform`)
- GitHub repository admin access (for secrets/variables)
- Google account(s) for IAP allowlist

## One-Time Setup

### 1. Terraform Infrastructure

```bash
cd terraform/cloudrun-qa

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values:
# - project_id: Your GCP project ID
# - github_repo: "iFocus-Innovations-LLC/GRCToolKit" (or your fork)
# - iap_allowed_users: List of user:email@example.com or group:group@example.com
# - billing_account_id: Find via `gcloud billing accounts list`
# - budget_alert_emails: List of emails for budget alerts
nano terraform.tfvars

# Initialize and apply
terraform init
terraform plan
terraform apply

# Save the outputs (needed for GitHub Actions)
terraform output -raw workload_identity_provider > wif-provider.txt
terraform output -raw deployer_service_account > deployer-sa.txt
```

### 2. Add Gemini API Key to Secret Manager

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

### 3. Configure GitHub Actions

Add these secrets in **Settings → Secrets and variables → Actions → Secrets**:

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

### 4. Deploy

Push to `main` branch to trigger the first deployment:

```bash
git push origin main
```

Monitor the deployment in **Actions** tab. Once complete, the Cloud Run service URL is in the workflow logs.

### 5. Access the Service

The service URL is shown in `terraform output cloudrun_service_url` or the GitHub Actions logs.

```bash
# Open in browser (requires IAP authentication)
gcloud run services describe grc-toolkit-qa \
  --region=us-central1 \
  --project=$GCP_PROJECT_ID \
  --format='value(status.url)'
```

Only users/groups in `iap_allowed_users` can access. First visit triggers Google OAuth consent.

## Managing IAP Access

### Add Users

Edit `terraform/cloudrun-qa/terraform.tfvars`:

```hcl
iap_allowed_users = [
  "user:admin@grctoolkit.ai",
  "user:new-user@example.com",          # Add individual users
  "group:qa-team@grctoolkit.ai",        # Or entire Google Groups
]
```

Apply changes:

```bash
cd terraform/cloudrun-qa
terraform plan
terraform apply
```

### Remove Users

Remove the user/group from `iap_allowed_users` and run `terraform apply`.

### Temporary Access via gcloud

For quick testing, grant IAP access directly (bypasses Terraform):

```bash
gcloud iap web add-iam-policy-binding \
  --resource-type=cloud-run \
  --service=grc-toolkit-qa \
  --region=us-central1 \
  --project=$GCP_PROJECT_ID \
  --member='user:tester@example.com' \
  --role='roles/iap.httpsResourceAccessor'
```

**Note**: Manual IAM changes will be overwritten on next `terraform apply`.

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
| **Total** | **~$1-5/month** |

- Budget configured: $5/month with alerts at 50%, 90%, 100%
- Scales to zero when idle (no requests = no cost)
- Each request ~$0.00002 (100,000 requests ≈ $2)

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

Budget alerts are sent to `budget_alert_emails` (configured in Terraform) at 50%, 90%, and 100% of $5 threshold.

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
3. Ensure IAP is enabled:
   ```bash
   gcloud iap web enable \
     --resource-type=cloud-run \
     --service=grc-toolkit-qa \
     --region=us-central1 \
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
# Destroy Terraform resources
cd terraform/cloudrun-qa
terraform destroy

# Manually delete secret versions (Terraform doesn't delete secret data)
gcloud secrets delete gemini-api-key --project=$GCP_PROJECT_ID

# Remove GitHub secrets/variables (manual in Settings UI)
```

## Security Notes

1. **API keys never reach the browser**: The Python proxy at `/api/llm/analyze` handles all LLM requests server-side
2. **IAP enforces authentication**: All requests must authenticate via Google OAuth before reaching the service
3. **Least privilege**: Runtime SA only has `secretmanager.secretAccessor` for the Gemini key
4. **No public access**: `--no-allow-unauthenticated` flag prevents anonymous requests
5. **Budget protection**: $5 cap with alerts prevents runaway costs

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
