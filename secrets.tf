# secrets.tf
# This file centralizes all secret fetching from Infisical using ephemeral resources
# for enhanced security (secrets are not stored in Terraform state)

# -----------------------------------------------------------------------------
# Neon Configuration Secrets
# -----------------------------------------------------------------------------
ephemeral "infisical_secret" "neon_api_key" {
  env_slug     = var.infisical_environment_slug
  workspace_id = var.infisical_project_id
  name         = "NEON_API_KEY"
}

# -----------------------------------------------------------------------------
# Temporal Database Secrets
# -----------------------------------------------------------------------------
ephemeral "infisical_secret" "db_password" {
  env_slug     = var.infisical_environment_slug
  workspace_id = var.infisical_project_id
  name         = "NEON_TEMPORAL_PRODUCTION_DB_PASSWORD"
}

ephemeral "infisical_secret" "temporal_admin_password" {
  env_slug     = var.infisical_environment_slug
  workspace_id = var.infisical_project_id
  name         = "TEMPORAL_PRODUCTION_ADMIN_PASSWORD"
}
