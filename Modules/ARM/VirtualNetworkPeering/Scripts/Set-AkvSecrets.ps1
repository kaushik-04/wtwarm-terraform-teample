<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		Set-AkvSecrets.ps1

		Purpose:	Set Virtual Network Peering Key Secrets

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
		Set Virtual Network Peering Key Secrets.

	.DESCRIPTION
		Set Virtual Network Peering Key Secrets.

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Virtual Network Peering Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER vNetPeeringName
		Specify the Virtual Network Peering Name output parameter.

	.PARAMETER vNetPeeringResourceId
		Specify the Virtual Network Peering ResourceId output parameter.

	.PARAMETER vNetPeeringResourceGroup
		Specify the Virtual Network Peering ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\Set-AkvSecrets.ps1
			-keyVaultName "$(keyVaultName)"
			-vNetPeeringName "$(vNetPeeringName)"
			-vNetPeeringResourceId "$(vNetPeeringResourceId)"
			-vNetPeeringResourceGroup "$(vNetPeeringResourceGroup)"
#>

#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$vNetPeeringName,

	[Parameter(Mandatory = $false)]
	[string]$vNetPeeringResourceId,

	[Parameter(Mandatory = $false)]
	[string]$vNetPeeringResourceGroup
)

#region - KeyVault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name: $keyVaultName"
	$kvSecretParameters = @{ }

	#region - Virtual Network Peering Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['vNetPeeringName']))
	{
		Write-Output "Virtual Network Peering Name: $vNetPeeringName"
		$kvSecretParameters.Add("vNetPeering-Name-$($vNetPeeringName)", $($vNetPeeringName))
	}
	else
	{
		Write-Output "Virtual Network Peering Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['vNetPeeringResourceId']))
	{
		Write-Output "Virtual Network Peering ResourceId: $vNetPeeringResourceId"
		$kvSecretParameters.Add("vNetPeering-ResourceId-$($vNetPeeringName)", $($vNetPeeringResourceId))
	}
	else
	{
		Write-Output "Virtual Network Peering ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['vNetPeeringResourceGroup']))
	{
		Write-Output "Virtual Network Peering ResourceGroup: $vNetPeeringResourceGroup"
		$kvSecretParameters.Add("vNetPeering-ResourceGroup-$($vNetPeeringName)", $($vNetPeeringResourceGroup))
	}
	else
	{
		Write-Output "Virtual Network Peering ResourceGroup: []"
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