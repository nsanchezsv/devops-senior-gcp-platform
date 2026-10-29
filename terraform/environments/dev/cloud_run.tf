
resource "google_cloud_run_v2_service" "api" {
  project  = var.project_id
  name     = "tramites-api"
  location = var.region

  deletion_protection  = false
  ingress              = "INGRESS_TRAFFIC_ALL"
  invoker_iam_disabled = true


  template {
    service_account = google_service_account.cloudrun_runtime.email

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      name = "tramites-api"

      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}/tramites-api@sha256:71085752dff5daafcaad0ca57af9b7efd60b95be322a933bb48794688bb20202"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env {
        name = "API_KEY"

        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.api_key.secret_id
            version = "1"
          }
        }
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.runtime_accessor
  ]

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image
    ]
  }
}
