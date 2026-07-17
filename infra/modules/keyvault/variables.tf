variable "name_prefix" {
  type        = string
  description = "Naming prefix for the Key Vault (e.g. \"mtc-aks-dev\")."
}

variable "location" {
  type        = string
  description = "Azure region for the Key Vault."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to create the Key Vault in (from the network module)."
}

variable "secrets_user_principal_ids" {
  type        = set(string)
  description = "Principal (object) IDs granted the \"Key Vault Secrets User\" role — read-only access to secret values, not vault management."
  default     = []
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Whether purge protection is enabled. Defaults to false so dev environments can be destroyed and rebuilt cleanly; enable for prod."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the Key Vault."
  default     = {}
}
