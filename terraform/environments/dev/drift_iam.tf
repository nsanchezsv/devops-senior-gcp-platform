
locals {
  drift_project_roles = toset([
    "roles/browser",
    "roles/run.viewer",
    "roles/artifactregistry.reader",
    "roles/secretmanager.viewer",
    "roles/iam.serviceAccountViewer",
    "roles/iam.workloadIdentityPoolViewer"
  ])
}

resource "google_project_iam_member" "drift_readonly" {
  for_each = local.drift_project_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_drift.email}"
}

resource "google_storage_bucket_iam_member" "drift_state_reader" {
  bucket = "devops-senior-demo-tfstate"
  role   = "roles/storage.objectViewer"

  member = "serviceAccount:${google_service_account.terraform_drift.email}"
}

