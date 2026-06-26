variable "environment" {
    type = string
    description = "Environment name (dev prodm etc)"
}

variable "location" {
    type = string
    description = "Azure region for this environment."
}

variable "key_vault_name" {
    type = string
    description = "Globally unique key vault name."
}

variable "key_vault_admin_object_id" {
  type = string
  description = "Object ID of the identity that manages Key Vault secrets. Explicit, so it never changes based on who runs Terraform."
}