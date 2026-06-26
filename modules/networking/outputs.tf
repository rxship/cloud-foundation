output "hub_vnet_id" {
    value = azurerm_virtual_network.hub.id
    description = "Resouce ID of the hub VNet."
}

output "workload_subnet_id" {
    value = azurerm_subnet.spoke_workload.id
    description = "Subnet where workloads and NSGs attach next."
  
}

output "spoke_vnet_id" { 
    value = azurerm_virtual_network.spoke.id
}

output "private_endpoints_subnet_id" {
    value = azurerm_subnet.private_endpoints.id
}