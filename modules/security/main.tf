# reads who you currently are (tenant + object id). creates nothing.
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
    name                         = var.key_vault_name
    resource_group_name          = var.resource_group_name
    location                     = var.location
    tenant_id                    = data.azurerm_client_config.current.tenant_id
    sku_name                     = "standard"
    rbac_authorization_enabled   = true
    purge_protection_enabled     = false
    soft_delete_retention_days   = 7
    tags                         = var.tags
}

# grant the identity running terraform the ability to manage secrets
resource "azurerm_role_assignment" "kv_secrets_officer" {
    scope                       =  azurerm_key_vault.main.id
    role_definition_name        =  "Key Vault Secrets Officer"
    principal_id                  =  var.key_vault_admin_object_id
}

# private DNS zone name for key vault is fixed by azure
resource "azurerm_private_dns_zone" "kv" {
    name = "privatelink.vaultcore.azure.net"
    resource_group_name = var.resource_group_name
    tags = var.tags
}

# link the zone to the vnet so queries from inside it use this zone
resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name                  = "kv-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = var.vnet_id
}

# The private endpoint: a NIC in your subnet representing the vault.
resource "azurerm_private_endpoint" "kv" {
  name                = "pe-${var.key_vault_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]   # "vault" is Key Vault's group id
    is_manual_connection           = false
  }

  # This auto-registers the A record in the zone -> the private IP.
  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv.id]
  }
}
