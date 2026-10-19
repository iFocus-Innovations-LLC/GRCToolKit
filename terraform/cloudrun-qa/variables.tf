variable "project_id" {
  description = "GCP project ID for Cloud Run QA environment"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run service"
  type        = string
  default     = "us-central1"
}

variable "github_repo" {
  description = "GitHub repository in format 'owner/repo' for WIF authentication"
  type        = string
  # Example: "iFocus-Innovations-LLC/GRCToolKit"
}

variable "iap_allowed_users" {
  description = "List of users/groups allowed to access via IAP (format: user:email@example.com or group:group@example.com)"
  type        = list(string)
  # Example: ["user:admin@grctoolkit.ai", "group:qa-team@grctoolkit.ai"]
}

variable "billing_account_id" {
  description = "Billing account ID (format: 012345-ABCDEF-678901) for budget alerts"
  type        = string
}

variable "budget_alert_emails" {
  description = "List of email addresses to receive budget alert notifications (optional)"
  type        = list(string)
  default     = null
}

variable "bootstrap_image" {
  description = "Placeholder image for initial Terraform apply (replaced by CI after first push). Use a public image that exists."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the Cloud Run service via Terraform. Set to false to allow `terraform destroy`."
  type        = bool
  default     = true
}
