# variables.tf
# This file defines the input variables for the Terraform configuration.

variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy resources in (e.g., us-central1)."
  type        = string
  default     = "europe-west2" # London
}

variable "infisical_host_address" {
  description = "The URL of your self-hosted Infisical instance."
  type        = string
  sensitive   = true
}

variable "infisical_client_id" {
  description = "Infisical Universal Auth Client ID."
  type        = string
  sensitive   = true
}

variable "infisical_client_secret" {
  description = "Infisical Universal Auth Client Secret."
  type        = string
  sensitive   = true
}

variable "infisical_project_id" {
  description = "The Infisical project ID where secrets are stored."
  type        = string
}

variable "infisical_environment_slug" {
  description = "The Infisical environment slug (e.g., 'development', 'production')."
  type        = string
}

variable "neon_vpc_peering_network_id" {
  description = "The network ID provided by Neon for VPC peering. Obtain this from your Neon account for private connectivity."
  type        = string
  # No default, this is crucial for private connectivity with Neon
}

variable "temporal_version" {
  description = "The Docker image version for temporalio/auto-setup."
  type        = string
  default     = "1.20.0" # Check for the latest stable version
}

variable "temporal_ui_version" {
  description = "The Docker image version for temporalio/ui."
  type        = string
  default     = "2.25.0" # Check for the latest stable version
}

variable "backend_state_bucket" {
  description = "The GCS bucket name where the backend management repo's Terraform state is stored."
  type        = string
}
