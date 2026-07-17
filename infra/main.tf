module "network" {
  source = "./modules/network"

  name_prefix = local.name_prefix
  location    = var.location
  tags        = local.common_tags
}
