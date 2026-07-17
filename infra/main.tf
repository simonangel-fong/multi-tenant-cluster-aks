module "network" {
  source = "./modules/network"

  name_prefix = local.name_prefix
  location    = var.location
  tags        = local.common_tags
}

module "aks" {
  source = "./modules/aks"

  name_prefix         = local.name_prefix
  location            = module.network.location
  resource_group_name = module.network.resource_group_name
  subnet_id           = module.network.aks_subnet_id
  tags                = local.common_tags

  # The subnet's NAT Gateway association must exist before the cluster is
  # created (outbound_type = "userAssignedNATGateway"); depending on the
  # subnet ID output alone doesn't guarantee that ordering.
  depends_on = [module.network]
}
