locals {
	rg				= join("-", [var.App, var.Location, var.EnvType, var.AppTier, "rg", var.Workload ])
	ipconfig		= join("-", [ var.Workload, "ipconfig" ])
	os_disk			= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "os", var.Workload ])
	vm				= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "vm", var.Workload ])
	nic				= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "nic", var.Workload ])
	tags = {
		location	= var.Location
		env		= var.EnvType
		app_id		= var.appid
		created_by	= "${var.corpuid}@pilot.com"
		automated_by	= "DBaaS@list.pilot.com"
		contact_dl	= "DBaaS@list.pilot.com"
		auto_fix	= "yes"
	}
	oraext 		= "cd /; rm -rf /oraext ;git clone https://oraadmin:glktsoxzxzg5z6x5fg27r6s2cm7oowz33sdluctyqihjicxrprqa@dev.azure.com/ado-azure-01/30710-DICA/_git/oraext ; export App=${var.App}; export appid=${var.appid}; export EnvType=${var.EnvType}; export AppTier=${var.AppTier}; export Workload=${var.Workload}; export corpuid=${var.corpuid}; export Enumerator=${var.Enumerator}; export app_keyvault_name=${var.app_keyvault_name}; export SourceDB=${var.SourceDB}; export TargetDB=${var.TargetDB}; export ConfigDB=${var.ConfigDB}; export OraVer=${var.OraVer}; export GGPort=${var.GGPort}; export DYNPortRange=${var.DYNPortRange}; env > /home/oraadmin/oragg.tfvars ;/oraext/oragg.sh"
}

data "azurerm_client_config" "current" {}

data "azurerm_virtual_machine" "dbvm" {
	name = local.vm
	resource_group_name = local.rg
}

resource "azurerm_virtual_machine_extension" "oracleggext" {
	name                            = "oracleggext"
	virtual_machine_id              = data.azurerm_virtual_machine.dbvm.id
	publisher                       = "Microsoft.Azure.Extensions"
	type                            = "CustomScript"
	type_handler_version            = "2.0"
	
	settings = <<SETTINGS
		{
		"commandToExecute": "${local.oraext}" 
		}
SETTINGS
	tags                            = local.tags
	timeouts {
		create = "90m"
		update = "30m"
		read   = "10m"
		delete = "30m"
		}
}