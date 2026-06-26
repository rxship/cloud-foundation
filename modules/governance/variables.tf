variable "resource_group_id" {
    type = string
    description = "Scope where the policy is assigned."
}

variable "environment" { 
    type = string
    description = "Names the custom role uniquely per env."
}

