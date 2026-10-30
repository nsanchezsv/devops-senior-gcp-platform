resource "google_iam_workload_identity_pool" "github_drift" {
  project                   = var.project_id
  workload_identity_pool_id = "github-drift-pool"
  display_name              = "GitHub Drift Pool"
}

resource "google_iam_workload_identity_pool_provider" "github_drift" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_drift.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-drift-oidc"
  display_name                       = "GitHub Drift Detection OIDC"

  attribute_mapping = {
    "google.subject"                = "assertion.sub"
    "attribute.repository_id"       = "assertion.repository_id"
    "attribute.repository_owner_id" = "assertion.repository_owner_id"
  }

  attribute_condition = join(" && ", [
    "assertion.repository_owner_id == '${var.github_owner_id}'",
    "assertion.repository_id == '${var.github_repository_id}'",
    "assertion.ref == 'refs/heads/main'",
    "assertion.workflow_ref.endsWith('/.github/workflows/terraform-drift.yml@refs/heads/main')",
    "assertion.event_name in ['schedule', 'workflow_dispatch']"
  ])

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_drift_wif" {
  service_account_id = google_service_account.terraform_drift.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_drift.name}/attribute.repository_id/${var.github_repository_id}"
}

