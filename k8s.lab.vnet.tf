
#create resource group for network stuff
resource "azurerm_resource_group" "vnet-rg" {
  name     = local.vnet_resource_group_name
  location = local.location

}

#create virtual network
resource "azurerm_virtual_network" "k8s-lab-vnet" {
  name                = local.vnet_name
  resource_group_name = azurerm_resource_group.vnet-rg.name
  location            = local.location
  address_space       = [local.vnet_address_space]
}

#calculate subnets for admins + bastion host
module "lab_subnets" {
  source          = "./modules/terraform-cidr-subnets"
  base_cidr_block = local.vnet_address_space
  networks = [
    {
      name     = "AzureBastionSubnet"
      new_bits = 3
    },
    {
      name     = "k8s-lab-pk-snet"
      new_bits = 3
    },
    {
      name     = "k8s-lab-ds-snet"
      new_bits = 3
    }
  ]
}

#create subnets in the previously created virtual network
resource "azurerm_subnet" "k8s-lab-subnets" {
  for_each             = module.lab_subnets.network_cidr_blocks
  name                 = each.key
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.k8s-lab-vnet.name
  address_prefixes     = [each.value]
}

#create public ip for bastion host
resource "azurerm_public_ip" "bastion" {
  name                = "k8s-lab-bastion-ip"
  resource_group_name = azurerm_resource_group.vnet-rg.name
  location            = local.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

#create bastion host
resource "azurerm_bastion_host" "bastion" {
  depends_on          = [azurerm_subnet.k8s-lab-subnets]
  name                = "k8s-lab-bastion"
  resource_group_name = azurerm_resource_group.vnet-rg.name
  location            = local.location
  sku                 = "Standard"
  ip_configuration {
    name                 = "k8s-lab-bastion-ip-config"
    subnet_id            = azurerm_subnet.k8s-lab-subnets["AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

output "subnets" {
  value = module.lab_subnets.network_cidr_blocks
}
