variable "name_prefix" {
  type        = string
  description = "Naming prefix for the cluster and related resources (e.g. \"mtc-aks-dev\")."
}

variable "location" {
  type        = string
  description = "Azure region for the cluster."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy the cluster into (from the network module)."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the system node pool (from the network module; must already have a NAT Gateway attached for egress)."
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to pin the cluster to. Leave null to use AKS's current default version."
  default     = null
}

variable "sku_tier" {
  type        = string
  description = "AKS control plane SKU tier (\"Free\" or \"Standard\"). Standard adds an uptime SLA; use it for anything beyond dev."
  default     = "Free"
}

variable "system_node_vm_size" {
  type        = string
  description = "VM size for the system node pool. Kept minimal since tenant capacity comes from Node Auto Provisioning, not this pool."
  default     = "standard_dc2s_v3"
}

variable "system_node_count" {
  type        = number
  description = "Fixed node count for the system node pool."
  default     = 2
}

variable "service_cidr" {
  type        = string
  description = "ClusterIP service CIDR. Must not overlap the VNet address space (10.0.0.0/16)."
  default     = "172.16.0.0/16"
}

variable "dns_service_ip" {
  type        = string
  description = "IP within service_cidr reserved for the cluster's internal DNS service."
  default     = "172.16.0.10"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the cluster."
  default     = {}
}
