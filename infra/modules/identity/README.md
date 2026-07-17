# identity

Provisions one Workload Identity (user-assigned managed identity + OIDC federated credential) per entry in `var.identities`, each bound to a specific `system:serviceaccount:<namespace>:<service_account>` against the AKS cluster's OIDC issuer. No Azure RBAC is granted here — role assignments (e.g. Key Vault Secrets User) live in the `keyvault` module and any other module that owns the resource being granted access to, scoped against this module's `principal_ids` output.

**Inputs**: `name_prefix`, `location`, `resource_group_name` (from `network`), `oidc_issuer_url` (from `aks`), `identities` (map of logical name → `{namespace, service_account}`, e.g. `{ eso = { namespace = "external-secrets", service_account = "external-secrets" } }`), `tags`.

**Outputs**: `client_ids` (map, for each ServiceAccount's `azure.workload.identity/client-id` annotation), `principal_ids` (map, for RBAC role assignments elsewhere).
