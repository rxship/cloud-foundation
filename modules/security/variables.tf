variable "resource_group_name" {
    type = string
}

variable "location" {
    type = string
}

variable "key_vault_name" {
    type = string
    description = "Globally unique key vault name."
}

variable "tags" {
    type = map(string)
    default = {}
}

variable "vnet_id" {
    type = string
    description = "VNet to link the private DNS zone to."
}

variable "private_endpoint_subnet_id" {
    type = string
    description = "Subnet where the private endpoint NIC lives."
}

variable "key_vault_admin_object_id" {
    type = string
    description = "Object ID of the identity that manages Key Vault secrets. Explicit, so it never changes based on who runs Terraform."
}