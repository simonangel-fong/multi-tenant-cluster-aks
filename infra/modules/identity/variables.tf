variable "name_prefix" {
  type        = string
  description = "Naming prefix for identity resources (e.g. \"mtc-aks-dev\")."
}

variable "location" {
  type        = string
  description = "Azure region for the identities."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to create the identities in (from the network module)."
}

variable "oidc_issuer_url" {
  type        = string
  description = "AKS cluster OIDC issuer URL (from the aks module), trusted by each federated credential."
}

variable "identities" {
  type = map(object({
    namespace       = string
    service_account = string
  }))
  description = "Logical name => Kubernetes namespace/service account. One user-assigned managed identity + federated credential is created per entry, bound to system:serviceaccount:<namespace>:<service_account>."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all identities."
  default     = {}
}
