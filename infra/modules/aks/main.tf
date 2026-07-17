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
