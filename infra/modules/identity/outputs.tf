output "client_ids" {
  description = "Map of logical identity name => client ID, for the azure.workload.identity/client-id annotation on each Kubernetes ServiceAccount."
  value       = { for k, v in azurerm_user_assigned_identity.this : k => v.client_id }
}

output "principal_ids" {
  description = "Map of logical identity name => principal (object) ID, consumed by the keyvault module for RBAC role assignments."
  value       = { for k, v in azurerm_user_assigned_identity.this : k => v.principal_id }
}
