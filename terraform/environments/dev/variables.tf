variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "devops-senior-demo"
}

variable "region" {
  description = "GCP deployment region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "github_repository_id" {
  description = "Immutable GitHub repository ID"
  type        = string
}

variable "github_owner_id" {
  description = "Immutable GitHub repository owner ID"
  type        = string
}
