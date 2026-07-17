variable "name_prefix" {
  type        = string
  description = "Naming prefix for all resources in this module (e.g. \"mtc-aks-dev\")."
}

variable "location" {
  type        = string
  description = "Azure region for all resources."
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the VNet."
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the AKS node subnet (Azure CNI overlay, so this stays small regardless of pod count)."
  default     = ["10.0.0.0/22"]
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources in this module."
  default     = {}
}
