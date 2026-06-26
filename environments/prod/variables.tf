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