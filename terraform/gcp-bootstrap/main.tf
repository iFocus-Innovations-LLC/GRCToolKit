provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  apis = var.enable_apis ? toset([
    "artifactregistry.googleapis.com",
    "containerregistry.googleapis.com",
    "container.googleapis.com",
    "secretmanager.googleapis.com",
  ]) : toset([])
}

resource "google_project_service" "enabled" {
  for_each = local.apis

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "grc_toolkit" {
  location      = var.region
  repository_id = var.repository_id
  description   = "GRC Toolkit container images (dev / distribution)"
  format        = "DOCKER"

  depends_on = [google_project_service.enabled]
}
