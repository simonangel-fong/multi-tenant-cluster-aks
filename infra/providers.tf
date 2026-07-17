# Minimal backend/provider wiring so `terraform init -backend-config=backend.hcl`
# succeeds (Phase 0 acceptance check). Modules, resources, and provider version
# pins get filled in during Phase 1 (network/aks/identity/keyvault).
#
# State backend is S3 — same shared bucket used for AWS/Azure/GCP projects,
# not an Azure-native backend. See backend.hcl.example for the config shape.

terraform {
  required_version = ">= 1.6"

  backend "s3" {
    # All values supplied via -backend-config=backend.hcl (gitignored, local only).
    # See backend.hcl.example for the template.
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
