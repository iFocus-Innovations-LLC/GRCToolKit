terraform {
  required_version = ">= 1.9.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
locals {
  apis = toset([
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "iap.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "billingbudgets.googleapis.com",
    "sts.googleapis.com",
    "monitoring.googleapis.com",
    "artifactregistry.googleapis.com",
  ])
}

resource "google_project_service" "enabled" {
  for_each = local.apis

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# Secret Manager secret shell (value added manually per docs/CLOUD-RUN-QA.md)
resource "google_secret_manager_secret" "gemini_api_key" {
  secret_id = "gemini-api-key"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.enabled]
}

# Runtime service account (runs the Cloud Run service with least privilege)
resource "google_service_account" "cloudrun_runtime" {
  account_id   = "cloudrun-runtime-sa"
  display_name = "Cloud Run Runtime Service Account"
  description  = "Minimal privileges for GRC Toolkit Cloud Run container"
  project      = var.project_id

  depends_on = [google_project_service.enabled]
}

# Grant runtime SA access to the Gemini API key secret
resource "google_secret_manager_secret_iam_member" "runtime_secret_accessor" {
  secret_id = google_secret_manager_secret.gemini_api_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun_runtime.email}"
}

# Deploy service account (used by GitHub Actions via WIF)
resource "google_service_account" "cloudrun_deployer" {
  account_id   = "cloudrun-deployer-sa"
  display_name = "Cloud Run Deployer Service Account"
  description  = "Used by GitHub Actions to deploy Cloud Run services"
  project      = var.project_id

  depends_on = [google_project_service.enabled]
}

# Grant deployer SA minimal roles for Cloud Run deployment
resource "google_project_iam_member" "deployer_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.cloudrun_deployer.email}"
}

resource "google_project_iam_member" "deployer_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloudrun_deployer.email}"
}

# Grant deployer SA access to Artifact Registry (already created by gcp-bootstrap)
resource "google_project_iam_member" "deployer_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cloudrun_deployer.email}"
}

# Workload Identity Federation pool
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions OIDC"

  depends_on = [google_project_service.enabled]
}

# WIF provider for GitHub
resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  description                        = "OIDC provider for GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow GitHub Actions from this repo to impersonate the deployer SA
resource "google_service_account_iam_member" "wif_github_deployer" {
  service_account_id = google_service_account.cloudrun_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

# Cloud Run service (placeholder - will be deployed by GitHub Actions)
# This resource ensures the service exists with IAP enabled
resource "google_cloud_run_v2_service" "grc_toolkit_qa" {
  name     = "grc-toolkit-qa"
  location = var.region
  project  = var.project_id

  template {
    service_account = google_service_account.cloudrun_runtime.email

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      # Placeholder image - will be replaced by GitHub Actions deploy
      image = "${var.region}-docker.pkg.dev/${var.project_id}/grc-toolkit/grc-toolkit:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env {
        name  = "LLM_PROVIDER"
        value = "gemini"
      }

      env {
        name  = "GEMINI_MODEL"
        value = "gemini-3.8-flash"
      }

      env {
        name = "GEMINI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.gemini_api_key.secret_id
            version = "latest"
          }
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_project_service.enabled,
    google_secret_manager_secret_iam_member.runtime_secret_accessor
  ]

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }
}

# Grant IAP access to allowed users (Cloud Run-specific resource)
# IAP is automatically enabled on Cloud Run when IAM bindings are configured
resource "google_iap_web_cloud_run_service_iam_binding" "cloudrun_iap_users" {
  project                = var.project_id
  location               = var.region
  cloud_run_service_name = google_cloud_run_v2_service.grc_toolkit_qa.name
  role                   = "roles/iap.httpsResourceAccessor"
  members                = var.iap_allowed_users

  depends_on = [
    google_project_service.enabled,
    google_cloud_run_v2_service.grc_toolkit_qa
  ]
}

# Grant IAP service agent permission to invoke Cloud Run
resource "google_cloud_run_service_iam_member" "iap_invoker" {
  project  = var.project_id
  location = var.region
  service  = google_cloud_run_v2_service.grc_toolkit_qa.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-iap.iam.gserviceaccount.com"

  depends_on = [google_project_service.enabled]
}

# Get project number for IAP service agent
data "google_project" "project" {
  project_id = var.project_id
}

# Billing budget with alerts
resource "google_billing_budget" "cloudrun_qa_budget" {
  billing_account = var.billing_account_id
  display_name    = "GRC Toolkit Cloud Run QA Budget"

  budget_filter {
    projects = ["projects/${data.google_project.project.number}"]
    services = ["services/F25E-7A61-5C95"] # Cloud Run service ID
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "5"
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = var.budget_alert_emails != null ? [
      for email in var.budget_alert_emails :
      google_monitoring_notification_channel.budget_email[email].id
    ] : []
    disable_default_iam_recipients = false
  }
}

# Email notification channels for budget alerts
resource "google_monitoring_notification_channel" "budget_email" {
  for_each = var.budget_alert_emails != null ? toset(var.budget_alert_emails) : toset([])

  display_name = "Budget Alert - ${each.value}"
  type         = "email"
  labels = {
    email_address = each.value
  }
  force_delete = false
}
