variable "resource_group_name" {
    type = string
    description = "Resource group to deploy networking into."
}

variable "location" {
    type = string
    description = "Azure region."
}

variable "hub_address_space" { 
    type = list(string)
    description = "CIDR range for the hub VNet."
    default = [ "10.0.0.0/16" ]
}

variable "spoke_address_space" {
    type = list(string)
    description = "CIDR range for the spoke VNet."
    default = [ "10.1.0.0/16" ]
}

variable "tags" { 
    type = map(string)
    description = "Tags applied to all networking resources."
    default = {}
}

variable "environment" {
    type = string
    description = "Environment name (dev, prod, etc.)"
}