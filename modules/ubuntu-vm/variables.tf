
variable "vnet_resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "key_vault_resource_group_name" {
  type = string
}

variable "admins" {
  type = list(object({
    initials            = string
    resource_group_name = string
    subnet_name         = string
    #subnet_cidr         = string
    prefixes = list(string)
  }))
}

