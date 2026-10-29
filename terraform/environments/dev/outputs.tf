output "project_id" {
  value = var.project_id
}

output "region" {
  value = var.region
}

output "environment" {
  value = var.environment
}
output "artifact_registry_repository" {
  description = "Artifact Registry repository ID"
  value       = google_artifact_registry_repository.docker.repository_id
}

output "artifact_registry_url" {
  description = "Docker repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}"
}

output "github_deployer_email" {
  description = "GitHub Actions deployment identity"
  value       = google_service_account.github_deployer.email
}

output "cloudrun_runtime_email" {
  description = "Cloud Run runtime identity"
  value       = google_service_account.cloudrun_runtime.email
}
output "secret_id" {
  description = "Secret Manager secret identifier"
  value       = google_secret_manager_secret.api_key.secret_id
}
output "cloud_run_url" {
  description = "Public URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.api.uri
}

output "cloud_run_service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.api.name
}

output "github_wif_provider" {
  description = "WIF provider resource name for GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github.name
}
