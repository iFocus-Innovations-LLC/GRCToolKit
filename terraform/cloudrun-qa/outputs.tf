output "cloudrun_service_url" {
  description = "Cloud Run service URL (requires IAP authentication)"
  value       = google_cloud_run_v2_service.grc_toolkit_qa.uri
}

output "cloudrun_service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.grc_toolkit_qa.name
}

output "runtime_service_account" {
  description = "Runtime service account email"
  value       = google_service_account.cloudrun_runtime.email
}

output "deployer_service_account" {
  description = "Deployer service account email (for GitHub Actions)"
  value       = google_service_account.cloudrun_deployer.email
}

output "workload_identity_provider" {
  description = "Workload Identity Provider resource name (for GitHub Actions secret WORKLOAD_IDENTITY_PROVIDER)"
  value       = google_iam_workload_identity_pool_provider.github.name
  sensitive   = true
}

output "secret_manager_secret" {
  description = "Secret Manager secret name for Gemini API key"
  value       = google_secret_manager_secret.gemini_api_key.id
}

output "budget_name" {
  description = "Billing budget name"
  value       = google_billing_budget.cloudrun_qa_budget.name
}

output "setup_instructions" {
  description = "Next steps after Terraform apply"
  value       = <<-EOT
    
    ✅ Cloud Run QA infrastructure created!
    
    Next steps:
    1. Add Gemini API key to Secret Manager:
       echo -n "YOUR_GEMINI_API_KEY" | gcloud secrets versions add ${google_secret_manager_secret.gemini_api_key.secret_id} --data-file=- --project=${var.project_id}
    
    2. Add GitHub Actions secrets (Settings → Secrets and variables → Actions):
       - WORKLOAD_IDENTITY_PROVIDER: Run `terraform output -raw workload_identity_provider` to get this value
       - GCP_SA_EMAIL: ${google_service_account.cloudrun_deployer.email}
       - GCP_PROJECT_ID: ${var.project_id}
    
    3. Add GitHub Actions variable:
       - ENABLE_CLOUD_RUN_DEPLOY: true
       - ENABLE_GCP_GAR_DEPLOY: true (if not already set)
    
    4. Push to main branch to trigger deployment
    
    5. Enable IAP on the Cloud Run service (one-time, idempotent):
       gcloud run services update grc-toolkit-qa --region=${var.region} --iap --project=${var.project_id}
    
    6. Access the service:
       ${google_cloud_run_v2_service.grc_toolkit_qa.uri}
       (Requires IAP authentication with allowed user/group)
    
    See docs/CLOUD-RUN-QA.md for full instructions.
  EOT
}
