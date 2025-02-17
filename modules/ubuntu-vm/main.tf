
data "azurerm_resource_group" "vm-rg" {
  for_each = { for value in var.admins : value.resource_group_name => value }
  name     = each.value.resource_group_name
}

data "azurerm_subnet" "vm-subnet" {
  for_each             = { for value in var.admins : value.resource_group_name => value }
  name                 = each.value.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}


resource "azurerm_network_interface" "nic" {
  for_each = { for combo in flatten([
    for admin in var.admins : [
      for prefix in admin.prefixes : {
        key    = "${admin.initials}-${prefix}"
        admin  = admin
        prefix = prefix
      }
    ]
  ]) : combo.key => combo }

  name                = "${each.value.admin.initials}-${each.value.prefix}-nic"
  resource_group_name = data.azurerm_resource_group.vm-rg[each.value.admin.resource_group_name].name
  location            = var.location

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = data.azurerm_subnet.vm-subnet[each.value.admin.resource_group_name].id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }
}


resource "azurerm_linux_virtual_machine" "vm" {
  for_each = { for combo in flatten([
    for admin in var.admins : [
      for prefix in admin.prefixes : {
        key    = "${admin.initials}-${prefix}"
        admin  = admin
        prefix = prefix
      }
    ]
  ]) : combo.key => combo }

  name                  = "${each.value.admin.initials}-${each.value.prefix}-vm"
  resource_group_name   = data.azurerm_resource_group.vm-rg[each.value.admin.resource_group_name].name
  location              = var.location
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]
  size                  = "Standard_B2ms"

  os_disk {
    name                 = "${each.value.admin.initials}-${each.value.prefix}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  computer_name  = "${each.value.admin.initials}-${each.value.prefix}"
  admin_username = "${each.value.admin.initials}admin"

  admin_ssh_key {
    username   = "${each.value.admin.initials}admin"
    public_key = azapi_resource_action.ssh_public_key_gen[each.value.admin.initials].output.publicKey
  }

  tags = {
    initials = each.value.admin.initials
  }
}

#resource "azurerm_virtual_machine_extension" "create_dir" {
#  for_each             = azurerm_linux_virtual_machine.vm
#  name                 = "create-dir"
#  virtual_machine_id   = each.value.id
#  publisher            = "Microsoft.Azure.Extensions"
#  type                 = "CustomScript"
#  type_handler_version = "2.1"
#
#  settings = <<SETTINGS
#  {
#    "commandToExecute": "git clone https://github.com/pkondratowicz/lab_k8s /home/${each.value.tags["initials"]}admin/kubernetes_lab"
#  }
#  SETTINGS
#}

