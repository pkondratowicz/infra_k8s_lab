
locals {
  location                 = "westeurope"
  vnet_name                = "k8s-lab-vnet"
  vnet_resource_group_name = "k8s-lab-vnet-rg"
  vnet_address_space       = "172.16.88.0/21"
  kv_name                  = "k8s-lab-kv-002"
  kv_resource_group_name   = "k8s-lab-kv-rg"

  admins = [
    {
      initials            = "pk"
      resource_group_name = "k8slab-pk-rg"
      subnet_name         = "k8s-lab-pk-snet"
      prefixes            = ["cp01", "node01"]
    },
    {
      initials            = "ds"
      resource_group_name = "k8slab-ds-rg"
      subnet_name         = "k8s-lab-ds-snet"
      prefixes            = ["cp01", "node01"]
    }
  ]
}

#create resource group for training vms and ssh keys
resource "azurerm_resource_group" "vms-rg" {
  for_each = { for value in local.admins : value.resource_group_name => value }
  name     = each.value.resource_group_name
  location = local.location
}

#create vms 
module "lab-vms" {
  depends_on = [
    azurerm_resource_group.vms-rg,
    azurerm_subnet.k8s-lab-subnets
  ]
  source                        = "./modules/ubuntu-vm"
  vnet_name                     = local.vnet_name
  vnet_resource_group_name      = local.vnet_resource_group_name
  key_vault_name                = azurerm_key_vault.k8skv.name
  key_vault_resource_group_name = azurerm_key_vault.k8skv.resource_group_name
  location                      = local.location
  admins                        = local.admins
}
