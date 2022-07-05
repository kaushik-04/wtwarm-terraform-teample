output "oracledb-rg-name" {
	value 		= azurerm_resource_group.db-rg.name
}

output "oracledb-des-id" {
    value = azurerm_disk_encryption_set.des.id
}