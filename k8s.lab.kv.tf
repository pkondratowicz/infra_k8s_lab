resource "azurerm_resource_group" "kv-rg" {
  name     = local.kv_resource_group_name
  location = local.location
}

resource "azurerm_key_vault" "k8skv" {
  name                      = local.kv_name
  location                  = local.location
  resource_group_name       = azurerm_resource_group.kv-rg.name
  tenant_id                 = data.azurerm_client_config.current.tenant_id #tenant id here
  sku_name                  = "standard"
  enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "k8skv_secrets_officer" {
  scope                = azurerm_key_vault.k8skv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

