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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Bootstraps ArgoCD itself via Helm — the one explicit exception to "Terraform
# stops at the API server" (PLAN.md Phase 2): something has to install ArgoCD
# before ArgoCD can manage everything else. Auth uses the AKS kubeconfig
# (local accounts, no AAD integration, so its client certificate already
# carries system:masters/cluster-admin), which is credential material Azure
# itself emits — not a secret we're introducing beyond what Azure requires.
#
# Known rough edge: this provider config is sourced from a resource
# (module.aks) created in this same root module. That's fine on every apply
# after the cluster first exists (today's case), but on a true from-scratch
# `apply` (Phase 8 destroy/rebuild, disaster recovery) the value is unknown
# at plan time. If that happens, run `terraform apply -target=module.aks`
# first, then a normal `apply` for everything else.
provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  }
}
