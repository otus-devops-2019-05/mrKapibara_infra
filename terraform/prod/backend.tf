terraform {
  backend "gcs" {
    bucket = "devops-otust-test-bckt"
    prefix = "infra/prod"
  }
}
