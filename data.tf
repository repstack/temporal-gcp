data "infisical_secrets" "app_secrets" {
  project_id  = var.infisical_project_id
  environment = var.infisical_environment_slug
}
