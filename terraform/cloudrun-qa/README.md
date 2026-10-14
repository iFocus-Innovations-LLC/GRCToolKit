# Cloud Run QA Infrastructure

Terraform configuration for GRCToolKit Cloud Run QA environment with Identity-Aware Proxy (IAP).

## What This Creates

- **Secret Manager**: Empty secret for Gemini API key (value added manually)
- **Service Accounts**:
  - `cloudrun-runtime-sa`: Runs the Cloud Run container (minimal privileges)
  - `cloudrun-deployer-sa`: Used by GitHub Actions via Workload Identity Federation
- **Workload Identity Federation**: OIDC pool + provider for GitHub Actions authentication
- **Cloud Run Service**: `grc-toolkit-qa` with 0-2 instances, 512Mi memory, IAP-protected
- **IAP Configuration**: OAuth brand, client, and user allowlist
- **Billing Budget**: $5/month cap with alerts at 50%, 90%, 100%

## Quick Start

See [docs/CLOUD-RUN-QA.md](../../docs/CLOUD-RUN-QA.md) for full setup instructions.

```bash
# 1. Copy example config
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit with your values

# 2. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 3. Follow output instructions to:
#    - Add Gemini API key to Secret Manager
#    - Configure GitHub Actions secrets
#    - Enable Cloud Run deployment
```

## Required Variables

See `terraform.tfvars.example` for all variables. Key settings:

- `project_id`: GCP project ID
- `github_repo`: `"iFocus-Innovations-LLC/GRCToolKit"` (or your fork)
- `iap_allowed_users`: List of `user:email` or `group:group@domain` entries
- `billing_account_id`: For budget alerts

## Outputs

- `cloudrun_service_url`: IAP-protected service URL
- `workload_identity_provider`: For GitHub Actions secret
- `deployer_service_account`: For GitHub Actions secret
- `setup_instructions`: Next steps after `terraform apply`

## Cost

~$1-5/month with configured budget. See [docs/CLOUD-RUN-QA.md](../../docs/CLOUD-RUN-QA.md#cost-expectations).

## Limitations

- **IAP Brand**: Cannot be deleted (GCP limitation), only deactivated
- **Single Region**: Cloud Run service in one region (default: us-central1)
- **No State Backend**: Local state file (consider [GCS backend](https://developer.hashicorp.com/terraform/language/backend/gcs) for team use)

## Updating

```bash
# Add/remove users in terraform.tfvars
nano terraform.tfvars

# Apply changes
terraform plan
terraform apply
```

## Teardown

```bash
terraform destroy

# Manually delete secret data (not deleted by Terraform)
gcloud secrets delete gemini-api-key --project=YOUR_PROJECT_ID
```
