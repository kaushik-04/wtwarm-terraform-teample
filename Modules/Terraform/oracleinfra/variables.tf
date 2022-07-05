variable "app_resource_group" {}
variable "app_vnet_name" {}
variable "app_keyvault_name" {}
variable "app_storage_account" {}
variable "app_law" { default = null}
variable "app_law_rg" { default = null}

variable "Location" 			{ description = "Location / Region" }
variable "Enumerator"			{ description = "Enumrator" }
variable "App" 				{ description = "Application Name" }
variable "appid" 			{ description = "appid" }
variable "EnvType" 			{ description = "Environment Type" }
variable "AppTier" 			{ description = "AppTier" }
variable "corpuid" 			{ description = "corpuid" }
variable "Workload"         { description = "Workload"}
variable "privateendpoint_proxy_name" {}
variable "privateendpoint_nva_name" {}
variable "privateendpoint_smtp_name" {}
variable "SIG_Definition" {}
variable "oracle_subnet_address" {}

variable "VM_Size" {}
variable "Disk_Type" {
    default = "Premium_LRS"
}
variable "OS_Disk_Size" {
    default = "128"
}
variable "SIG_Name" {
    default = "Oracle_SIG"
}
variable "SIG_RG" {
    default = "oracle-images-rg"
}
variable "SIG_SubscriptionID" {
	default = "a722ec0a-ab02-4541-8da5-3fe73d3d61f3"
}
variable "lbports" { 
	type = map(object({
		key = string
		port = string
	}))
	description = "Load Balancer ports"
	default = {}
}

variable "dynamic_ports" { 
	type = map(object({
		key = string
		probe-key = string
		port = string
	}))
	description = "Dynamic Load Balancer ports"
	default = {}
}

# -
# - Network Security Rules
# -
variable "security_rules" {
	type = map(object({
		key 										= string
		description                                  = string
		protocol                                     = string
		direction                                    = string
		access                                       = string
		priority                                     = number
		source_address_prefix                        = string
		source_address_prefixes                      = list(string)
		destination_address_prefix                   = string
		destination_address_prefixes                 = list(string)
		source_port_range                            = string
		source_port_ranges                           = list(string)
		destination_port_range                       = string
		destination_port_ranges                      = list(string)
		source_application_security_group_names      = list(string)
		destination_application_security_group_names = list(string)
    }))
  description = "The network security rules."
  default     = {}
}
