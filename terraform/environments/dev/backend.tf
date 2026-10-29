terraform {
  backend "gcs" {
    bucket = "devops-senior-demo-tfstate"
    prefix = "terraform/dev"
  }
}
