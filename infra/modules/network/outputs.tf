output "resource_group_name" {
  description = "Name of the resource group all other modules (aks, identity, keyvault) deploy into."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Azure region, for reuse by downstream modules without re-reading var.location."
  value       = azurerm_resource_group.this.location
}

output "vnet_id" {
  description = "ID of the VNet."
  value       = azurerm_virtual_network.this.id
}

output "aks_subnet_id" {
  description = "ID of the subnet AKS nodes are deployed into."
  value       = azurerm_subnet.aks.id
}
