# keyvault

Provisions the platform Key Vault (RBAC-authorized, not access-policy-based) and grants the "Key Vault Secrets User" role to each principal in `var.secrets_user_principal_ids` — in practice, the `eso` Workload Identity's `principal_id` from the `identity` module, so External Secrets Operator can read secrets via Workload Identity federation with no static credentials involved.

**Inputs**: `name_prefix`, `location`, `resource_group_name` (from `network`), `secrets_user_principal_ids` (set of principal/object IDs, from `identity`'s `principal_ids` output), `purge_protection_enabled` (default `false` for dev), `tags`.

**Outputs**: `key_vault_id`, `key_vault_name`, `key_vault_uri` (consumed by ArgoCD's `ClusterSecretStore` manifest in Phase 6).
