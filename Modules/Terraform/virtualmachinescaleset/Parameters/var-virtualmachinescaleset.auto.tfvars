resource_group_name = "jstartvmss11302020rg"
ssh_key_vault_name  = "ADO-Base-Infrastructure" # name of the key vault where existing ssh key vault is stored
key_vault_rg_name   = "ADO-Base-Infrastructure" #rg name of the key vault where existing ssh key vault is stored
virtual_machine_scalesets = {
  vm1 = {
    name                                   = "jstartvmss11302020"
    subnet_name                            = "proxy"
    vnet_name                              = null #"jstartvmssfirst"
    lb_backend_pool_names                  = []
    lb_nat_pool_names                      = null
    app_security_group_names               = null
    app_gateway_name                       = null
    lb_probe_name                          = null
    zones                                  = ["1", "2"] # Availability Zone id, could be 1, 2 or 3, if you don't need to set it to null or delete the line if mutli zone is enabled with LB, LB has to be standard
    vm_size                                = "Standard_F4s_v2"
    enable_ip_forwarding                   = false
    assign_identity                        = true
    enable_rolling_upgrade                 = false
    enable_automatic_instance_repair       = false
    rolling_upgrade_policy                 = null
    automatic_instance_repair_grace_period = null
    instances                              = 1
    disable_password_authentication        = true
    source_image_reference_offer           = "UbuntuServer" #(Mandatory) 
    source_image_reference_publisher       = "Canonical"    #(Mandatory) 
    source_image_reference_sku             = "18.04-LTS"    #(Mandatory) 
    source_image_reference_version         = "Latest"       #(Mandatory)    
    storage_os_disk_caching                = "ReadWrite"
    managed_disk_type                      = "Premium_LRS"
    disk_size_gb                           = null
    write_accelerator_enabled              = null
    enable_default_auto_scale_settings     = null
    enable_accelerated_networking          = null
    enable_ip_forwarding                   = null
    enable_cmk_disk_encryption             = true
    single_placement_group                 = false
    use_existing_disk_encryption_set       = false
    existing_disk_encryption_set_name      = null
    use_existing_ssh_key                   = true # set this to true if you want to use existing public ssh key
    secret_name_of_public_ssh_key          = "publickeynew" #key vault secret name where existing public ssh key is stored
    networking_resource_group              = null
    existing_disk_encryption_set_rg_name   = null
    custom_data_path                       = null #"//CustomData.tpl" #Optional
    custom_data_args                       = null #{ name = "VMandVMSS", destination = "EASTUS2", version = "1.0" }    
    storage_profile_data_disks = [
      {
        lun                       = 0
        caching                   = "ReadWrite"
        disk_size_gb              = 32
        managed_disk_type         = "Standard_LRS"
        write_accelerator_enabled = null
      }
    ]
  }
}

custom_auto_scale_settings = {}

administrator_user_name = "adminuser"
diagnostics_sa_name     = "jstartvmss11302020sa"
key_vault_name          = null #"jstartvmss11302020kv"

vmss_additional_tags = {
  iac            = "Terraform"
  env            = "uat"
  automated_by = ""
  monitor_enable = true
}