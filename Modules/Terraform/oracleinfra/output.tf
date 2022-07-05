output "pls-id" {
        value                   = azurerm_private_link_service.pls.id
        description             = "Private Link Service ID"
}

output "oracleinfra-rg" {
	value 		= azurerm_resource_group.rg.name
}

output "nsg-id" {  
        value = azurerm_network_security_group.nsg.id
}

output "subnet-id" {
        value = azurerm_subnet.snet.id
}

output "lb-id" {
        value = azurerm_lb.lb.id
}

output "oblbbep-id" {
        value = azurerm_lb_backend_address_pool.oblbbep.id
}

output "lbbep-id" {
        value = azurerm_lb_backend_address_pool.lbbep.id
}

output "ssh-kv-pubkey-name" {
        value = azurerm_key_vault_secret.pubkey.name
}

output "ssh-kv-privkey-name" {
        value = azurerm_key_vault_secret.this.name
}