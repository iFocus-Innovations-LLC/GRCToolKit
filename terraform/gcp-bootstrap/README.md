# GCP bootstrap (Terraform)

Creates Artifact Registry and enables APIs. **Do not commit `project_id`** — pass it from your secret store or from Secret Manager.

## Prerequisites (sys admin)

- **Project**: A GCP project ID and **billing** enabled.
- **Who runs Terraform**: Your user (`gcloud auth application-default login`) or a **service account** whose key JSON is used via `GOOGLE_APPLICATION_CREDENTIALS`.
- **IAM (least privilege for this module)** on that project:
  - `roles/serviceusage.serviceUsageAdmin` — enable APIs
  - `roles/artifactregistry.admin` — create the Docker repository  
  Broader roles such as **Editor** or **Owner** also work for small dev tenants.
- **Not created here**: GKE clusters, VPC/firewalls, or workload identities. After `apply`, create a dev cluster (Console or `gcloud`) and install with Helm per [`docs/HELM-TERRAFORM.md`](../../docs/HELM-TERRAFORM.md).

## Variables

| Input | Sensitive | How to set |
|-------|-----------|------------|
| `project_id` | yes | `TF_VAR_project_id`, gitignored `terraform.tfvars`, or `load-vars-from-secret.sh` |
| `region` | no | default `us-central1` |
| `repository_id` | no | default `grc-toolkit` |

## Option A — CI / deployment secrets (GitHub Actions, etc.)

Store `GCP_PROJECT_ID` (or equivalent) in your platform’s secret store, then:

```yaml
env:
  TF_VAR_project_id: ${{ secrets.GCP_PROJECT_ID }}
```

```bash
terraform plan
terraform apply
```

## Option B — Google Secret Manager

1. Create a secret (same project you bootstrap, or a dedicated “org config” project):

   ```bash
   echo '{"project_id":"YOUR_PROJECT_ID","region":"us-central1","repository_id":"grc-toolkit"}' | \
     gcloud secrets create grc-toolkit-terraform-bootstrap --data-file=- --project=YOUR_PROJECT_ID
   ```

2. Before `terraform plan` / `apply`:

   ```bash
   cd terraform/gcp-bootstrap
   source ./load-vars-from-secret.sh
   terraform init
   terraform apply
   ```

   Override secret name or project:

   ```bash
   export GCP_BOOTSTRAP_SECRET_NAME=my-bootstrap-config
   export GCP_BOOTSTRAP_LOOKUP_PROJECT=my-org-config-project
   source ./load-vars-from-secret.sh
   ```

## Option C — Local only

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars (file is gitignored)
terraform apply
```

## Files

- `terraform.tfvars.example` — documentation only (no real IDs).
- `load-vars-from-secret.sh` — exports `TF_VAR_*` from GSM JSON.
