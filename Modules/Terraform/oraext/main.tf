locals {
	rg				= join("-", [var.App, var.Location, var.EnvType, var.AppTier, "rg", var.Workload ])
	vm				= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "vm", var.Workload ])
	storage_acct    = lower(join("", [var.App, var.EnvType, "statt", var.Workload ]))

	tags = {
		location	= var.Location
		env		= var.EnvType
		app_id		= var.appid
		created_by	= "${var.corpuid}@pilot.com"
		automated_by	= "DBaaS@list.pilot.com"
		contact_dl	= "DBaaS@list.pilot.com"
		auto_fix	= "yes"
	}
	oraext 		= "cd /; rm -rf /oraext ;git clone https://oraadmin:glktsoxzxzg5z6x5fg27r6s2cm7oowz33sdluctyqihjicxrprqa@dev.azure.com/ado-azure-01/30710-DICA/_git/oraext ; export App=${var.App}; export appid=${var.appid}; export EnvType=${var.EnvType}; export AppTier=${var.AppTier}; export SIG_Definition=${var.SIG_Definition}; export Workload=${var.Workload}; export OMSHOST=${var.OMSHOST}; export corpuid=${var.corpuid}; export SupportTeamID=${var.SupportTeamID}; export DBsize=${var.DBsize}; export DBport=${var.DBport}; export AGENTPORT=${var.AGENTPORT}; export ORASOFT_ENV=${var.ORASOFT_ENV}; export ORASOFT_DIR=${var.ORASOFT_DIR}; export IBM_AZURE_SDBA=${var.IBM_AZURE_SDBA}; export Enumerator=${var.Enumerator}; export app_resource_group=${var.app_resource_group};export app_keyvault_name=${var.app_keyvault_name}; export app_recovery_vault=${var.app_recovery_vault}; export storage_acct=${local.storage_acct}; export VP_ORA_DB_BLOCK_SIZE=${var.VP_ORA_DB_BLOCK_SIZE}; export VP_ORA_CHARACTER_SET=${var.VP_ORA_CHARACTER_SET};export VP_ORA_NAT_CHARACTER_SET=${var.VP_ORA_NAT_CHARACTER_SET}; env > /home/oracle/oraext.tfvars ;/oraext/oraext.sh"
}

data "azurerm_client_config" "current" {}

data "azurerm_virtual_machine" "dbvm" {
	name = local.vm
	resource_group_name = local.rg
}

resource "azurerm_virtual_machine_extension" "oraext" {
	name                            = "oraext"
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