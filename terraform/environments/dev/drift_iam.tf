
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

resource "google_project_iam_custom_role" "drift_policy_reader" {
  project     = var.project_id
  role_id     = "terraformDriftPolicyReader"
  title       = "Terraform Drift Policy Reader"
  description = "Read IAM policies required by Terraform drift detection"

  permissions = [
    "storage.buckets.getIamPolicy",
    "artifactregistry.repositories.getIamPolicy",
    "iam.roles.get"
  ]
}

resource "google_project_iam_member" "drift_policy_reader" {
  project = var.project_id
  role    = google_project_iam_custom_role.drift_policy_reader.id

  member = "serviceAccount:${google_service_account.terraform_drift.email}"
}

