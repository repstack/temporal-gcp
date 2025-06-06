# main.tf
# This file defines the core infrastructure resources.

# -----------------------------------------------------------------------------
# GCP Provider Configuration
# -----------------------------------------------------------------------------
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# -----------------------------------------------------------------------------
# Infisical Provider Configuration
# IMPORTANT: Replace with your actual Infisical host and authentication method.
# -----------------------------------------------------------------------------
provider "infisical" {
  host = var.infisical_host_address

  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}

# -----------------------------------------------------------------------------
# Neon Provider Configuration
# -----------------------------------------------------------------------------
provider "neon" {
  token = data.infisical_secrets.neon_secrets.secrets["NEON_PRODUCTION_API_KEY"].value
}

# -----------------------------------------------------------------------------
# GCP Service Account for Cloud Run
# This service account will be used by all Cloud Run services.
# Adhere to the principle of least privilege.
# -----------------------------------------------------------------------------
resource "google_service_account" "cloud_run_sa" {
  account_id   = "temporal-cloudrun-sa"
  display_name = "Service Account for Temporal Cloud Run Services"
  project      = var.gcp_project_id
}

# IAM binding to allow the service account to deploy and manage Cloud Run services
resource "google_project_iam_member" "cloud_run_developer_binding" {
  project = var.gcp_project_id
  role    = "roles/run.developer" # Allows managing Cloud Run services
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# IAM binding to allow Cloud Run services to pull images
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# -----------------------------------------------------------------------------
# Serverless VPC Access Connector
# Required for Cloud Run to connect to private networks (like Neon if needed).
# -----------------------------------------------------------------------------
# resource "google_compute_network" "vpc_network" {
#   name                    = "temporal-vpc-network"
#   project                 = var.gcp_project_id
#   auto_create_subnetworks = true # For simplicity, auto-create subnets
# }

# resource "google_compute_network_peering" "neon_peering" {
#   name                 = "neon-vpc-peering"
#   network              = google_compute_network.vpc_network.self_link
#   peer_network         = var.neon_vpc_peering_network_id # Provided by Neon for VPC peering
#   import_custom_routes = true
#   export_custom_routes = true
# }


# resource "google_vpc_access_connector" "temporal_connector" {
#   name          = "temporal-vpc-connector"
#   region        = var.gcp_region
#   ip_cidr_range = "10.8.0.0/28" # Small CIDR range for connector
#   network       = google_compute_network.vpc_network.name
#   project       = var.gcp_project_id
# }

# -----------------------------------------------------------------------------
# Neon.tech PostgreSQL Database
# -----------------------------------------------------------------------------
resource "neon_project" "temporal_db_project" {
  name      = "temporal"
  region_id = "aws-eu-west-2"
}

resource "neon_branch" "temporal_db_branch" {
  project_id = neon_project.temporal_db_project.id
  name       = "main"
}

resource "neon_database" "temporal_database" {
  project_id = neon_project.temporal_db_project.id
  branch_id  = neon_branch.temporal_db_branch.id
  name       = "temporal-production"
  owner_name = "temporal"
}

resource "neon_role" "temporal_db_user" {
  project_id = neon_project.temporal_db_project.id
  branch_id  = neon_branch.temporal_db_branch.id
  name       = "temporal"
}

# -----------------------------------------------------------------------------
# Cloud Run Service: Temporal Server
# NOTE: min_instance_count is set to 1 to prevent scaling to zero.
# This assumes the 'auto-setup' image correctly initializes the database
# upon startup.
# -----------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "temporal_server" {
  name     = "temporal-server"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    service_account = google_service_account.cloud_run_sa.email
    containers {
      image = "temporalio/auto-setup:${var.temporal_version}"
      ports {
        container_port = 7233
      }
      env {
        name  = "DB"
        value = "postgres12"
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
      env {
        name  = "POSTGRES_USER"
        value = neon_role.temporal_db_user.name
      }
      env {
        name  = "POSTGRES_PWD"
        value = data.infisical_secrets.temporal_secrets.secrets["NEON_TEMPORAL_PRODUCTION_DB_PASSWORD"].value
      }
      # env {
      #   name  = "POSTGRES_SEEDS"
      #   value = neon_branch.temporal_db_branch.connection_uri_params["host"] # Use Neon host
      # }
      env {
        name  = "DYNAMIC_CONFIG_FILE_PATH"
        value = "config/dynamicconfig/development-sql.yaml" # Assuming default path
      }
      env {
        name  = "TEMPORAL_ADDRESS"
        value = "0.0.0.0:7233" # Listen on all interfaces
      }
      env {
        name  = "TEMPORAL_CLI_ADDRESS"
        value = "0.0.0.0:7233"
      }
      resources {
        limits = {
          cpu    = "1000m" # 1 CPU
          memory = "1Gi"   # 1 GB Memory
        }
      }
    }
    scaling {
      min_instance_count = 1 # CRITICAL: Keep at least one instance running
      max_instance_count = 2 # Adjust based on expected load
    }
    # vpc_access {
    #   connector = google_vpc_access_connector.temporal_connector.id
    #   egress    = "ALL_TRAFFIC" # Ensure egress to VPC for DB connection
    # }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  # Allow unauthenticated access for simplicity, or set up IAP if needed.
  # For internal services, consider "run.googleapis.com/ingress": "internal-and-cloud-load-balancing"
  # or use Private Google Access + VPC Access.
  # For the Temporal server, it's typically an internal service.
  # Set it to private for now.
  binary_authorization {
    policy = "DEFAULT_POLICY" # No Binary Authorization
  }
}

resource "google_cloud_run_v2_service_iam_member" "temporal_server_public_access" {
  location = google_cloud_run_v2_service.temporal_server.location
  name     = google_cloud_run_v2_service.temporal_server.name
  role     = "roles/run.invoker"
  member   = "allUsers" # This makes it publicly accessible. REMOVE FOR INTERNAL-ONLY.
  # For internal access, remove this, and ensure other services/clients are in VPC.
  # Or use a Load Balancer + IAP if it needs external but authenticated access.
}


# -----------------------------------------------------------------------------
# Cloud Run Service: Temporal UI
# This service can scale to zero.
# -----------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "temporal_ui" {
  name     = "temporal-ui"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    service_account = google_service_account.cloud_run_sa.email
    containers {
      image = "temporalio/ui:${var.temporal_ui_version}"
      ports {
        container_port = 8080
      }
      env {
        name = "TEMPORAL_ADDRESS"
        # Reference the internal URL of the Temporal Server Cloud Run service
        value = "${google_cloud_run_v2_service.temporal_server.uri}:7233"
      }
      env {
        name  = "TEMPORAL_CORS_ORIGINS"
        value = "http://localhost:3000,https://repstack.com" # Adjust as needed
      }
      resources {
        limits = {
          cpu    = "500m"  # 0.5 CPU
          memory = "512Mi" # 512 MB Memory
        }
      }
    }
    scaling {
      min_instance_count = 0 # Can scale to zero
      max_instance_count = 1 # Start small
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_cloud_run_v2_service_iam_member" "temporal_ui_public_access" {
  location = google_cloud_run_v2_service.temporal_ui.location
  name     = google_cloud_run_v2_service.temporal_ui.name
  role     = "roles/run.invoker"
  member   = "allUsers" # Make the UI publicly accessible
}
