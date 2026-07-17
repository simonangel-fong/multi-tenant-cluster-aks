# External parameters — set via infra/*.auto.tfvars or -var on the CLI.
# Module-level inputs live in each module's own variables.tf; these are the
# root-level knobs shared across all modules.

variable "environment" {
  type        = string
  description = "Deployment environment; feeds the mtc-aks-<environment>-* resource naming prefix."
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure region for all resources (e.g. \"canadacentral\")."
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto every resource, on top of the common tags in locals.tf."
  default     = {}
}
