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

output "kube_config" {
  description = "Cluster-admin kubeconfig credentials (host, client cert/key, CA), for bootstrapping the helm provider. Sensitive — humans should use `az aks get-credentials`, not this output. With no AAD integration on this cluster, kube_admin_config is never populated — kube_config's client certificate already carries system:masters (cluster-admin), which is exactly what `az aks get-credentials` (no --admin flag) has been handing out all along. `sensitive = true` keeps this out of CLI/plan output, but it's still a system:masters cert/key sitting in infra/backend.hcl's S3 state file (encrypt = true is set there) — the shared bucket's own access controls are the real boundary protecting it."
  value = {
    host                   = azurerm_kubernetes_cluster.this.kube_config[0].host
    client_certificate     = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
    client_key             = azurerm_kubernetes_cluster.this.kube_config[0].client_key
    cluster_ca_certificate = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  }
  sensitive = true
}
