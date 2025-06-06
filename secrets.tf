# secrets.tf
# This file centralizes all secret fetching from Infisical using data sources

# -----------------------------------------------------------------------------
# Neon Configuration Secrets
# -----------------------------------------------------------------------------
data "infisical_secrets" "neon_secrets" {
  env_slug     = var.infisical_environment_slug
  workspace_id = var.infisical_project_id
  folder_path  = "/"
}

# -----------------------------------------------------------------------------
# Temporal Database Secrets
# -----------------------------------------------------------------------------
data "infisical_secrets" "temporal_secrets" {
  env_slug     = var.infisical_environment_slug
  workspace_id = var.infisical_project_id
  folder_path  = "/"
}

