resource "google_artifact_registry_repository_iam_member" "github_writer" {
  project    = var.project_id
  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name

  role = "roles/artifactregistry.writer"

  member = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_cloud_run_v2_service_iam_member" "github_developer" {
  project  = var.project_id
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name

  role   = "roles/run.developer"
  member = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_service_account_iam_member" "github_runtime_user" {
  service_account_id = google_service_account.cloudrun_runtime.name

  role   = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.github_deployer.email}"
}
