output "artifact_registry_location" {
  description = "Region of the Docker repository"
  value       = google_artifact_registry_repository.grc_toolkit.location
}

output "artifact_registry_repository" {
  description = "Full path prefix for docker push (without image name)"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}"
  sensitive   = true
}

output "helm_image_registry_hint" {
  description = "Use as Helm --set image.registry when repository name matches image"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}"
  sensitive   = true
}
