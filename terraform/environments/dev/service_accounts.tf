
resource "google_service_account" "github_deployer" {
  project      = var.project_id
  account_id   = "github-deployer"
  display_name = "GitHub Actions Deployer"
  description  = "CI/CD deployment identity"
}

resource "google_service_account" "cloudrun_runtime" {
  project      = var.project_id
  account_id   = "cloudrun-runtime"
  display_name = "Cloud Run Runtime"
  description  = "Runtime identity for FastAPI"
}

resource "google_service_account" "terraform_drift" {
  project      = var.project_id
  account_id   = "terraform-drift"
  display_name = "Terraform Drift Detection"
  description  = "Read-only identity for scheduled drift checks"
}
