# secrets.tf
# This file centralizes all secret fetching from Infisical using data sources

# -----------------------------------------------------------------------------
# Neon Configuration Secrets
# -----------------------------------------------------------------------------
data "infisical_secret" "neon_api_key" {
  env_slug     = var.infisical_environment_slug
  workspace_id = var.infisical_project_id
  secret_name  = "NEON_API_KEY"
}

# -----------------------------------------------------------------------------
# Temporal Database Secrets
# -----------------------------------------------------------------------------
data "infisical_secret" "db_password" {
  env_slug     = var.infisical_environment_slug
  workspace_id = var.infisical_project_id
  secret_name  = "NEON_TEMPORAL_PRODUCTION_DB_PASSWORD"
}

data "infisical_secret" "temporal_admin_password" {
  env_slug     = var.infisical_environment_slug
  workspace_id = var.infisical_project_id
  secret_name  = "TEMPORAL_PRODUCTION_ADMIN_PASSWORD"
}
