locals {
	rg				= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "rg", var.Workload ])
	vm				= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "vm", var.Workload ])
	des             = join("-", [ local.vm, "des" ])
	desKey          = join("-", [ local.des, "key" ])
	sa              = lower(join("", [var.App, var.EnvType, "statt", var.Workload ]))
	sa-access-key	= join("-", [ local.sa, "access", "key" ])
	sape			= join("-", [ var.appid, var.Location, var.EnvType, "st", "pe", var.Workload ])
	saadope			= join("-", [ var.appid, var.Location, var.EnvType, "stado", "pe", var.Workload ])
	sacnt			= var.Workload
	sacntpe			= join("-", [ var.appid, var.Location, var.EnvType, "stcnt", "pe", var.Workload ])
	safs			= var.Workload
	safspe			= join("-", [ var.appid, var.Location, var.EnvType, "stfs", "pe", var.Workload ])
	safsadope		= join("-", [ var.appid, var.Location, var.EnvType, "stfsado", "pe", var.Workload ])
	key_vault_id 	= data.azurerm_key_vault.key_vault.id
	tags = {
		location	= var.Location
		env		= var.EnvType
		app_id		= var.appid
		created_by	= "${var.corpuid}@pilot.com"
		automated_by	= "DBaaS@list.pilot.com"
		contact_dl	= "DBaaS@list.pilot.com"
		auto_fix	= "yes"
	}
}

data "azurerm_client_config" "current" {}

data "azurerm_virtual_network" "appvnet" {
	name = var.app_vnet_name
	resource_group_name = var.app_resource_group		
}

data "azurerm_subnet" "adosnet" {
	provider 		= azurerm.ado
	name			= var.ado_subnet_name
	virtual_network_name	= var.ado_vnet_name
	resource_group_name	= var.ado_rg_name
}

data "azurerm_key_vault" "key_vault" {
  name                = var.app_keyvault_name
  resource_group_name = var.app_resource_group
}

#Create db-specific RG
resource "azurerm_resource_group" "db-rg" {
	name		= local.rg
	location	= var.Location
	tags		= local.tags
}

resource "azurerm_storage_account" "sa" {
	name					= local.sa
	resource_group_name 	= azurerm_resource_group.db-rg.name
	location				= azurerm_resource_group.db-rg.location

	account_tier 			= "Standard"
	account_replication_type = "LRS"
	account_kind 			= "StorageV2"
	
	enable_https_traffic_only 	= true
	identity { type			= "SystemAssigned" }
	tags 					= { terraform = "true" }
}

resource "azurerm_key_vault_access_policy" "saap" {
	key_vault_id 	= data.azurerm_key_vault.key_vault.id
	tenant_id 		= data.azurerm_client_config.current.tenant_id
	object_id 		= azurerm_storage_account.sa.identity[0].principal_id

	key_permissions         = ["get", "wrapkey", "unwrapkey"]
	secret_permissions      = ["get"]
	certificate_permissions = ["get"]
	storage_permissions     = ["get"]

	depends_on = [azurerm_storage_account.sa]
}

# -
# - Store Storage Account Access Key to Key Vault Secrets
# -
resource "azurerm_key_vault_secret" "sa-secret" {
  name         = local.sa-access-key
  value        = azurerm_storage_account.sa.primary_access_key
  key_vault_id = data.azurerm_key_vault.key_vault.id
}

resource "azurerm_private_endpoint" "private_endpoints" {
  name                = local.sape
  location            = var.Location
  resource_group_name = azurerm_resource_group.db-rg.name
  subnet_id           = data.terraform_remote_state.oracleinfra.outputs.subnet-id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.sape}-connection"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
   	request_message                = null
 }
}

resource "azurerm_private_endpoint" "private_endpointsfile" {
  name                = local.safspe
  location            = var.Location
  resource_group_name = azurerm_resource_group.db-rg.name
  subnet_id           = data.terraform_remote_state.oracleinfra.outputs.subnet-id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.safspe}-connection"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["file"]
   	request_message                = null
 }
}

#This PE, ADO DNS zone and A record allows the agents to view and edit the storage account in the pipeline
resource "azurerm_private_endpoint" "private_endpoints_ado" {
  provider            = azurerm.ado 
  name                = local.saadope
  location            = var.ado_region != null ? var.ado_region : var.Location
  resource_group_name = var.ado_rg_name
  subnet_id           = data.azurerm_subnet.adosnet.id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.saadope}-connection"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
   	request_message                = null
 }
}

resource "azurerm_private_endpoint" "private_endpoints_file_ado" {
  provider 		= azurerm.ado
  name                = local.safsadope
  location            = var.ado_region != null ? var.ado_region : var.Location
  resource_group_name = var.ado_rg_name
  subnet_id           = data.azurerm_subnet.adosnet.id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.safsadope}-connection"
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = false
    subresource_names              = ["file"]
   	request_message                = null
 }
}

resource "azurerm_private_dns_a_record" "sarecord" {
	name				= azurerm_storage_account.sa.name
	resource_group_name 		= var.app_resource_group
	zone_name 			= "privatelink.blob.core.windows.net"
	ttl				= 300
	records				= azurerm_private_endpoint.private_endpoints.private_service_connection.*.private_ip_address
	tags				= local.tags
}

resource "azurerm_private_dns_a_record" "sarecordado" {
	provider 		= azurerm.ado
	name				= azurerm_storage_account.sa.name
	resource_group_name 		= var.ado_rg_name
	zone_name 			= "privatelink.blob.core.windows.net"
	ttl				= 300
	records				= azurerm_private_endpoint.private_endpoints_ado.private_service_connection.*.private_ip_address
	tags				= local.tags
}

resource "azurerm_private_dns_a_record" "filerecordado" {
	provider 		= azurerm.ado
	name				= azurerm_storage_account.sa.name
	resource_group_name 		= var.ado_rg_name
	zone_name 			= "privatelink.file.core.windows.net"
	ttl				= 300
	records				= azurerm_private_endpoint.private_endpoints_file_ado.private_service_connection.*.private_ip_address
	tags				= local.tags
}

resource "azurerm_private_dns_a_record" "filesarecord" {
	name				= azurerm_storage_account.sa.name
	resource_group_name 		= var.app_resource_group
	zone_name 			= "privatelink.file.core.windows.net"
	ttl				= 300
	records				= azurerm_private_endpoint.private_endpointsfile.private_service_connection.*.private_ip_address
	tags				= local.tags
}

resource "azurerm_storage_container" "sacnt" {
	name						= local.sacnt
	storage_account_name 		= azurerm_storage_account.sa.name
	container_access_type		= "private"
	depends_on = [azurerm_private_dns_a_record.sarecordado]
}

resource "azurerm_storage_share" "safs" {
	name						= local.safs
	storage_account_name 		= azurerm_storage_account.sa.name
	quota						= 1024
	depends_on = [azurerm_private_dns_a_record.sarecordado]
}

resource "azurerm_storage_account_network_rules" "sanr" {
  resource_group_name  = azurerm_resource_group.db-rg.name
  storage_account_name = azurerm_storage_account.sa.name

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  depends_on				 = [azurerm_storage_container.sacnt, azurerm_storage_share.safs]
}

resource "azurerm_key_vault_key" "sacmk" {
	name			= local.sa
	key_vault_id 	= local.key_vault_id
	key_type		= "RSA"
	key_size 		= 2048
	key_opts 		= [ "decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey" ]
	
	depends_on 		= [azurerm_storage_account.sa, azurerm_key_vault_access_policy.saap]
}

resource "azurerm_storage_account_customer_managed_key" "sacmk" {
	storage_account_id 	= azurerm_storage_account.sa.id
	key_vault_id 		= data.azurerm_key_vault.key_vault.id
	key_name 			= local.sa
	key_version 		= azurerm_key_vault_key.sacmk.version
	depends_on 			= [azurerm_storage_account.sa, azurerm_key_vault_key.sacmk]
}

resource "azurerm_key_vault_key" "desKey" {
	name			= local.desKey
	key_vault_id 	= local.key_vault_id
	key_type		= "RSA"
	key_size 		= 2048
	key_opts 		= [
			"decrypt",
			"encrypt",
			"sign",
			"unwrapKey",
			"verify",
			"wrapKey",
	]
}

resource "azurerm_disk_encryption_set" "des" {
	name					= local.des
	location				= var.Location
	resource_group_name 	= azurerm_resource_group.db-rg.name
	key_vault_key_id 		= azurerm_key_vault_key.desKey.id
	identity { type			= "SystemAssigned" }
}

resource "azurerm_key_vault_access_policy" "desap" {
	key_vault_id 	= local.key_vault_id
	object_id 		= azurerm_disk_encryption_set.des.identity[0].principal_id
	tenant_id 		= data.azurerm_client_config.current.tenant_id
	key_permissions = [ "wrapkey", "unwrapkey", "get" ]
}
