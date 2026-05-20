output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "artifact_registry_url" {
  description = "Full URL for the Artifact Registry Docker repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.app_name}"
}

output "get_credentials_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.zone} --project ${var.project_id}"
}
