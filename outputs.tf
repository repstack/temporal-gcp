# outputs.tf
# This file defines the outputs of the Terraform configuration.

output "temporal_server_url" {
  description = "The URL of the Temporal Server Cloud Run service."
  value       = google_cloud_run_v2_service.temporal_server.uri
}

output "temporal_ui_url" {
  description = "The URL of the Temporal UI Cloud Run service."
  value       = google_cloud_run_v2_service.temporal_ui.uri
}

output "temporal_server_service_account_email" {
  description = "The email of the service account used by Temporal Cloud Run services."
  value       = google_service_account.cloud_run_sa.email
}

# output "neon_database_connection_string" {
#   description = "The connection string for the Neon PostgreSQL database."
#   # Note: This output exposes sensitive info. Use with caution or remove in production.
#   value     = neon_role.temporal_db_user.connection_uri
#   sensitive = true
# }
