variable "project_id" {
  description = "GCP project ID — supply via TF_VAR_project_id, terraform.tfvars (gitignored), or load-vars-from-secret.sh"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "GCP region for Artifact Registry"
  type        = string
  default     = "us-central1"
}

variable "repository_id" {
  description = "Artifact Registry Docker repository id"
  type        = string
  default     = "grc-toolkit"
}

variable "enable_apis" {
  description = "Enable commonly used APIs for container + optional GKE"
  type        = bool
  default     = true
}
