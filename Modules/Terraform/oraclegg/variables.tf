variable "app_resource_group" {}
variable "app_keyvault_name" {}
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

variable "SIG_Definition" {}
variable "SIG_SubscriptionID" {
	default = "a722ec0a-ab02-4541-8da5-3fe73d3d61f3"
}
variable "SIG_Name" {
    default = "Oracle_SIG"
}
variable "SIG_RG" {
    default = "oracle-images-rg"
}
variable "VM_Size" {}
variable "Zone"				{ 
					description = "Availability Zone 1,2,3" 
					default = "1"
					}
variable "Disk_Type" {
    default = "Premium_LRS"
}
variable "OS_Disk_Size" 		{ 
    default = "100"
    description = "OS Disk Size" 
}
variable "Data_Disks" 			{
					type = map(object({
						key = string
						size = number
						lun = string
					}))
  					description = "Map storage data disk configurations"
					default = {}
					}
variable "Cache"				{ 
					description = "Cache (ReadOnly or ReadWrite or None)" 
					default = "ReadOnly"
					}

# DB configs
#variable "DBsize" {}			
#variable "DBport" {}
#variable "AGENTPORT" {}
#variable "OMSHOST"			{ 
#	description = "OEM OMS Host" 
#	default = "oemato.it.pilot.com"
#}
#variable "ORASOFT_ENV" 			{ 
#	description = "ORASOFT_ENV" 
#	default = "prod"
#}
#variable "ORASOFT_DIR" 			{ 
#	description = "ORASOFT_DIR" 
#	default = "/orasoft/prod"
#}
#