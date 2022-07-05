variable "app_resource_group" {}
variable "Location" 			{ description = "Location / Region" }
variable "Enumerator"			{ description = "Enumrator" }
variable "App" 				{ description = "Application Name" }
variable "appid" 			{ description = "appid" }
variable "EnvType" 			{ description = "Environment Type" }
variable "AppTier" 			{ description = "AppTier" }
variable "corpuid" 			{ description = "corpuid" }
variable "Workload"         { description = "Workload"}
variable "deskeycnt"        { 
                            description = "disk encryption Set Key count to allow override when for keyvault soft delete"
                            default = "1"
                            }
variable "app_vnet_name" {}
variable "ado_rg_name" {}
variable "ado_vnet_name" {}
variable "ado_subnet_name" {}
variable "app_keyvault_name" {}
variable "ado_subscription_id" {}
variable "ado_region"       { default = null }