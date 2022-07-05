resource_group_name = "[__resoure_group_name__]"

virtual_machine_scalesets = {
  vmss1 = {
    name                                   = "jstartwinvmss001"
    computer_name_prefix                   = "ATTCOMP"
    vm_size                                = "Standard_F4s_v2"
    zones                                  = ["1", "2"] # Availability Zone id, could be 1, 2 or 3, if you don't need to set it to null or delete the line if mutli zone is enabled with LB, LB has to be standard
    assign_identity                        = true
    instances                              = 1
    subnet_name                            = "00000-eastus2-test-core-rg-001"
    vnet_name                              = "eastus-00000-test-vnet-app-snet-001"
    networking_resource_group              = "eastus-00000-test-vnet"
    lb_backend_pool_names                  = ["jstartvmsslbbackend", "jstartvmsslbbackendpublic"]
    lb_nat_pool_names                      = null
    app_security_group_names               = null
    app_gateway_name                       = null
    lb_probe_name                          = "jstartvmsslbrule"
    source_image_reference_offer           = "WindowsServer"          # set this to null if you are  using image id from shared image gallery or if you are passing image id to the VM through packer
    source_image_reference_publisher       = "MicrosoftWindowsServer" # set this to null if you are  using image id from shared image gallery or if you are passing image id to the VM through packer  
    source_image_reference_sku             = "2016-Datacenter"        # set this to null if you are using image id from shared image gallery or if you are passing image id to the VM through packer 
    source_image_reference_version         = "latest"                 # set this to null if you are using image id from shared image gallery or if you are passing image id to the VM through packer                 
    storage_os_disk_caching                = "ReadWrite"
    managed_disk_type                      = "Premium_LRS"
    disk_size_gb                           = null
    write_accelerator_enabled              = null
    upgrade_mode                           = "Manual"
    enable_automatic_os_upgrade            = true
    rolling_upgrade_policy                 = null
    enable_cmk_disk_encryption             = true
    enable_accelerated_networking          = null
    enable_ip_forwarding                   = null
    enable_automatic_instance_repair       = false
    automatic_instance_repair_grace_period = null
    enable_default_auto_scale_settings     = null
    enable_automatic_updates               = true
    ultra_ssd_enabled                      = false
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
diagnostics_sa_name     = "jstartvmssdev111020asa"
key_vault_name          = null #"jstartvmss10182020kv"

vmss_additional_tags = {
  iac            = "Terraform"
  env            = "uat"
  automated_by   = ""
  monitor_enable = true
}