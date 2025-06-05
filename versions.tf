terraform {
  backend "gcs" {
    bucket = var.backend_state_bucket
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    infisical = {
      source  = "infisical/infisical"
      version = "~> 1.0" # Check the latest version on Terraform Registry
    }
    neon = {
      source  = "neondatabase/neon"
      version = "~> 0.1" # Check the latest version on Terraform Registry
    }
  }
  required_version = ">= 1.0"
}
