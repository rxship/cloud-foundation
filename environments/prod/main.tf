resource "azurerm_resource_group" "lz" {
    name = "rg-cloudfoundation-${var.environment}"
    location = var.location

    tags = {
        project = "cloud-foundation"
        environment = var.environment
        managed_by = "terraform"
    }
}

module "networking" {
    source = "../../modules/networking"
    
    resource_group_name = azurerm_resource_group.lz.name
    location = azurerm_resource_group.lz.location
    tags = azurerm_resource_group.lz.tags
    environment = var.environment
}

module "security" {
    source = "../../modules/security"

    resource_group_name = azurerm_resource_group.lz.name
    location = azurerm_resource_group.lz.location
    key_vault_name = var.key_vault_name
    tags = azurerm_resource_group.lz.tags
    vnet_id = module.networking.spoke_vnet_id
    private_endpoint_subnet_id = module.networking.private_endpoints_subnet_id

}

module "governance" {
    source = "../../modules/governance"
    resource_group_id = azurerm_resource_group.lz.id
    environment = var.environment
}