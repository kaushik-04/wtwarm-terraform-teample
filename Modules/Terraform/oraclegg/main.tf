locals {
	rg				= join("-", [var.App, var.Location, var.EnvType, var.AppTier, "rg", var.Workload])
	ipconfig		= join("-", [ var.Workload, "ipconfig" ])
	os_disk			= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "os", var.Workload])
	vm				= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "vm", var.Workload ])
	nic				= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "nic", var.Workload ])
	des             = join("-", [ local.vm, "des" ])
	sa              = lower(join("", [var.App, var.EnvType, "statt", var.Workload ]))
	sape			= join("-", [ var.appid, var.Location, var.EnvType, "st", "pe", var.Workload ])
	law-rg			= var.app_law_rg != null ? var.app_law_rg : var.app_resource_group
	law				= var.app_law != null ? var.app_law : join("-", [ var.App, var.Location, var.EnvType, "law" ])
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

data "azurerm_key_vault" "key_vault" {
  name                = var.app_keyvault_name
  resource_group_name = var.app_resource_group
}

data "azurerm_shared_image" "image" {
	provider				= azurerm.SIG
	name                    = var.SIG_Definition
	gallery_name            = var.SIG_Name
	resource_group_name     = var.SIG_RG
}

data "azurerm_disk_encryption_set" "des" {
	name			= local.des
	resource_group_name 	= local.rg
}

data "azurerm_key_vault_secret" "pubkey" {
	name = data.terraform_remote_state.oracleinfra.outputs.ssh-kv-pubkey-name
	key_vault_id = local.key_vault_id
}

data "azurerm_storage_account" "sa" {
  name                = local.sa
  resource_group_name = local.rg
}

data "azurerm_log_analytics_workspace" "law" {
	name				= local.law
	resource_group_name = local.law-rg
}

resource "azurerm_network_interface" "nic" {
        name                    = local.nic
        resource_group_name     = local.rg
        location                = var.Location

        ip_configuration {
                name                            = local.ipconfig
                subnet_id                       = data.terraform_remote_state.oracleinfra.outputs.subnet-id
                private_ip_address_allocation   = "Dynamic"
        }
        #enable_accelerated_networking           = var.Accelerated_Networking
        tags                    = local.tags
}

resource "azurerm_network_interface_security_group_association" "nsga" {
	network_interface_id 		= azurerm_network_interface.nic.id
	network_security_group_id 	= data.terraform_remote_state.oracleinfra.outputs.nsg-id
}

resource "azurerm_network_interface_backend_address_pool_association" "lbbepa" {
	network_interface_id    = azurerm_network_interface.nic.id
	ip_configuration_name   = local.ipconfig
	backend_address_pool_id = data.terraform_remote_state.oracleinfra.outputs.lbbep-id
}

resource "azurerm_network_interface_backend_address_pool_association" "oblbbepa" {
	network_interface_id    = azurerm_network_interface.nic.id
	ip_configuration_name   = local.ipconfig
	backend_address_pool_id = data.terraform_remote_state.oracleinfra.outputs.oblbbep-id
}

resource "azurerm_linux_virtual_machine" "vm" {
	name			= local.vm
	computer_name		= var.Workload
	resource_group_name 	= local.rg
	location		= var.Location
	size			= var.VM_Size
	zone			= var.Zone
	admin_username		= "oraadmin"
	admin_ssh_key {
		username	= "oraadmin"
		public_key	= data.azurerm_key_vault_secret.pubkey.value
	}
	network_interface_ids	= [ azurerm_network_interface.nic.id ]
	os_disk {
		name			= local.os_disk
		caching			= "ReadWrite"
		storage_account_type	= var.Disk_Type
		disk_size_gb		= var.OS_Disk_Size
		disk_encryption_set_id	= data.azurerm_disk_encryption_set.des.id
	}

	boot_diagnostics {
		storage_account_uri = data.azurerm_storage_account.sa.primary_blob_endpoint
	}


	identity {
    	type = "SystemAssigned"
  	}
	  
	source_image_id			= data.azurerm_shared_image.image.id
	tags 				= local.tags
}

resource "azurerm_key_vault_access_policy" "dbvmmsi" {
	key_vault_id 	= local.key_vault_id
	object_id 		= azurerm_linux_virtual_machine.vm.identity[0].principal_id
	tenant_id 		= data.azurerm_client_config.current.tenant_id
	key_permissions = [ "wrapkey", "unwrapkey", "get" ]
	#lifecycle { prevent_destroy 	= true }
}

resource "azurerm_managed_disk" "datadisk" {
	for_each			= var.Data_Disks
	name				= "${var.App}-${var.Location}-${var.EnvType}-${var.AppTier}-data-${var.Workload}-${each.value["key"]}"
	resource_group_name 		= local.rg
	location			= var.Location
	storage_account_type		= var.Disk_Type
	disk_size_gb			= each.value["size"]
	disk_encryption_set_id		= data.azurerm_disk_encryption_set.des.id
	create_option 			= "Empty"
	zones				= [ var.Zone ]
	tags 				= local.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "attachdisks" {
	for_each			= var.Data_Disks
	managed_disk_id 		= azurerm_managed_disk.datadisk[each.key].id
	virtual_machine_id 		= azurerm_linux_virtual_machine.vm.id
	lun 				= each.value["lun"]
	caching				= var.Cache
	#caching 			= "ReadOnly"
	#caching 			= "ReadWrite"
	#write_accelerator_enabled	= true
}

resource "azurerm_virtual_machine_extension" "network_watcher" {
  name                       = "network-watcher"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.NetworkWatcher"
  type                       = "NetworkWatcherAgentLinux"
  type_handler_version       = "1.4"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_linux_virtual_machine.vm]
}

resource "azurerm_virtual_machine_extension" "vm_insights" {
  name                       = "vm-insights"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_linux_virtual_machine.vm]
}

resource "azurerm_virtual_machine_extension" "log_analytics" {
  name                 = "log-analytics"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.EnterpriseCloud.Monitoring"
  type                 = "OmsAgentForLinux"
  type_handler_version = "1.13"
  settings = <<SETTINGS
    {
      "workspaceId": "${data.azurerm_log_analytics_workspace.law.workspace_id}"       
    }
  SETTINGS
  protected_settings = <<SETTINGS
    {
    	"workspaceKey": "${data.azurerm_log_analytics_workspace.law.primary_shared_key}"
    }
  SETTINGS
  tags = local.tags
  depends_on = [azurerm_linux_virtual_machine.vm]
}

resource "azurerm_virtual_machine_extension" "storage" {
  name                       = "storage-diagnostics"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Diagnostics"
  type                       = "LinuxDiagnostic"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = true
  #settings = each.value.diagnostics_storage_config_path == null ? templatefile("${path.module}/Diagnostics/config.json", merge({ vm_id = (local.vm_state_exists == true ? lookup(data.terraform_remote_state.virtualmachine.outputs.linux_vm_id_map, each.value.virtual_machine_name) : lookup(data.azurerm_virtual_machine.this, each.key)["id"]) }, local.diagnostics_storage_config_parms)) : templatefile("${path.root}${each.value.diagnostics_storage_config_path}", merge({ vm_id = (local.vm_state_exists == true ? lookup(data.terraform_remote_state.virtualmachine.outputs.linux_vm_id_map, each.value.virtual_machine_name) : lookup(data.azurerm_virtual_machine.this, each.key)["id"]) }, local.diagnostics_storage_config_parms))
  settings = templatefile("${path.module}/Diagnostics/config.json", {vm_id = "${azurerm_linux_virtual_machine.vm.id}", storage_account = "${data.azurerm_storage_account.sa.name}", log_level_config = "LOG_DEBUG"})
  protected_settings = <<SETTINGS
    {
      "storageAccountName": "${data.azurerm_storage_account.sa.name}",
      "storageAccountSasToken": "${data.azurerm_storage_account.sa.primary_access_key}",
      "storageAccountEndPoint": "${data.azurerm_storage_account.sa.primary_connection_string}",
      "sinksConfig": {
        "sink": [
          {
              "name": "SyslogJsonBlob",
              "type": "JsonBlob"
          },
          {
              "name": "LinuxCpuJsonBlob",
              "type": "JsonBlob"
          }
        ]
      }
    }
  SETTINGS
  tags = local.tags
  depends_on = [azurerm_linux_virtual_machine.vm]
}
