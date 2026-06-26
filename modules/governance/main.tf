data "azurerm_subscription" "current" {}

resource "azurerm_resource_group_policy_assignment" "allowed_locations" {
    name = "allowed-locations"
    resource_group_id = var.resource_group_id
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"

  parameters = jsonencode({
    listOfAllowedLocations = {
        value = ["canadacentral", "canadaeast"]
    }
  })
}

resource "azurerm_role_definition" "lz_operator" {
    name = "Landing Zone Operator (${var.environment})"
    scope = data.azurerm_subscription.current.id
    description = "Read all resources and restart VMs. No create, no delete."

    permissions {
        actions     = [
            "*/read",
            "Microsoft.Compute/virtualMachines/restart/action"
            ]
        not_actions = []
  }
  assignable_scopes = [data.azurerm_subscription.current.id]
}