<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		Set-AkvSecrets.ps1

		Purpose:	Set Azure Firewall Key Secrets

		Version: 	3.0.0.0 - 1st November 2020
		==============================================================================================

		DISCLAIMER
		==============================================================================================
		This script is not supported under any Microsoft standard support program or service.

		This script is provided AS IS without warranty of any kind.
		Microsoft further disclaims all implied warranties including, without limitation, any
		implied warranties of merchantability or of fitness for a particular purpose.

		The entire risk arising out of the use or performance of the script
		and documentation remains with you. In no event shall Microsoft, its authors,
		or anyone else involved in the creation, production, or delivery of the
		script be liable for any damages whatsoever (including, without limitation,
		damages for loss of business profits, business interruption, loss of business
		information, or other pecuniary loss) arising out of the use of or inability
		to use the sample scripts or documentation, even if Microsoft has been
		advised of the possibility of such damages.

		IMPORTANT
		==============================================================================================
		This script uses or is used to either create or sets passwords and secrets.
		All coded passwords or secrests supplied from input files must be created and provided by the customer.
		Ensure all passwords used by any script are generated and provided by the customer
		==============================================================================================

	.SYNOPSIS
		Set Azure Firewall Key Secrets.

	.DESCRIPTION
		Set Azure Firewall Key Secrets.

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Azure Firewall Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER azureFirewallName
		Specify the Azure Firewall Name output parameter.

	.PARAMETER azureFirewallResourceId
		Specify the Azure Firewall ResourceId output parameter.

	.PARAMETER azureFirewallResourceGroup
		Specify the Azure Firewall ResourceGroup output parameter.

	.PARAMETER azureFirewallPublicIp
		Specify the Azure Firewall Public IP output parameter.

	.PARAMETER azureFirewallPrivateIp
		Specify the Azure Firewall Private IP output parameter.

		
		
	.EXAMPLE
		Default:
		C:\PS>.\Set-AkvSecrets.ps1
			-keyVaultName "$(keyVaultName)"
			-azureFirewallName "$(azureFirewallName)"
			-azureFirewallResourceId "$(azureFirewallResourceId)"
			-azureFirewallResourceGroup "$(azureFirewallResourceGroup)"
			-azureFirewallPublicIp "$(azureFirewallPublicIp)"
			-azureFirewallPrivateIp "$(azureFirewallPrivateIp)"
#>

#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$azureFirewallName,

	[Parameter(Mandatory = $false)]
	[string]$azureFirewallResourceId,

	[Parameter(Mandatory = $false)]
	[string]$azureFirewallResourceGroup,

	[Parameter(Mandatory = $false)]
	[string]$azureFirewallPublicIp,

	[Parameter(Mandatory = $false)]
	[string]$azureFirewallPrivateIp 	
)

#region - KeyVault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name: $keyVaultName"
	$kvSecretParameters = @{ }

	#region - Azure Firewall Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['azureFirewallName']))
	{
		Write-Output "Azure Firewall Name: $azureFirewallName"
		$kvSecretParameters.Add("AzureFirewall-Name-$($azureFirewallName)", $($azureFirewallName))
	}
	else
	{
		Write-Output "Azure Firewall Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['azureFirewallResourceId']))
	{
		Write-Output "Azure Firewall ResourceId: $azureFirewallResourceId"
		$kvSecretParameters.Add("AzureFirewall-ResourceId-$($azureFirewallName)", $($azureFirewallResourceId))
	}
	else
	{
		Write-Output "Azure Firewall ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['azureFirewallResourceGroup']))
	{
		Write-Output "Azure Firewall ResourceGroup: $azureFirewallResourceGroup"
		$kvSecretParameters.Add("AzureFirewall-ResourceGroup-$($azureFirewallName)", $($azureFirewallResourceGroup))
	}
	else
	{
		Write-Output "Azure Firewall ResourceGroup: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['azureFirewallPublicIp']))
	{
		Write-Output "Azure Firewall PublicIp: $azureFirewallPublicIp"
		$kvSecretParameters.Add("AzureFirewall-PublicIP-$($azureFirewallName)", $($azureFirewallPublicIp))
	}
	else
	{
		Write-Output "Azure Firewall PublicIP: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['azureFirewallPublicIp']))
	{
		Write-Output "Azure Firewall PrivateIp: $azureFirewallPrivateIp"
		$kvSecretParameters.Add("AzureFirewall-PrivateIP-$($azureFirewallName)", $($azureFirewallPrivateIp))
	}
	else
	{
		Write-Output "Azure Firewall PrivateIP: []"
	}
	#endregion

	#region - Set Azure KeyVault Secret
	$kvSecretParameters.Keys | ForEach-Object {
		$key = $psitem
		$value = $kvSecretParameters.Item($psitem)

		if (-not [string]::IsNullOrWhiteSpace($value))
		{
			Write-Output "KeyVault Secret: $key : $value"
			$value = $kvSecretParameters.Item($psitem)
			$paramSetAzKeyVaultSecret = @{
				VaultName   = $keyVaultName
				Name        = $key
				SecretValue = (ConvertTo-SecureString $value -AsPlainText -Force)
				Verbose     = $true
			}
			Set-AzKeyVaultSecret @paramSetAzKeyVaultSecret
		}
		else
		{
			Write-Output "KeyVault Secret: $key - []"
		}
	}
	#endregion
}
else
{
	Write-Output "KeyVault Name: []"
}
#endregion