resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name_prefix
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.name_prefix
  node_resource_group = "${var.name_prefix}-nrg"
  sku_tier            = var.sku_tier
  kubernetes_version  = var.kubernetes_version

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    node_count                   = var.system_node_count
    vnet_subnet_id               = var.subnet_id
    only_critical_addons_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  # Node Auto Provisioning requires Azure CNI Overlay + Cilium dataplane.
  # service_cidr/dns_service_ip must not overlap the VNet (10.0.0.0/16) —
  # AKS's own default service CIDR is 10.0.0.0/16, which collides with it.
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    load_balancer_sku   = "standard"
    outbound_type       = "userAssignedNATGateway"
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  # Managed Karpenter. Tenant capacity comes entirely from here, not the
  # system pool above. Workload-class NodePool/AKSNodeClass CRDs are created
  # by ArgoCD in Phase 3, not Terraform.
  node_provisioning_profile {
    mode = "Auto"
  }

  tags = var.tags
}

# Bring-your-own-VNet AKS clusters don't get their identity auto-granted
# network access the way AKS-managed VNets do — that's the deployer's job.
# The initial system node pool works anyway (the AKS resource provider
# provisions it internally), but Node Auto Provisioning's Karpenter
# controller runs as an in-cluster workload and calls Azure APIs directly
# using the cluster's own identity, which needs this to read/join the
# subnet. Network Contributor (rather than a narrower custom role limited
# to subnets/read + subnets/join/action) is Microsoft's own documented
# minimum for this scenario; scoping to the subnet, not the VNet or
# resource group, keeps the blast radius to just the one subnet AKS nodes
# actually live in.
resource "azurerm_role_assignment" "subnet_network_contributor" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id
}
