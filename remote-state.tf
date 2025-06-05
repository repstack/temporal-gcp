# remote-state.tf
# This file centralizes all remote Terraform state data sources
# for reading configuration from other Terraform projects/repos

# -----------------------------------------------------------------------------
# Backend Management Repository State
# -----------------------------------------------------------------------------
data "terraform_remote_state" "shared_backend_config" {
  backend = "gcs"

  config = {
    bucket = var.backend_state_bucket
    prefix = "temporal"
  }
}
