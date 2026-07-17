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

# Phase 2 (PLAN.md §4): the one Helm release Terraform is allowed to manage —
# ArgoCD has to exist before it can take over everything else above the API
# server. app-of-apps.yaml stays a manual `kubectl apply` (see CLAUDE.md
# Common commands): pointing the cluster at this git repo is a deliberate,
# one-time trust decision, not something to automate away.
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.1.4"
  namespace        = "argocd"
  create_namespace = true

  # The system node pool is tainted CriticalAddonsOnly=true:NoSchedule (see
  # infra/modules/aks) since tenant/platform capacity is meant to come from
  # NAP, not this pool. NAP NodePools don't exist until Phase 3, and ArgoCD
  # is platform bootstrap, not tenant capacity — so it tolerates the taint
  # and runs on the system pool like any other critical add-on.
  values = [
    yamlencode({
      global = {
        tolerations = [
          {
            key      = "CriticalAddonsOnly"
            operator = "Equal"
            value    = "true"
            effect   = "NoSchedule"
          }
        ]
      }
    })
  ]

  depends_on = [module.aks]
}
