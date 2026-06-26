terraform {
    backend "azurerm" {
        resource_group_name = "rg-cloudfoundation-tfstate"
        storage_account_name = "stcfstate9f42be"
        container_name = "tfstate"
        key = "prod/landingzone.tfstate"
    }
}