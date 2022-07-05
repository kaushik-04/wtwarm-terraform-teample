variable "role_definitions" {
  description = "Map of roles definitions"
  default = {
    rd1 = {
      name                       = "Network-VM-Join-Contributor"
      scope                      = "/subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44"
      actions                    = ["Microsoft.Network/virtualNetworks/subnets/read", "Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/virtualMachines/read"]
      not_actions                = null
      assignable_scopes          = ["/subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44"]
    },
    rd2 = {
      name                       = "Network-VM-Join-Reader"
      scope                      = "/subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44"
      actions                    = ["Microsoft.Network/virtualNetworks/read"]
      not_actions                = null
      assignable_scopes          = ["/subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44"]
    },
    rd3 = {
      name                       = "Network-PE-Contributor"
      scope                      = "/subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44"
      actions                    = ["Microsoft.Network/privateEndpoints/write","Microsoft.Network/virtualNetworks/read"]
      not_actions                = null
      assignable_scopes          = ["/subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44"] 
    }
  }
}

variable "role_assignments" { 
  description = "Map of roles assignments"
  default = {
    ra1 = {
      scope                      = "/subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44"
      role_definition_name       = "Network-VM-Join-Contributor"
      principal_id               = "cc61c825-6012-495c-963e-55b2240a01f1"
    }, 
    ra2 = {
      scope                      = "/subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44"
      role_definition_name       = "Network-VM-Join-Reader"
      principal_id               = "cc61c825-6012-495c-963e-55b2240a01f1"
    },
    ra3 = {
      scope                      = "/subscriptions/c6aa1fdc-66a8-446e-8b37-7794cd545e44"
      role_definition_name       = "Network-PE-Contributor"
      principal_id               = "cc61c825-6012-495c-963e-55b2240a01f1"
    }
  }
}

############################
# State File
############################ 
variable ackey {
  description = "Not required if MSI is used to authenticate to the SA where state file is"
  default = null
}