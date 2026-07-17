resource "azurerm_user_assigned_identity" "this" {
  for_each = var.identities

  name                = "${var.name_prefix}-id-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "this" {
  for_each = var.identities

  name      = "${var.name_prefix}-fic-${each.key}"
  parent_id = azurerm_user_assigned_identity.this[each.key].id
  audience  = ["api://AzureADTokenExchange"]
  issuer    = var.oidc_issuer_url
  subject   = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
}
