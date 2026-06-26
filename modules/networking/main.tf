#----HUB----
resource "azurerm_virtual_network" "hub" {
    name = "vnet-hub"
  resource_group_name = var.resource_group_name
  location = var.location
  address_space = var.hub_address_space
  tags =  var.tags
}

resource "azurerm_subnet" "hub_shared" {
    name = "snet-shared-services"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes = ["10.0.1.0/24"]
}

#----SPOKE----
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.spoke_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "spoke_workload" {
  name                 = "snet-workload"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.1.0/24"]
}

#----PEERING----
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

#----NSG on the workload subnet----
resource "azurerm_network_security_group" "workload" {
  name                = "nsg-workload"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-Admin-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  subnet_id                 = azurerm_subnet.spoke_workload.id
  network_security_group_id = azurerm_network_security_group.workload.id
}

resource "azurerm_subnet" "private_endpoints" {
  name = "snet-private-endpoints"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes = ["10.1.2.0/24"]
}