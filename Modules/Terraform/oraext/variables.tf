variable "app_resource_group" {} 
variable "app_keyvault_name" {}
variable "app_recovery_vault" { default = null }

variable "Location" 			{ description = "Location / Region" }
variable "Enumerator"			{ description = "Enumrator" }
variable "App" 				{ description = "Application Name" }
variable "appid" 			{ description = "appid" }
variable "EnvType" 			{ description = "Environment Type" }
variable "AppTier" 			{ description = "AppTier" }
variable "corpuid" 			{ description = "corpuid" }
variable "IBM_AZURE_SDBA"	{ default = "NO" }
variable "SupportTeamID"	{ default = "3374"}
variable "Workload"         { description = "Workload"}
variable "SIG_Definition" {}

# DB configs
variable "DBsize" {}			
variable "DBport" {}
variable "AGENTPORT" {}
variable "VP_ORA_DB_BLOCK_SIZE" { default = "8192" }
variable "VP_ORA_CHARACTER_SET" { default = "AL32UTF8" }
variable "VP_ORA_NAT_CHARACTER_SET" { default = "AL16UTF16" }

variable "OMSHOST"			{ 
	description = "OEM OMS Host" 
	default = "oemato.it.pilot.com"
}
variable "ORASOFT_ENV" 			{ 
	description = "ORASOFT_ENV" 
	default = "prod"
}
variable "ORASOFT_DIR" 			{ 
	description = "ORASOFT_DIR" 
	default = "/orasoft/prod"
}