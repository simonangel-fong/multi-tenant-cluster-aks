output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_id" {
  description = "Resource ID of the AKS cluster, for role-assignment scoping in the identity/keyvault modules."
  value       = azurerm_kubernetes_cluster.this.id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL, consumed by the identity module to bind federated credentials for Workload Identity."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "node_resource_group" {
  description = "Auto-managed resource group holding node VMs/disks/LB IPs, for scoping diagnostics or NSG rules if ever needed."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}
