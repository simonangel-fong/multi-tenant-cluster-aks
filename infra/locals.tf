# Internal values derived from variables.tf — not settable directly by callers.

locals {
  name_prefix = "mtc-aks-${var.environment}"

  common_tags = merge(var.tags, {
    project     = "multi-tenant-cluster-aks"
    environment = var.environment
    managed_by  = "terraform"
  })
}
