terraform {
  backend "gcs" {
    bucket = "terraform-state-dev-e8e61720"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    infisical = {
      source  = "infisical/infisical"
      version = "0.15.12"
    }
    neon = {
      source  = "terraform-community-providers/neon"
      version = "0.1.8"
    }
  }
  required_version = ">= 1.0"
}
