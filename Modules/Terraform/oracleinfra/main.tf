
locals {
	#Prefix       	= join("-", [ var.App, var.Location, var.EnvType, var.AppTier ])
	rg				= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "rg", var.Enumerator ])
	lb              = join("-", [ var.App, var.Location, var.EnvType, "lb", var.Enumerator ])
	lbfeip          = join("-", [ var.App, var.Location, var.EnvType, "lbfeip", var.Enumerator ])
	lbbep           = join("-", [ var.App, var.Location, var.EnvType, "lbbep", var.Enumerator ])
	oblb            = join("-", [ var.App, var.Location, var.EnvType, "elb", var.Enumerator ])
	oblbip          = join("-", [ var.App, var.Location, var.EnvType, "pip", var.Enumerator ])
	oblbbep         = join("-", [ var.App, var.Location, var.EnvType, "elbbep", var.Enumerator ])
	obrule			= join("-", [ var.App, var.Location, var.EnvType, "elbrule", var.Enumerator ])
	pls             = join("-", [ var.appid, var.Location, var.EnvType, var.AppTier, "pls", var.Enumerator ])
	snet			= join("-", [ var.Location, var.appid, var.EnvType, "vnet", var.AppTier, "snet", var.Enumerator ])
	kvpe            = join("-", [ var.appid, var.Location, var.EnvType, "kv", "pe", var.Enumerator ])
	nsg				= join("-", [ var.App, var.EnvType, var.AppTier, "nsg", var.Enumerator ])
	ipconfig		= join("-", [ var.Workload, "ipconfig", var.Enumerator ])
	os_disk			= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "os", var.Workload, var.Enumerator ])
	vm				= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "vm", var.Workload, var.Enumerator ])
	nic				= join("-", [ var.App, var.Location, var.EnvType, var.AppTier, "nic", var.Workload, var.Enumerator ])
	des             = join("-", [ local.vm, "des" ])
	desKey          = join("-", [ local.des, "key" ])
	sa              = lower(join("", [var.App, var.EnvType, "statt", var.Enumerator ]))
	key_vault_id 	= data.azurerm_key_vault.key_vault.id
	law-rg			= var.app_law_rg != null ? var.app_law_rg : var.app_resource_group
	law				= var.app_law != null ? var.app_law : join("-", [ var.App, var.Location, var.EnvType, "law" ])
	jump-ext		= "cd /; rm -rf /oraext; git clone https://oraadmin:glktsoxzxzg5z6x5fg27r6s2cm7oowz33sdluctyqihjicxrprqa@dev.azure.com/ado-azure-01/30710-DICA/_git/oraext ;export key_vault_id=${local.key_vault_id} ; export vm=${local.vm} ;export Enumerator=${var.Enumerator}; export app_keyvault_name=${var.app_keyvault_name}; env > /home/oraadmin/jumpext.tfvars ;/oraext/jumpext.sh"
	tags 			= {
		location	= var.Location
		env			= var.EnvType
		app_id		= var.appid
		created_by	= "${var.corpuid}@pilot.com"
		automated_by = "DBaaS@list.pilot.com"
		contact_dl	= "DBaaS@list.pilot.com"
		auto_fix	= "yes"
	}
}

data "azurerm_client_config" "current" {}

data "azurerm_shared_image" "image" {
	provider 				= azurerm.SIG
	name                    = var.SIG_Definition
	gallery_name            = var.SIG_Name
	resource_group_name     = var.SIG_RG
}

data "azurerm_virtual_network" "appvnet" {
	name = var.app_vnet_name
	resource_group_name = var.app_resource_group		
}

data "azurerm_key_vault" "key_vault" {
  name                = var.app_keyvault_name
  resource_group_name = var.app_resource_group
}

data "azurerm_private_endpoint_connection" "nva" {
  name                = var.privateendpoint_nva_name
  resource_group_name = var.app_resource_group
}

data "azurerm_private_endpoint_connection" "smtp" {
  name                = var.privateendpoint_smtp_name
  resource_group_name = var.app_resource_group
}

data "azurerm_private_endpoint_connection" "proxy" {
  name                = var.privateendpoint_proxy_name
  resource_group_name = var.app_resource_group
}

data "azurerm_storage_account" "sa" {
  name                = var.app_storage_account
  resource_group_name = var.app_resource_group
}

data "azurerm_log_analytics_workspace" "law" {
	name				= local.law
	resource_group_name = local.law-rg
}

resource "azurerm_resource_group" "rg" {
        name            = local.rg
        location        = var.Location
        tags            = local.tags
}

#####
# DNS for Oracle
#####
# resource "azurerm_private_dns_zone" "svc-local" {
# 	name				= "svc.local"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_zone_virtual_network_link" "svc-local" {
# 	name				= "svc.local"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	private_dns_zone_name		= azurerm_private_dns_zone.svc-local.name
# 	virtual_network_id 			= data.azurerm_virtual_network.appvnet.id
# 	tags					= local.tags
# }
# 
# resource "azurerm_private_dns_a_record" "svc-local" {
# 	name				= "proxy.conexus"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	zone_name 			= azurerm_private_dns_zone.svc-local.name
# 	ttl				= 300
# 	records				= data.azurerm_private_endpoint_connection.proxy.private_service_connection.*.private_ip_address
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_zone" "az-3pc-att-com" {
# 	name				= "az.3pc.pilot.com"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_zone_virtual_network_link" "az-3pc-att-com" {
# 	name				= "az.3pc.pilot.com"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	private_dns_zone_name		= azurerm_private_dns_zone.az-3pc-att-com.name
# 	virtual_network_id 		= data.azurerm_virtual_network.appvnet.id
# 	registration_enabled		= true
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_a_record" "nva-az-3pc-att-com" {
# 	name				= "nva"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	zone_name 			= azurerm_private_dns_zone.az-3pc-att-com.name
# 	ttl				= 300
# 	records				= data.azurerm_private_endpoint_connection.nva.private_service_connection.*.private_ip_address
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_a_record" "smtp-az-3pc-att-com" {
# 	name				= "smtp"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	zone_name 			= azurerm_private_dns_zone.az-3pc-att-com.name
# 	ttl				= 300
# 	records				= data.azurerm_private_endpoint_connection.smtp.private_service_connection.*.private_ip_address
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_zone" "it-att-com" {
# 	name				= "it.pilot.com"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_zone_virtual_network_link" "it-att-com" {
# 	name				= "it.pilot.com"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	private_dns_zone_name		= azurerm_private_dns_zone.it-att-com.name
# 	virtual_network_id 		= data.azurerm_virtual_network.appvnet.id
# 	registration_enabled		= false
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_a_record" "odmsvr-it-att-com" {
# 	name				= "odmsvr"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	zone_name 			= azurerm_private_dns_zone.it-att-com.name
# 	ttl				= 300
# 	records				= data.azurerm_private_endpoint_connection.nva.private_service_connection.*.private_ip_address
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_a_record" "srmupld-it-att-com" {
# 	name				= "srmupld"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	zone_name 			= azurerm_private_dns_zone.it-att-com.name
# 	ttl				= 300
# 	records				= data.azurerm_private_endpoint_connection.smtp.private_service_connection.*.private_ip_address
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_a_record" "srmupld2-it-att-com" {
# 	name				= "srmupld2"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	zone_name 			= azurerm_private_dns_zone.it-att-com.name
# 	ttl				= 300
# 	records				= data.azurerm_private_endpoint_connection.smtp.private_service_connection.*.private_ip_address
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_zone" "vci-att-com" {
# 	name				= "vci.pilot.com"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_zone_virtual_network_link" "vci-att-com" {
# 	name				= "vci.pilot.com"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	private_dns_zone_name		= azurerm_private_dns_zone.vci-att-com.name
# 	virtual_network_id 		= data.azurerm_virtual_network.appvnet.id
# 	registration_enabled		= false
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_a_record" "zlp05473-vci-att-com" {
# 	name				= "zlp05473"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	zone_name 			= azurerm_private_dns_zone.vci-att-com.name
# 	ttl				= 300
# 	records				= data.azurerm_private_endpoint_connection.nva.private_service_connection.*.private_ip_address
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_zone" "kmdc-att-com" {
# 	name				= "kmdc.pilot.com"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_zone_virtual_network_link" "kmdc-att-com" {
# 	name				= "kmdc.pilot.com"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	private_dns_zone_name		= azurerm_private_dns_zone.kmdc-att-com.name
# 	virtual_network_id 		= data.azurerm_virtual_network.appvnet.id
# 	registration_enabled		= false
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_a_record" "p40rm1d1-kmdc-att-com" {
# 	name				= "p4orm1d1"
# 	resource_group_name 		= azurerm_resource_group.rg.name
# 	zone_name 			= azurerm_private_dns_zone.kmdc-att-com.name
# 	ttl				= 300
# 	records				= data.azurerm_private_endpoint_connection.nva.private_service_connection.*.private_ip_address
# 	tags				= local.tags
# }

# resource "azurerm_private_dns_zone" "fsdns" {
# 	name				= "privatelink.file.core.windows.net"
# 	resource_group_name 		= var.app_resource_group
# 	tags				= local.tags
# }
# 
# resource "azurerm_private_dns_zone_virtual_network_link" "fsdnslink" {
# 	name				= "privatelink.file.core.windows.net"
# 	resource_group_name 		= var.app_resource_group
# 	private_dns_zone_name		= azurerm_private_dns_zone.fsdns.name
# 	virtual_network_id 		= data.azurerm_virtual_network.appvnet.id
# 	tags				= local.tags
# }

#####
# Oracle "Shared" Infra
#####

resource "azurerm_subnet" "snet" {
	name					= local.snet
	resource_group_name 	= var.app_resource_group
	virtual_network_name	= var.app_vnet_name
	address_prefix			= var.oracle_subnet_address
	enforce_private_link_endpoint_network_policies	= true
	enforce_private_link_service_network_policies	= true
}

resource "azurerm_private_endpoint" "private_endpoints" {
  name                = local.kvpe
  location            = var.Location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.snet.id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.kvpe}-connection"
    private_connection_resource_id = local.key_vault_id
    is_manual_connection           = false
    subresource_names              = ["vault"]
    request_message                = null
  }

}

resource "azurerm_lb" "lb" {
	name					= local.lb
	location				= var.Location
	resource_group_name 	= azurerm_resource_group.rg.name
	sku 					= "Standard"
	frontend_ip_configuration {
		name				= local.lbfeip
		subnet_id			= azurerm_subnet.snet.id
	}
	#lifecycle 		{ prevent_destroy = true }
	tags 					= local.tags
}

resource "azurerm_lb_backend_address_pool" "lbbep" {
	name					= local.lbbep
	resource_group_name 	= azurerm_resource_group.rg.name
	loadbalancer_id			= azurerm_lb.lb.id
	#lifecycle 		{ prevent_destroy = true }
}

resource "azurerm_lb_probe" "lbprobe" {
	for_each			= var.lbports
	name				= each.value["key"]
	resource_group_name = azurerm_resource_group.rg.name
	loadbalancer_id 	= azurerm_lb.lb.id
	port 				= each.value["port"]
}

resource "azurerm_lb_rule" "lbrule" {
	for_each				= var.lbports
	name					= each.value["key"]
	resource_group_name 	= azurerm_resource_group.rg.name
	loadbalancer_id 		= azurerm_lb.lb.id
	protocol 				= "Tcp"
	frontend_port 			= each.value["port"]
	backend_port 			= each.value["port"]
	backend_address_pool_id = azurerm_lb_backend_address_pool.lbbep.id
	frontend_ip_configuration_name = local.lbfeip
	probe_id 				= azurerm_lb_probe.lbprobe[each.key].id
}

resource "azurerm_lb_rule" "dynamic_rule" {
	for_each				= var.dynamic_ports
	name					= each.value["key"]
	resource_group_name 	= azurerm_resource_group.rg.name
	loadbalancer_id 		= azurerm_lb.lb.id
	protocol 				= "Tcp"
	frontend_port 			= each.value["port"]
	backend_port 			= each.value["port"]
	backend_address_pool_id = azurerm_lb_backend_address_pool.lbbep.id
	frontend_ip_configuration_name = local.lbfeip
	probe_id 				= azurerm_lb_probe.lbprobe[each.value["probe-key"]].id
}

resource "azurerm_private_link_service" "pls" {
	name			= local.pls
	resource_group_name 	= azurerm_resource_group.rg.name
	location		= azurerm_resource_group.rg.location
	load_balancer_frontend_ip_configuration_ids = [azurerm_lb.lb.frontend_ip_configuration[0].id]
	nat_ip_configuration {
		name 		= "primary"
		subnet_id	= azurerm_subnet.snet.id
		primary 	= true
	}
	#lifecycle 		{ prevent_destroy = true }
	tags 			= local.tags
}

resource "azurerm_network_interface" "nic" {
        name                    = local.nic
        resource_group_name     = azurerm_resource_group.rg.name
        location                = azurerm_resource_group.rg.location

        ip_configuration {
                name                            = local.ipconfig
                subnet_id                       = azurerm_subnet.snet.id
                private_ip_address_allocation   = "Dynamic"
        }
        #enable_accelerated_networking           = var.Accelerated_Networking
        tags                    = local.tags
}

resource "azurerm_network_security_group" "nsg" {
	name				= local.nsg
	resource_group_name = azurerm_resource_group.rg.name
	location			= azurerm_resource_group.rg.location
	tags				= local.tags
}

resource "azurerm_network_security_rule" "nsgrules" {
	for_each 						= var.security_rules
	resource_group_name 			= azurerm_resource_group.rg.name
	network_security_group_name		= azurerm_network_security_group.nsg.name
	name 							= each.key
	description						= each.value.description
	protocol                        = each.value.protocol
	direction                       = each.value.direction
	access                          = each.value.access
	priority                        = each.value.priority
	source_address_prefix           = each.value.source_address_prefix
	source_address_prefixes         = each.value.source_address_prefixes
	destination_address_prefix      = each.value.destination_address_prefix
	destination_address_prefixes    = each.value.destination_address_prefixes
	source_port_range               = each.value.source_port_range
	source_port_ranges              = each.value.source_port_ranges
	destination_port_range          = each.value.destination_port_range
	destination_port_ranges         = each.value.destination_port_ranges
	source_application_security_group_ids      = each.value.source_application_security_group_names
	destination_application_security_group_ids = each.value.destination_application_security_group_names
}

resource "azurerm_subnet_network_security_group_association" "nsg-snet" {
	subnet_id                 = azurerm_subnet.snet.id
	network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "nsga" {
	network_interface_id 		= azurerm_network_interface.nic.id
	network_security_group_id 	= azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "oblbip" {
	name			= local.oblbip
	location		= azurerm_resource_group.rg.location
	resource_group_name 	= azurerm_resource_group.rg.name
	allocation_method	= "Static"
	sku 			= "Standard"
	tags 			= local.tags
}

resource "azurerm_lb" "oblb" {
	name					= local.oblb
	location				= azurerm_resource_group.rg.location
	resource_group_name 	= azurerm_resource_group.rg.name
	sku 					= "Standard"
	frontend_ip_configuration {
		name				= local.oblbip
		public_ip_address_id	= azurerm_public_ip.oblbip.id
	}
	tags 			= local.tags
}

resource "azurerm_lb_backend_address_pool" "oblbbep" {
	name					= local.oblbbep
	resource_group_name 	= azurerm_resource_group.rg.name
	loadbalancer_id			= azurerm_lb.oblb.id
}

resource "azurerm_lb_outbound_rule" "obrule" {
	name					= local.obrule
	resource_group_name 	= azurerm_resource_group.rg.name
	loadbalancer_id			= azurerm_lb.oblb.id
	protocol 				= "All"
	idle_timeout_in_minutes	= "15"
	allocated_outbound_ports = "128"
	backend_address_pool_id = azurerm_lb_backend_address_pool.oblbbep.id
	frontend_ip_configuration {
		name		= local.oblbip
	}
}

resource "azurerm_network_interface_backend_address_pool_association" "lbbepa" {
	network_interface_id    = azurerm_network_interface.nic.id
	ip_configuration_name   = local.ipconfig
	backend_address_pool_id = azurerm_lb_backend_address_pool.lbbep.id
}

resource "azurerm_network_interface_backend_address_pool_association" "oblbbepa" {
	network_interface_id    = azurerm_network_interface.nic.id
	ip_configuration_name   = local.ipconfig
	backend_address_pool_id = azurerm_lb_backend_address_pool.oblbbep.id
}

#Create Jumpbox
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "azurerm_key_vault_secret" "pubkey" {
  name         = "${local.vm}-id-rsa-pub"
  value        = tls_private_key.this.public_key_openssh
  key_vault_id = local.key_vault_id

  lifecycle {
    ignore_changes = [value]
  }

  depends_on = [tls_private_key.this]
}

resource "azurerm_key_vault_secret" "this" {
  name         = "${local.vm}-id-rsa"
  value        = tls_private_key.this.private_key_pem
  key_vault_id = local.key_vault_id

  lifecycle {
    ignore_changes = [value]
  }

  depends_on = [tls_private_key.this]
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
	#lifecycle { prevent_destroy = true }
}

resource "azurerm_disk_encryption_set" "des" {
	name					= local.des
	location				= var.Location
	resource_group_name 	= azurerm_resource_group.rg.name
	key_vault_key_id 		= azurerm_key_vault_key.desKey.id
	identity { type			= "SystemAssigned" }
	#lifecycle { prevent_destroy 	= true }
}

resource "azurerm_key_vault_access_policy" "desap" {
	key_vault_id 	= local.key_vault_id
	object_id 		= azurerm_disk_encryption_set.des.identity[0].principal_id
	tenant_id 		= data.azurerm_client_config.current.tenant_id
	key_permissions = [ "wrapkey", "unwrapkey", "get" ]
	#lifecycle { prevent_destroy 	= true }
}

resource "azurerm_linux_virtual_machine" "vm" {
	name				= local.vm
	#computer_name		= var.Workload
	resource_group_name = azurerm_resource_group.rg.name
	location			= azurerm_resource_group.rg.location
	size				= var.VM_Size
	admin_username		= "oraadmin"
	admin_ssh_key {
		username		= "oraadmin"
		public_key		= azurerm_key_vault_secret.pubkey.value
	}
	#custom_data		= file(".ssh/sshkey.txt")
	network_interface_ids	= [ azurerm_network_interface.nic.id ]
	os_disk {
		name			= local.os_disk
		caching			= "ReadWrite"
		storage_account_type	= var.Disk_Type
		disk_size_gb		= var.OS_Disk_Size
		disk_encryption_set_id	= azurerm_disk_encryption_set.des.id
	}

	boot_diagnostics {
		storage_account_uri = data.azurerm_storage_account.sa.primary_blob_endpoint
	}

	identity {
		type = "SystemAssigned"
  	}

	source_image_id		= data.azurerm_shared_image.image.id
	tags 				= local.tags
}

resource "azurerm_key_vault_access_policy" "jumpvmmsi" {
	key_vault_id 	= local.key_vault_id
	object_id 		= azurerm_linux_virtual_machine.vm.identity[0].principal_id
	tenant_id 		= data.azurerm_client_config.current.tenant_id
	key_permissions = [ "wrapkey", "unwrapkey", "get" ]
	#lifecycle { prevent_destroy 	= true }
}

resource "azurerm_lb_nat_rule" "ssh-nat" {
	resource_group_name 		= azurerm_resource_group.rg.name
	loadbalancer_id 		= azurerm_lb.lb.id
	name 				= "jump-ssh"
	protocol 			= "Tcp"
	frontend_port 			= 22 
	backend_port 			= 22
	frontend_ip_configuration_name 	= local.lbfeip
}

resource "azurerm_network_interface_nat_rule_association" "ssh-nat" {
	network_interface_id  		= azurerm_network_interface.nic.id
	ip_configuration_name 		= local.ipconfig
	nat_rule_id           		= azurerm_lb_nat_rule.ssh-nat.id
}

resource "azurerm_virtual_machine_extension" "jumpext" {
	name 				= "jumpext"
	virtual_machine_id 		= azurerm_linux_virtual_machine.vm.id
	publisher 			= "Microsoft.Azure.Extensions"
	type 				= "CustomScript"
	type_handler_version 		= "2.0"

	settings = <<SETTINGS
		{
		"commandToExecute": "${local.jump-ext}"
		}
SETTINGS
	tags 				= local.tags
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
