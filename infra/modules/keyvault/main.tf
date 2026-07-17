data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = "${var.name_prefix}-kv"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = var.purge_protection_enabled
  tags                       = var.tags
}

resource "azurerm_role_assignment" "secrets_user" {
  for_each = var.secrets_user_principal_ids

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}
