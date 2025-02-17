data "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

resource "random_pet" "ssh_key_name" {
  for_each  = { for admin in var.admins : admin.initials => admin }
  prefix    = "ssh-${each.key}-"
  separator = ""
}

resource "azapi_resource" "ssh_public_key" {
  for_each  = { for admin in var.admins : admin.initials => admin }
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name[each.key].id
  location  = var.location
  parent_id = data.azurerm_resource_group.vm-rg[each.value.resource_group_name].id
}

resource "azapi_resource_action" "ssh_public_key_gen" {
  for_each    = { for admin in var.admins : admin.initials => admin }
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key[each.key].id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

output "admin_public_keys" {
  value     = { for key, admin in azapi_resource_action.ssh_public_key_gen : key => admin.output.publicKey }
  sensitive = false
}

output "admin_private_keys" {
  value     = { for key, admin in azapi_resource_action.ssh_public_key_gen : key => admin.output.privateKey }
  sensitive = true # Keep this private!
}

resource "azurerm_key_vault_secret" "sshkey" {
  for_each     = { for key, admin in azapi_resource_action.ssh_public_key_gen : key => admin }
  name         = random_pet.ssh_key_name[each.key].id
  value        = each.value.output.privateKey
  key_vault_id = data.azurerm_key_vault.kv.id
  depends_on   = [azapi_resource_action.ssh_public_key_gen]

}
