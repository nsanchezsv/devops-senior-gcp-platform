
resource "google_secret_manager_secret" "api_key" {
  project   = var.project_id
  secret_id = "devops-api-key"

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "google_secret_manager_secret_iam_member" "runtime_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.api_key.secret_id

  role = "roles/secretmanager.secretAccessor"

  member = "serviceAccount:${google_service_account.cloudrun_runtime.email}"
}
