# Pester azure infra test cases 

#Version 0.1
#Author : Pester Develeopment Team
#Use case : Automate the Smoke testing 

#region - Global Functions
function Invoke-RunCommand ()
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$vmname,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$rgname,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$subid,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$command,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$token
	)
	
	$restUri = "https://management.azure.com/subscriptions/$subid/resourceGroups/$rgname/providers/Microsoft.Compute/virtualMachines/$vmname/runCommand?api-version=2019-03-01"
	
	$authHeader = @{
		'Content-Type'  = 'application/json'
		'Authorization' = "Bearer " + $token.AccessToken
	}
	
	$body = @{
		'commandId' = 'RunShellScript'
		'script'    = @($Command)
	}
	
	$response = Invoke-webrequest -Uri $restUri -Method Post -Headers $authHeader -Body $($body | ConvertTo-Json) -UseBasicParsing
	$asyncstatus = $($response.headers.'Azure-AsyncOperation')
	$status = "InProgress"
	
	While ($status -eq "InProgress")
	{
		
		$response = invoke-webrequest -uri $asyncstatus -Headers $authHeader -UseBasicParsing
		$status = $($response.Content | ConvertFrom-Json).status -eq "InProgress"
		sleep 5
	}
	
	$results = $($response.Content | ConvertFrom-Json).properties.output.value.message
	$parserpos = $results.IndexOf("]")
	$results = $results.Substring($parserpos + 2).trimstart().replace('[stderr]', '').trimend()
	
	return $results;
}
#endregion

#region - Pre-Requisites
if (!(Get-Command Get-AzMySQLServer -ErrorAction SilentlyContinue))
{
	Install-Module -Name Az.MySQL -AllowClobber -ErrorAction SilentlyContinue -Force -Confirm:$false
}
if (!(Get-Command Get-AzPostgreSqlServer -ErrorAction SilentlyContinue))
{
	Install-Module -Name Az.PostgreSql -AllowClobber -ErrorAction SilentlyContinue -Force -Confirm:$false
}
if (!(Get-Command Get-AzCosmosDBAccount -ErrorAction SilentlyContinue))
{
	Install-Module -Name Az.CosmosDb -AllowClobber -ErrorAction SilentlyContinue -Force -Confirm:$false
}
if (!(Get-Command Get-AzAksCluster -ErrorAction SilentlyContinue))
{
	Install-Module -Name Az.Aks -AllowClobber -ErrorAction SilentlyContinue -Force -Confirm:$false
}
# $spnid = "__PesterSPNID__"
# $spnpass = "__PesterSPNPass__"
# $tenantid = "__PesterSPNTenantID__"
[System.Collections.ArrayList]$required_tags= @('auto_fix','env','contact_dl','app_id','created_by')

[System.Collections.ArrayList]$regions= @('eastus2','westus2','global')

$include_resourcetype = @("Microsoft.Cache/Redis", "Microsoft.Web/sites", "Microsoft.ContainerService/managedClusters",
	"Microsoft.Compute/diskEncryptionSets", "Microsoft.OperationalInsights/workspaces", "Microsoft.ManagedIdentity/userAssignedIdentities",
	"Microsoft.Web/serverFarms", "Microsoft.Network/networkInterfaces", "Microsoft.Compute/disks", "Microsoft.Network/virtualNetworks",
	"Microsoft.Network/natGateways", "Microsoft.Network/privateEndpoints", "Microsoft.Network/loadBalancers",
	"Microsoft.Network/networkSecurityGroups", "Microsoft.Network/applicationGateways", "Microsoft.Network/privateDnsZones",
	"Microsoft.Network/trafficmanagerprofiles", "Microsoft.Network/azureFirewalls", "Microsoft.Network/privateLinkServices",
	"Microsoft.Compute/virtualMachines", "Microsoft.Compute/virtualMachineScaleSets", "Microsoft.OperationalInsights/workspaces",
	"Microsoft.ContainerRegistry/registries", "Microsoft.Sql/servers", "Microsoft.Sql/managedInstances", "Microsoft.ServiceBus/namespaces",
	"Microsoft.DataLakeStore/accounts", "Microsoft.DBforPostgreSQL/servers", "Microsoft.DBforPostgreSQL/serversv2", "Microsoft.DBforMySQL/servers",
	"Microsoft.ApiManagement/service", "Microsoft.Cdn/profiles", "Microsoft.KeyVault/vaults", "Microsoft.DataFactory/dataFactories",
	"Microsoft.DataFactory/factories", "Microsoft.ContainerInstance/containerGroups", "Microsoft.RecoveryServices/vaults",
	"Microsoft.Storage/storageAccounts","Microsoft.DBforMariaDB/servers","Microsoft.DocumentDB/databaseAccounts","Microsoft.Compute/galleries")
#endregion

#region - Extract Token
$azContext = Get-AzContext
$subscriptionId = $azContext.Subscription.Id
$subscriptionName = $azContext.Subscription.Name
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRMProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
#$script:token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
#az login --service-principal --username $env:servicePrincipalId --password $env:servicePrincipalKey --tenant $tenantId
#endregion
az account show

#region - Azure Resource List
$azrglist = Get-AzResourceGroup
$azresourcelist = Get-Azresource
#endregion

#region - Core Infrastructure
Describe "Validation: Approved Regions Deployment" -Tags CoreInfrastructure {
	Context "_Resource Groups" {
		foreach ($resourcegroup in $azrglist)
		{
			it "_$($resourcegroup.ResourceGroupName)" {
				$regions.contains($resourcegroup.Location.ToLower()) | Should -Be $true
			}
			Context "_Azure Resources" {
				$rgresourcelist = $azresourcelist | Where-Object {$psitem.ResourceGroupName -eq $resourcegroup.ResourceGroupName}
				foreach ($resource in $rgresourcelist)
				{
					if ($include_resourcetype.Contains($resource.resourcetype))
					{
						it "_$($resource.Name)" {
							$regions.contains($resource.Location.ToLower()) | Should -Be $true
						}
					}
				}
			}
		}
	}
}

Describe "Validation: Subscription Diagnostics" -Tags CoreInfrastructure {
	Context '_settings' {
		It -Name "_$subscriptionName" {
			Get-AzDiagnosticSetting -ResourceId "/subscriptions/$subscriptionId" | Should -Not -Be $null
		}
	}
}

Describe "Validation: Azure Resources Tags" -Tags CoreInfrastructure {
    <#
                   - RESOURCE TAGS - Test cases for following conditions:
                   SCOPE - Resource group or subscription
    
                   . Validate the resource should have tags
                   . Check for Mandatory tags, empty tag values and
                   . Validate diagnostics logs are enabled on Key Vault
    #>
	foreach ($resource in $azresourcelist)
	{
		if ($include_resourcetype.Contains($resource.resourcetype))
		{
			Context "_Should have tags" {
				It "_$($resource.name)_ShouldHaveTags" {
					($resource.Tags).count | Should -Not -Be 0
				}
			}
			if ($resource.Tags.Count -ne 0)
			{
				Context "_Should not have empty value tag" {
					It "_$($resource.name)_NoNullValueTags" {
						$resource.tags.ContainsValue($null) | Should -Not -Be $true
					}
				}
				Context "_Should have mandatory tags" {
					$ArrList = New-Object System.Collections.ArrayList
					foreach ($l in $required_tags)
					{
						$ArrList.Add($resource.Tags.ContainsKey($l))  > $null
					}
					It "_$($resource.name)_MandatoryTags" {
						$ArrList.Contains($False) | Should -Be $False
					}
				}
			}
			
		}
	}
}

Describe "Validation: Networking Tests" -Tags CoreInfrastructure {
	$VirtualNetworks = $azresourcelist | Where-Object { $psitem.ResourceType -eq "Microsoft.Network/virtualNetworks" }
	Context "_Virtual Network" {
		$rfc1918regex = "^(?:10|172\.(?:1[6-9]|2[0-9]|3[01])|192\.168)\..*"
		foreach ($net in $VirtualNetworks)
		{
			$vNet = Get-AzVirtualNetwork -ResourceGroupName $net.ResourceGroupName -Name $net.Name -ErrorAction SilentlyContinue
			
			it "_$($vNet.Name)_Subnet" {
				$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vNet -ErrorAction SilentlyContinue
				$subnet | Should -Not -Be $null
			}
			
			It "_$($vNet.Name)_RFC1918" {
				$vNet.AddressSpace.AddressPrefixes -match $rfc1918regex | Should -Not -Be $null
			}
		}
	}
}

Describe "Validation: Network Security Group Tests" -Tags CoreInfrastructure {
	$NSGS = Get-AzNetworkSecurityGroup
	foreach ($NSG in $NSGS)
	{
		Context "_Ports Open to All" {
			$openAllInCount = 0
			$openAllOutCount = 0
			foreach ($rule in $NSG.SecurityRules)
			{
				if ($rule.Direction -eq "Inbound" -and $rule.Access -eq "Allow" -and ($rule.SourceAddressPrefix -eq "*" -or $rule.SourceAddressPrefix -eq "0.0.0.0/0" -or $rule.SourceAddressPrefix -eq "Internet"))
				{
					$openAllInCount++
				}
				if ($rule.Direction -eq "Outbound" -and $rule.Access -eq "Allow" -and ($rule.DestinationAddressPrefix -eq "*" -or $rule.DestinationAddressPrefix -eq "0.0.0.0/0" -or $rule.DestinationAddressPrefix -eq "Internet"))
				{
					$openAllOutCount++
				}
			}
			It "_$($NSG.name)_PortInboundOpen" {
				$openAllInCount | Should -Be 0
			}
			It "_$($NSG.name)_PortOutboundOpen" {
				$openAllOutCount | Should -Be 0
			}
		}
		
		Context "_Required DENYALL rule" {
			It "_$($NSG.name)_DenyAllInbound" {
				(Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $NSG | Where-Object { $_.Access -eq "Deny" -and $_.SourcePortRange -eq "*" -and $_.DestinationPortRange -eq "*" -and $_.SourceAddressPrefix -eq "*" -and $_.DestinationAddressPrefix -eq "*" -and $_.Protocol -eq "*" -and $_.Direction -eq "Inbound" }) | Should -Not -Be $null
			}
			It "_$($NSG.name)_DenyAllOutbound" {
				(Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $NSG | Where-Object { $_.Access -eq "Deny" -and $_.SourcePortRange -eq "*" -and $_.DestinationPortRange -eq "*" -and $_.SourceAddressPrefix -eq "*" -and $_.DestinationAddressPrefix -eq "*" -and $_.Protocol -eq "*" -and $_.Direction -eq "Outbound" }) | Should -Not -Be $null
			}
		}
		
		<#
			Pester azure infra test cases for validating Azure Application Gateway
			Version 1.0
			Author : Manish Anand
			Use case : Automate the Smoke testing 
			Security ID : SC23
			Scope : Subscription

			- Validate NSG flow logs are enabled
			- Validate subscription activity logs are bening send to ASTRA
		#>
		Context '_NSG Flow Logs' {
			It -Name "_$($NSG.Name)" {
				(Get-AzNetworkWatcherFlowLogStatus -Location $NSG.Location -TargetResourceId $NSG.id).Enabled | Should -Be $true
			}
		}
	}
}

Describe "Validation: Storage Account Tests" -Tags CoreInfrastructure {
	Context "_Storage Accounts" {
		$azstorage = $azresourcelist | Where-Object { $psitem.ResourceType -eq "Microsoft.Storage/storageAccounts" }
		foreach ($storage in $azstorage)
		{
			$adls = Get-AzStorageAccount -Name $storage.Name -ResourceGroupName $storage.ResourceGroupName
			
			# Get Role Assignment of Storage Account $adls
			# FIX Needed - Requires Directory Read.All to fetch the Output of AZ Role Assignment
			#if ($adls) {
			#    [int]$adlsrbacassignment = (Get-AzRoleAssignment -Scope $adls.Id).Count
			#    [int]$adlsrgrbacassignment = (Get-AzRoleAssignment -ResourceGroupName $adls.ResourceGroupName).Count
			#}
			
			# Validate Storage Account V2
			it "_$($adls.StorageAccountName)_V2" {
				$adls.Kind | Should -Be "StorageV2"
			}
			
			# SC26 - Storage accounts must set SECURE TRANSFER REQUIRED to enforce secure connections
			it "_SC26 - $($adls.StorageAccountName)_HTTPS" {
				$adls.EnableHttpsTrafficOnly | Should -Be $true
			}
			
			# SC04 - Data-at-rest must be encrypted (disk, storage, etc.)
			it "_SC04 - $($adls.StorageAccountName)_Encryption" {
				$adls.Encryption.Services.Blob.Enabled | Should -Be $true
				$adls.Encryption.Services.File.Enabled | Should -Be $true
			}
			
			# SC28 - Storage account management tier access (RBAC) is inherited from resource group RBAC
			#it "should inherit RBAC from Resource Group" {
			#	$adlsrbacassignment | Should -Be $adlsrgrbacassignment
			#}
			
			# SC22: Use Azure Private Link and storage firewall to protect Azure Storage. Configure storage firewall to block external access.
			it "_SC22 - $($adls.StorageAccountName)_PE" {
				(Get-AzPrivateEndpointConnection -PrivateLinkResourceId $adls.id).Count | Should -BeGreaterThan 0
			}
			
			<#
				Pester azure infra test cases for validating Azure storage acccount network rule set
				Version 1.0
				Author : Manish Anand
				Use case : Automate the Smoke testing 
				Security ID : SC22
				Scope : Subscription

				- Validate all storage account network rule set is set to Default Action Deny
			#>
			It -Name "_SC22 - $($adls.StorageAccountName)_DenyNetwork" {
				(Get-AzStorageAccount -Name $adls.StorageAccountName -ResourceGroupName $adls.ResourceGroupName).NetworkRuleSet.DefaultAction | Should -Be "Deny"
			}
		}
	}
}

Describe "Validation: Azure Key Vault" -Tags CoreInfrastructure {
	<#
		- KEY VAULT - Test cases for following conditions:
		SCOPE - Subscription

		. Validate that subscription has atleast one Key vault
		. Verify Network security for Key Vault i.e. No Public IPs, Firewall Enabled and No service endpoints.
		. Validate diagnostics logs are enabled on Key Vault
	#>
	$keyvaults = Get-AzKeyVault
	Context "_Checking Subscription for Key-Vault" {
		It "_$((Get-AzContext).Subscription.Name)" {
			$keyvaults.Count | Should -Not -Be 0
		}
	}
	
	Context "_Checking Network Complaince for Key Vault" {
		foreach ($kv in $keyvaults)
		{
			$kvtemp = Get-AzKeyVault -VaultName $kv.vaultname
			It "_$($kvtemp.vaultname)_NetworkFirewall" {
				$kvtemp.NetworkAcls.DefaultAction.value__ | Should -Be 1
			}
			It "_$($kvtemp.vaultname)_PublicIPRanges" {
				$kvtemp.NetworkAcls.IpAddressRanges.Count | Should -Be 0
			}
			It "_$($kvtemp.vaultname)_ServiceEndpoints" {
				$kvtemp.NetworkAcls.VirtualNetworkResourceIds.Count | Should -Be 0
			}
			It "_$($kvtemp.vaultname)_PE" {
				(Get-AzPrivateEndpointConnection -PrivateLinkResourceId $kvtemp.ResourceId).count | should -BeGreaterThan 0
			}
		}
	}
	
	Context "_Checking Key Vault diagnostics" {
		foreach ($kv in $keyvaults)
		{
			$diagcount = 0
			$diagsettings = Get-AzDiagnosticSetting -ResourceId $kv.resourceid -WarningAction SilentlyContinue
			foreach ($setting in $diagsettings)
			{
				If (($setting.Logs.enabled -eq $true) -and ($setting.StorageAccountId))
				{
					$diagcount++
				}
			}
			It "_$($kv.vaultname)_StorageDiag" {
				$diagcount | Should -Not -Be 0
			}
		}
	}
	
	Context "_Checking Key Vault region" {
		foreach ($kv in $keyvaults)
		{
			It "_$($kv.vaultname)_Region" {
				$regions.Contains($kv.Location.ToLower()) | Should -Be $true
			}
		}
	}
}

Describe "Validation: Log-anaytic workspace" -Tags CoreInfrastructure {
	Context "_Get the Workspace name" {
		$LAResource = $azresourcelist | Where-Object { $psitem.ResourceType -eq "Microsoft.OperationalInsights/workspaces" }
		foreach ($LA in $LAResource)
		{
			$LAName = Get-AzOperationalInsightsWorkspace -ResourceGroupName $LA.ResourceGroupName
			it "_$($LAName.Name)_ResourceGroup" {
				$LAName.Name | Should -Not -Be $null
			}
		}
	}
}
#endregion

#region - Networking Tests
Describe "Validation : Azure PaaS Services PE Connectivity" -Tags PaaSPrivateEndpoint {
	<#
		Pester azure infra test cases for validating private endpoint connectivity to Azure PaaS services
		Version 1.0
		Author : Manish Anand
		Use case : Automate the Smoke testing 
		Scope : Subscription
		- Validate that all az PaaS components are leveraging private link for connectivity
		 - Az.Storage
		 - Az.ACR
		 - Az.AKV
		 - Az.MySqlDB
		 - Az.AKS
		 - Az.PostgreDB
		 - Az.MariaDB
		 - Az.SQL
	#>
	Context '_Azure Database for MariaDB ' {
		$Az_mariadb = Get-AzResource -ResourceType Microsoft.DBforMariaDB/servers
		foreach ($mariadb in $Az_mariadb)
		{
			
			It -Name "_$($mariadb.Name)" {
				(Get-AzPrivateEndpointConnection -PrivateLinkResourceId $mariadb.id).count | should -BeGreaterThan 0
			}
		}
		
	}
	Context '_Azure Database for SQL ' {
		$Az_sql = Get-AzResource -ResourceType Microsoft.Sql/servers
		foreach ($sql in $Az_sql)
		{
			It -Name "_$($sql.Name)" {
				(Get-AzPrivateEndpointConnection -PrivateLinkResourceId $sql.id).count | should -BeGreaterThan 0
			}
		}
		
	}
}

Describe "Validation : LoadBalancer" -Tags LoadBalancer {
	<#
		Pester azure infra test cases for validating Load Balancer SKU, Backend Health Status and ELB Inbound Rule
		Version 1.0
		Author : Manish Anand
		Use case : Automate the Smoke testing 
		Scope : Subscription

		- Validate all loadbalancer SKU is set to Standard
		- Validate all loadbalancer backend are healthy
		- Validate if there is a public standard loadbalancer then it should not have any inbound rules configured.
	#>	
	$Az_lb = Get-AzLoadBalancer
	Context '_LoadBalancer SKU' {
		foreach ($lb in $Az_lb)
		{
			It -Name "_$($lb.Name)" {
				$lb.sku.Name | Should -Be "Standard"
			}
		}
		
	}
	Context '_Inbound Rule in ELB' {
		foreach ($lb in $Az_lb | ? { $_.FrontendIpConfigurations[0].publicIpAddress.id -ne $null -and $_.sku.Name -eq "Standard" })
		{
			It -Name "_$($lb.Name)" {
				
				(Get-AzLoadBalancerRuleConfig -LoadBalancer $lb).id | Should -Be $Null
			}
		}
	}
	Context '_Backend Health' {
		foreach ($lb in $Az_lb | ? { $_.FrontendIpConfigurations[0].publicIpAddress.id -eq $null -and $_.sku.Name -eq "Standard" })
		{
			It -Name "_$($lb.Name)" {
				
				(((Get-AzMetric -ResourceId $lb.Id -MetricName DipAvailability -TimeGrain 00:01:00 -DetailedOutput -AggregationType Average -StartTime (get-date).AddMinutes(-5)).Data | Measure-Object -Property "average" -Sum).sum) / 5 | Should -BeGreaterOrEqual 100
			}
		}
	}
	
}

Describe  'Validation : Azure AppGw' -Tags ApplicationGateway {
	<#
		Pester azure infra test cases for validating Azure Application Gateway
		Version 1.0
		Author : Manish Anand
		Use case : Automate the Smoke testing 
		Security ID : SC19
		Scope : Subscription

		- Validate application gateway SKU it set to WAF_V2
		- Validate application gateway firewall is enabled
		- Validate application gateway firewall mode is set to Prevention
		- Validate application gateway listener config protocol is set to https
		- Validate application gateway https setting config protocol is set to https
	#>	
	$Az_appgw = Get-AzApplicationGateway
	foreach ($appgw in $Az_appgw)
	{
		Context '_SKU' {
			It -Name "_$($appgw.Name)" {
				(Get-AzApplicationGateway -Name $appgw.Name -ResourceGroupName $appgw.ResourceGroupName).sku.Tier | Should -Be "WAF_v2"
			}
		}
		Context '_Firewall Enabled' {
			It -Name "_$($appgw.Name)" {
				(Get-AzApplicationGateway -Name $appgw.Name -ResourceGroupName $appgw.ResourceGroupName).webApplicationFirewallConfiguration.Enabled | Should -Be "True"
			}
		}
		Context '_Firewall Mode' {
			It -Name "_$($appgw.Name)" {
				(Get-AzApplicationGateway -Name $appgw.Name -ResourceGroupName $appgw.ResourceGroupName).webApplicationFirewallConfiguration.FirewallMode | Should -Be "Prevention"
			}
		}
		$az_appgw_listeners = Get-AzApplicationGatewayHttpListener -ApplicationGateway $appgw
		Context '_Listener Protocol' {
			foreach ($listeners in $az_appgw_listeners)
			{
				It -Name "_$($appgw.Name)_$($listeners.Name)" {
					(Get-AzApplicationGatewayHttpListener -ApplicationGateway $appgw -Name $listeners.Name).Protocol | Should -Be "Https"
				}
			}
		}
		$az_appgw_httpssettings = Get-AzApplicationGatewayBackendHttpSettings -ApplicationGateway $appgw
		Context '_Https Setting Protocol' {
			foreach ($httpsettings in $az_appgw_httpssettings)
			{
				It -Name "_$($appgw.Name)_$($httpsettings.Name)" {
					(Get-AzApplicationGatewayBackendHttpSettings -ApplicationGateway $appgw -Name $httpsettings.Name).Protocol | Should -Be "Https"
				}
			}
		}
	}
}
#endregion

#region - Compute Tests
Describe "Validation: Virtual Machine Tests" -Tags VirtualMachines {
	$azvms = $azresourcelist | Where-Object { $psitem.ResourceType -eq "Microsoft.Compute/virtualMachines" }
	
	Context "_Log anaytic workspace Extension Test" {
		foreach ($vm in $azvms)
		{
			$ExtensionList = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
			$LAExtension = $ExtensionList | Where-Object { $psitem.Publisher -eq "Microsoft.EnterpriseCloud.Monitoring" }
			$Networkwatcher = $ExtensionList | Where-Object { $psitem.Publisher -eq "Microsoft.Azure.NetworkWatcher" }
			$Vminsights = $ExtensionList | Where-Object { $psitem.Publisher -eq "Microsoft.Azure.Diagnostics" }
			It "_$($vm.name)_OMS" {
				$LAExtension | Should -Not -Be $null
				$LAExtension.ProvisioningState | Should -Be "Succeeded"
			}
			
			It "_$($vm.name)_NetworkWatcher" {
				$Networkwatcher | Should -Not -Be $null
				$Networkwatcher.ProvisioningState | Should -Be "Succeeded"
			}
			
			It "_$($vm.name)_VMInsights" {
				$Vminsights | Should -Not -Be $null
				$Vminsights.ProvisioningState | Should -Be "Succeeded"
			}
		}
	}
	
	Context "_VM Accelarated Networking" {
		foreach ($vm in $azvms)
		{
			$vm = Get-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName
			foreach ($nic in $vm.NetworkProfile.NetworkInterfaces.id)
			{
				$nicobj = Get-AzNetworkInterface -ResourceId $nic -ErrorAction SilentlyContinue
				it "_$($vm.name)_$($nicobj.Name)" {
					$nicobj.EnableAcceleratedNetworking | Should -Be $true
				}
			}
		}
	}
	
	Context "_VM BootDiagnostics" {
		foreach ($vm in $azvms)
		{
			It -Name "_$($vm.Name)" {
				$vm.diagnosticsProfile.bootDiagnostics.enabled | Should -Be $true
			}
		}
	}
	
	Context  "_Linux VM Password Login check" {
		foreach ($vm in $azvms)
		{
			$command = "cat /etc/ssh/sshd_config | grep -i 'PasswordAuthentication no'"
			
			$InvokeRunCommandParam = @{
				vmname = $vm.Name
				rgname = $vm.ResourceGroupName
				subid  = $subscriptionId
				token  = $token
				command = $command
			}
			$linuxpasswordoutput = Invoke-RunCommand @InvokeRunCommandParam
			$linuxpasswordoutput = $linuxpasswordoutput.trimstart().trimend()
			
			It -Name "_$($vm.Name)_Password"{
				$linuxpasswordoutput | Should -BeLike '*PasswordAuthentication no*'
			}
		}
	}
	
	Context "_Remote Root Login check in the VM Instances" {
		foreach ($vm in $azvms)
		{
			$command = "passwd --status root | grep 'L' | awk '{print `$2}'"
			
			$InvokeRunCommandParam = @{
				vmname = $vm.Name
				rgname = $vm.ResourceGroupName
				subid  = $subscriptionId
				token  = $token
				command = $command
			}
			$rootloginoutput = Invoke-RunCommand @InvokeRunCommandParam
			$rootloginoutput = $rootloginoutput.trimstart().trimend()
			
			It -Name "_$($vm.Name)_RootPassword" {
				$rootloginoutput | Should -BeLike '*L*'
			}
		}
	}
	
	Context "_Checking SSH Root access" {
		foreach ($vm in $azvms)
		{
			$command = "cat /etc/ssh/sshd_config | grep -i 'PermitRootLogin no'"
			
			$InvokeRunCommandParam = @{
				vmname = $vm.Name
				rgname = $vm.ResourceGroupName
				subid  = $subscriptionId
				token  = $token
				command = $command
			}
			$sshrootaccessoutput = Invoke-RunCommand @InvokeRunCommandParam
			$sshrootaccessoutput = $sshrootaccessoutput.trimstart().trimend()
			
			It "_$($vm.Name)_PasswordLogin" {
				$sshrootaccessoutput | Should -BeLike '*PermitRootLogin no*'
			}
		}
	}
	
	Context "_Check Disk Encryption" {
		foreach ($vm in $azvms)
		{
			$vm = Get-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName
			It "_$($vm.Name)_$($vm.StorageProfile.OsDisk.Name)" {
				$vm.StorageProfile.OsDisk.ManagedDisk.DiskEncryptionSet.Id | should -Be $true
			}
			foreach ($datadisk in $vm.StorageProfile.DataDisks)
			{
				It "_$($vm.Name)_$($datadisk.Name)" {
					$datadisk.ManagedDisk.DiskEncryptionSet.id | should -Be $true
				}
			}
		}
	}
}

Describe "Validation: Azure Kubernetes Tests" -Tags KubernetesCluster {
	$azakscluster = $azresourcelist | Where-Object { $psitem.ResourceType -eq "Microsoft.ContainerService/managedClusters" }
	Context "_Private AKS Cluster" {
		foreach ($akscluster in $azakscluster)
		{
			$aksclusterobj = Get-AzAks -Name $akscluster.Name -ResourceGroupName $akscluster.ResourceGroupName
			
			# Validate Private AKS Cluster
			It -Name "_$($akscluster.Name)_PrivateAKS" {
				$aksclusterobj.ApiServerAccessProfile.EnablePrivateCluster | Should -Be $true
			}
			
			# Validate Private AKS Cluster using VMSS
			It -Name "_$($akscluster.Name)_VMSS" {
				$aksclusterobj.AgentPoolProfiles.type | Should -Be "VirtualMachineScaleSets"
			}
			
			# Validate Private AKS Cluster using Availability Zone
			It -Name "_$($akscluster.Name)_AvZone" {
				$avzone = @(1, 2, 3)
				$aksclusterobj.AgentPoolProfiles.AvailabilityZones.Count | Should -Be $avzone.Count
			}
			
			# Validate Private AKS Cluster Network using Firewall Route Table
			It -Name "_$($akscluster.Name)_RouteTable" {
				(Get-AzVirtualNetworkSubnetConfig -ResourceId $aksclusterobj.AgentPoolProfiles.vnetsubnetid).RouteTable.Count | Should -BeGreaterThan 0
			}
			
			# Validate Private AKS Cluster using RBAC
			It -Name "_$($akscluster.Name)_RBAC" {
				$aksclusterobj.EnableRBAC | Should -Be $true
			}
			
			# Validate Network Policy
			It -Name "_$($akscluster.Name)_NetworkPolicy" {
				$aksclusterobj.NetworkProfile.NetworkPolicy | Should -Be $true
			}
			
			# Validate Private AKS Cluster using OMS
			It -Name "_$($akscluster.Name)_OMSAgent" {
				$aksclusterobj.AddonProfiles.Keys | Should -BeLike "*omsagent*"
			}
		}
	}
	
	Context '_LinkerD' {
		<#
			Pester azure infra test cases for validating AKS network policy validation and Linkerd mesh
			Version 1.0
			Author : Manish Anand
			Use case : Automate the Smoke testing 
			Scope : Subscription

			- Validate AKS network policy set to Azure or Calico
			- Validate Namespaces are messed wit linkerD
		#>
		foreach ($aks in $azakscluster)
		{
			$aks = Get-AzAks -Name $aks.Name -ResourceGroupName $aks.ResourceGroupName
			Import-AzAksCredential -InputObject $aks -Force
			kubectl config use-context $aks.Name
			$namespace = kubectl get ns -o json | ConvertFrom-Json
			foreach ($ns in $namespace.items)
			{
				if ($ns.metadata.name -ne "Default" -and $ns.metadata.name -ne "kube-public" -and $ns.metadata.name -ne "kube-system")
				{
					It -Name "_$($aks.Name + "_" + $ns.metadata.name)" {
						(kubectl get ns $ns.metadata.name -o json | convertfrom-json).metadata.annotations.'linkerd.io/inject' | Should -Be "enabled"
					}
				}
			}
			
		}
	}
	
	Context "_MSIAuthentication" {
		foreach ($aks in $azakscluster)
		{
			It -Name "_$($aks.Name)_MSI" {
				$temp = $(az aks show -g $aks.ResourceGroupName -n $aks.Name | ConvertFrom-Json)
				$temp.servicePrincipalProfile.clientId | Should -Be 'msi'
			}
		}
	}
	
	Context "_PodIdentity" {
		foreach ($aks in $azakscluster)
		{
			It -Name "_$($aks.Name)_PodIdentity" {
				$temp = $(helm ls -A | Select-String "aad-pod-identity")
				$temp | Should -BeLike 'aad-pod-identity'
			}
		}
	}
	
	Context "_Firewall" {
		if ($azakscluster)
		{
			$fw = Get-AzFirewall
			It "_$subscriptionName" {
				$fw.count | Should -Not -Be 0
			}
		}
	}
	
	Context "_SubnetRoute" {
		foreach ($akscluster in $azakscluster)
		{
			$aksobj = Get-AzAks -Name $akscluster.Name -ResourceGroupName $akscluster.ResourceGroupName
			$akssubnetID = (get-azvmss -ResourceGroupName $aksobj.NodeResourceGroup).VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].Subnet.Id
			$routetable = (Get-AzVirtualNetworkSubnetConfig -ResourceId $akssubnetID).RouteTable.Id
			
			It "_$($akssubnetID.Split('/')[10])" {
				$routetable | Should -Not -Be $null
			}
			
			If ($routetable -and $fw)
			{
				$fwroute = 0
				$routes = (Get-AzRouteTable -Name $($routetable.Split('/')[8])).Routes
				foreach ($firewall in $fw)
				{
					$fwip = $firewall.IpConfigurations[0].PrivateIPAddress
					foreach ($route in $routes)
					{
						if (($route.AddressPrefix -eq "0.0.0.0/0") -and ($route.NextHopIpAddress -eq $fwip))
						{
							$fwroute++
						}
					}
				}
				It "_$($routetable.Split('/')[8])" {
					$fwroute | Should -Not -Be 0
				}
			}
		}
	}
}
#endregion

#region - PaaS DB Pester Tests
Describe "Validation: PaaS DB Validation Tests" -Tags PaaSDatabase {
	Context "_MySQL DB" {
		$azmysqldb = $azresourcelist | Where-Object { $psitem.ResourceType -eq "Microsoft.DBforMySQL/servers" }
		foreach ($mysql in $azmysqldb)
		{
			# SC05: PaaS databases will restrict access with PLS, encrypt data in all states and enable auditing
			It -Name "_SC05 - $($mysql.Name)_PE" {
				(Get-AzPrivateEndpointConnection -PrivateLinkResourceId $mysql.id).Count | Should -BeGreaterThan 0
			}
			It -Name "_SC05 - $($mysql.Name)_PublicAccess" {
				Get-AzMySQLServer -Name $mysql.Name -ResourceGroupName $mysql.ResourceGroupName | Select-Object PublicNetworkAccess -ExpandProperty PublicNetworkAccess | Should -Be "Disabled"
			}
			It -Name "_SC05 - $($mysql.Name)_Encryption" {
				Get-AzMySQLServer -Name $mysql.Name -ResourceGroupName $mysql.ResourceGroupName | Select-Object SslEnforcement -ExpandProperty SslEnforcement | Should -Be "Enabled"
			}
			It -Name "_SC05 - $($mysql.Name)_Encryption" {
				Get-AzMySQLServer -Name $mysql.Name -ResourceGroupName $mysql.ResourceGroupName | Select-Object InfrastructureEncryption -ExpandProperty InfrastructureEncryption | Should -Be "Enabled"
			}
		}
	}
	
	Context "_PostgreSQL DB" {
		$azpsqldb = $azresourcelist | Where-Object { $psitem.ResourceType -eq "Microsoft.DBforPostgreSQL/servers" }
		foreach ($psql in $azpsqldb)
		{
			# SC05: PaaS databases will restrict access with PLS, encrypt data in all states and enable auditing
			It -Name "_SC05 - $($psql.Name)_PE" {
				(Get-AzPrivateEndpointConnection -PrivateLinkResourceId $psql.id).Count | Should -BeGreaterThan 0
			}
			It -Name "_SC05 - $($psql.Name)_PublicAccess" {
				Get-AzPostgreSqlServer -Name $psql.Name -ResourceGroupName $psql.ResourceGroupName | Select-Object PublicNetworkAccess -ExpandProperty PublicNetworkAccess | Should -Be "Disabled"
			}
			It -Name "_SC05 - $($psql.Name)_Encryption" {
				Get-AzPostgreSqlServer -Name $psql.Name -ResourceGroupName $psql.ResourceGroupName | Select-Object SslEnforcement -ExpandProperty SslEnforcement | Should -Be "Enabled"
			}
			It -Name "_SC05 - $($psql.Name)_Encryption" {
				Get-AzPostgreSqlServer -Name $psql.Name -ResourceGroupName $psql.ResourceGroupName | Select-Object InfrastructureEncryption -ExpandProperty InfrastructureEncryption | Should -Be "Enabled"
			}
		}
	}
	
	Context "_Cosmos DB Account" {
		$azcosmosdb = $azresourcelist | Where-Object { $psitem.ResourceType -eq "Microsoft.DocumentDB/databaseAccounts" }
		foreach ($cosmos in $azcosmosdb)
		{
			# SC05: PaaS databases will restrict access with PLS, encrypt data in all states and enable auditing
			It -Name "_SC05 - $($cosmos.Name)_PE" {
				(Get-AzPrivateEndpointConnection -PrivateLinkResourceId $cosmos.id).Count | Should -BeGreaterThan 0
			}
			It -Name "_SC05 - $($cosmos.Name)_PublicAccess" {
				Get-AzCosmosDBAccount -Name $cosmos.Name -ResourceGroupName $cosmos.ResourceGroupName | Select-Object PublicNetworkAccess -ExpandProperty PublicNetworkAccess | Should -Be "Disabled"
			}
			It -Name "_SC05 - $($cosmos.Name)_Encryption" {
				(Get-AzCosmosDBAccount -Name $cosmos.Name -ResourceGroupName $cosmos.ResourceGroupName).KeyVaultKeyUri.Count | Should -BeGreaterThan 0
			}
		}
	}
}
#endregion

#region - Other PaaS Resources
Describe "Validation: Azure Container Registry Tests" -Tags ContainerRegistry {
	Context "_PrivateACR" {
		$azmysqldb = $azresourcelist | Where-Object { $psitem.ResourceType -eq "Microsoft.ContainerRegistry/registries" }
		foreach ($azacr in $azacrarray)
		{
			$acrobj = Get-AzContainerRegistry -Name $azacr.Name -ResourceGroupName $azacr.ResourceGroupName
			$acrrepobj = Get-AzContainerRegistryReplication -Name $azacr.Name -ResourceGroupName $azacr.ResourceGroupName
			
			# Validate Private Endpoint for ACR
			It -Name "_$($azacr.Name)_PE" {
				(Get-AzPrivateEndpointConnection -PrivateLinkResourceId $acrobj.id).Count | Should -BeGreaterThan 0
			}
			
			# Validate ACR SKU Premium
			It -Name "_$($azacr.Name)_Premium" {
				$acrobj.SkuName | Should -Be "Premium"
			}
			
			# Validate ACR Admin User is Disabled
			It -Name "_$($azacr.Name)_AdminUser" {
				$acrobj.AdminUserEnabled | Should -Be "False"
			}
			
			# Validate ACR Replication Enabled
			It -Name "_$($azacr.Name)_Replication" {
				$acrrepobj.Count | Should -BeGreaterOrEqual 2
			}
			
			# Validate ACR Encryption is Enabled
			It -Name "_$($azacr.Name) should have encryption enabled" {
				(az acr encryption show --name $($azacr.Name) | ConvertFrom-Json).Status | Should -Be "enabled"
			}
		}
	}
}
#endregion

<# On Pause till we get Key-vault solution for DB Credentials
#region - Database VM Pester Tests
$dbIdentifier = "__DBIdentifier__"
$dbusername = "__DBUser__"
$dbuserpassword = "__DBPassword__"
$mysqlvmarray = @()
$oraclevmarray = @()

Describe "Validation: Database IaaS VM Tests" -Tags DatabaseVirtualMachines {
	$virtualMachines = $azresourcelist | Where-Object {
		$psitem.ResourceType -eq "Microsoft.Compute/virtualMachines"
		-and $psitem.Name -like "*$($dbIdentifier)*" }

	foreach ($vm in $virtualMachines)
	{
		#region - Check for MySQl
		$checkmysql = $null
		$command = "which mysql 2> /dev/null"
		
		$InvokeRunCommandParam = @{
			vmname = $vm.ResourceGroupName
			rgname = $vm.Name
			subid  = $subscriptionId
			token  = $token
			command = $command
		}
		
		$checkmysql = Invoke-RunCommand @InvokeRunCommandParam
		
		if ($checkmysql)
		{
			$mysqlvmarray += $vm
		}
		#endregion
		
		#region - Check for Oracle
		if ($checkmysql -eq $null)
		{
			$checkoracle = $null
			$command = "ps -ef | grep pmon | grep -v grep"
			
			$InvokeRunCommandParam = @{
				vmname  = $vm.Name
				rgname  = $vm.ResourceGroupName
				subid   = $subscriptionId
				token   = $token
				command = $command
			}
			
			$checkoracle = Invoke-RunCommand @InvokeRunCommandParam
			
			if ($checkoracle)
			{
				$oraclevmarray += $vm
			}
		}
		#endregion
	}
	
	Context "_MySQL IaaS VMs" {
		foreach ($mysqlvm in $mysqlvmarray)
		{
			#region - Test 1 - Validate under MySQL Config (Inactive)
			$command = "mysql -u $($dbusername) -p$($dbuserpassword) -e `"SHOW VARIABLES LIKE '%SSL%';`" | egrep 'ssl_ca|ssl_cert|ssl_key' | grep -v 'ssl_capath'"
			
			$InvokeRunCommandParam = @{
				vmname = $mysqlvm.Name
				rgname = $mysqlvm.ResourceGroupName
				subid  = $subscriptionId
				token  = $token
				command = $command
			}
			
			$mysqlsslconfig = Invoke-RunCommand @InvokeRunCommandParam
			$mysqlsslconfig = $mysqlsslconfig.Replace("mysql: [Warning] Using a password on the command line interface can be insecure.", '').trimstart().trimend()
			#endregion
			
			#region - Test 2 - Validate with \s switch
			$command = "mysql -u $($dbusername) -p$($dbuserpassword) -e `"\s;`" | grep 'SSL'"
			
			$InvokeRunCommandParam = @{
				vmname = $mysqlvm.Name
				rgname = $mysqlvm.ResourceGroupName
				subid  = $subscriptionId
				token  = $token
				command = $command
			}
			
			$mysqlswitchoutput = Invoke-RunCommand @InvokeRunCommandParam
			$mysqlswitchoutput = $mysqlswitchoutput.Replace("mysql: [Warning] Using a password on the command line interface can be insecure.", '').trimstart().trimend()
			
			it "_$($mysqlvm.Name)_SSL" {
				$mysqlswitchoutput | Should -Not -BeLike "*Not in use*"
			}
			#endregion
			
			#region - Test 3 - Validate with /etc/my.cnf
			$command = "cat /etc/my.cnf | grep 'require_secure_transport'"
			
			$InvokeRunCommandParam = @{
				vmname = $mysqlvm.Name
				rgname = $mysqlvm.ResourceGroupName
				subid  = $subscriptionId
				token  = $token
				command = $command
			}
			
			$mysqlcnfoutput = Invoke-RunCommand @InvokeRunCommandParam
			$mysqlcnfoutput = $mysqlcnfoutput.trimstart().trimend()
			
			it "_$($mysqlvm.Name)_SSL" {
				$mysqlcnfoutput | Should -BeLike "*require_secure_transport = ON*"
			}
			#endregion
		}
	}
	
	Context "_Oracle IaaS VMs" {
		foreach ($oraclevm in $oraclevmarray)
		{
			$command = "ls -l `$ORACLE_HOME/network/admin/sqlnet.ora"
			
			$InvokeRunCommandParam = @{
				vmname = $oraclevm.Name
				rgname = $oraclevm.ResourceGroupName
				subid  = $subscriptionId
				token  = $token
				command = $command
			}
			
			$validateorafile = Invoke-RunCommand @InvokeRunCommandParam
			$validateorafile = $validateorafile.trimstart().trimend()
			
			if ($validateorafile -like "*/sqlnet.ora*")
			{
				#region - Test 1 - Validate Encryption Config sqlnet.ora file
				$command = "cat `$ORACLE_HOME/network/admin/sqlnet.ora | grep 'SQLNET.ENCRYPTION_SERVER'"
				
				$InvokeRunCommandParam = @{
					vmname = $oraclevm.Name
					rgname = $oraclevm.ResourceGroupName
					subid  = $subscriptionId
					token  = $token
					command = $command
				}
				
				$sqlnetoraoutput = Invoke-RunCommand @InvokeRunCommandParam
				$sqlnetoraoutput = $sqlnetoraoutput.trimstart().trimend()
				
				it "_$($oraclevm.Name)_SSL" {
					$sqlnetoraoutput | Should -BeLike "*SQLNET.ENCRYPTION_SERVER = required*"
				}
				#endregion
				
				#region - Test 2 - Validate CRYPTO sqlnet.ora file
				$command = "cat `$ORACLE_HOME/network/admin/sqlnet.ora | grep 'SQLNET.CRYPTO_CHECKSUM_SERVER'"
				
				$InvokeRunCommandParam = @{
					vmname = $oraclevm.Name
					rgname = $oraclevm.ResourceGroupName
					subid  = $subscriptionId
					token  = $token
					command = $command
				}
				
				$sqlnetcryptooutput = Invoke-RunCommand @InvokeRunCommandParam
				$sqlnetcryptooutput = $sqlnetcryptooutput.trimstart().trimend()
				
				it "_$($oraclevm.Name)_CRYPTO" {
					$sqlnetcryptooutput | Should -BeLike "*SQLNET.CRYPTO_CHECKSUM_SERVER = required*"
				}
				#endregion	
			}
		}
	}
}
#endregion
#>