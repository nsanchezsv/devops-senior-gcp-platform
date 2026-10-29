
resource "google_artifact_registry_repository" "docker" {
  project       = var.project_id
  location      = var.region
  repository_id = "devops-app"
  description   = "Docker images for DevOps Senior technical assessment"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
