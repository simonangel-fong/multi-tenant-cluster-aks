# More outputs land here as the aks, identity, and keyvault modules are
# wired into main.tf during Phase 1 — see PLAN.md §4.

output "resource_group_name" {
  description = "Name of the resource group all modules deploy into."
  value       = module.network.resource_group_name
}

output "vnet_id" {
  description = "ID of the VNet."
  value       = module.network.vnet_id
}

output "aks_subnet_id" {
  description = "ID of the subnet AKS nodes are deployed into."
  value       = module.network.aks_subnet_id
}
