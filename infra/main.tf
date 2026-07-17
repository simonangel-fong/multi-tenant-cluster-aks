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

module "identity" {
  source = "./modules/identity"

  name_prefix         = local.name_prefix
  location            = module.network.location
  resource_group_name = module.network.resource_group_name
  oidc_issuer_url     = module.aks.oidc_issuer_url
  tags                = local.common_tags

  # ESO is the only workload that needs its own Azure identity today — it's
  # the sole bootstrap secret (Cloudflare token, etc. are vended through it
  # from Key Vault). cert-manager/external-dns consume k8s Secrets from ESO
  # rather than talking to Azure directly. See PLAN.md Phase 6.
  identities = {
    eso = {
      namespace       = "external-secrets"
      service_account = "external-secrets"
    }
  }
}

module "keyvault" {
  source = "./modules/keyvault"

  name_prefix         = local.name_prefix
  location            = module.network.location
  resource_group_name = module.network.resource_group_name
  tags                = local.common_tags

  secrets_user_principal_ids = [module.identity.principal_ids["eso"]]
}
