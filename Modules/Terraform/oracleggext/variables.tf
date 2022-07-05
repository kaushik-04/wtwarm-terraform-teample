variable "app_keyvault_name" {}

variable "Location" 			{ description = "Location / Region" }
variable "Enumerator"			{ description = "Enumrator" }
variable "App" 				{ description = "Application Name" }
variable "appid" 			{ description = "appid" }
variable "EnvType" 			{ description = "Environment Type" }
variable "AppTier" 			{ description = "AppTier" }
variable "corpuid" 			{ description = "corpuid" }
variable "IBM_AZURE_SDBA"	{
							default = "NO"
}
variable "SupportTeamID"	{
							default = "3374"
}
variable "Workload"         { description = "Workload"}

variable "SourceDB"         { 
	description = "SourceDB FQDN <workload.domain> sample as SourceDB_workload.az.3pc.pilot.com"
	default = "xxx"
}
variable "TargetDB"         { 
	description = "TargetDB FQDN <workload.domain> sample as TargetDB_workload.az.3pc.pilot.com"
	default = "xxx"
} 
# DB configs for gguser, Only for DB on Azure. DB Bounce required 
variable "ConfigDB"         { 
	description = "List of DB workloads on Azure for gguser and IC configuration. DB Bounce required. Supply as seperated with space, i.e. TargetDB_workload SourceDB_workload"
	default = "xxx"
} 
variable "OraVer"         { 
	description = "GG binary to use for Oracle DB version (og11g og12c og19c)"
	default = "og19c"
} 
variable "GGPort" 	{ 
	description = "GG Master Port"
	default = "7809"
} 
variable "DYNPortRange" 	{ 
	description = "GG Dynamic Port Range"
	default = "7851-7853"
}
