<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		Set-AkvSecrets.ps1

		Purpose:	Set Azure Bastion Key Secrets

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
		Set Azure Bastion Key Secrets.

	.DESCRIPTION
		Set Azure Bastion Key Secrets.

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Azure Bastion Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER azureBastionName
		Specify the Azure Bastion Name output parameter.

	.PARAMETER azureBastionResourceId
		Specify the Azure Bastion ResourceId output parameter.

	.PARAMETER azureBastionResourceGroup
		Specify the Azure Bastion ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\Set-AkvSecrets.ps1
			-keyVaultName "$(keyVaultName)"
			-azureBastionName "$(azureBastionName)"
			-azureBastionResourceId "$(azureBastionResourceId)"
			-azureBastionResourceGroup "$(azureBastionResourceGroup)"
#>

#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$azureBastionName,

	[Parameter(Mandatory = $false)]
	[string]$azureBastionResourceId,

	[Parameter(Mandatory = $false)]
	[string]$azureBastionResourceGroup
)

#region - KeyVault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name: $keyVaultName"
	$kvSecretParameters = @{ }

	#region - Azure Bastion Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['azureBastionName']))
	{
		Write-Output "Azure Bastion Name: $azureBastionName"
		$kvSecretParameters.Add("AzureBastion-Name-$($azureBastionName)", $($azureBastionName))
	}
	else
	{
		Write-Output "Azure Bastion Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['azureBastionResourceId']))
	{
		Write-Output "Azure Bastion ResourceId: $azureBastionResourceId"
		$kvSecretParameters.Add("AzureBastion-ResourceId-$($azureBastionName)", $($azureBastionResourceId))
	}
	else
	{
		Write-Output "Azure Bastion ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['azureBastionResourceGroup']))
	{
		Write-Output "Azure Bastion ResourceGroup: $azureBastionResourceGroup"
		$kvSecretParameters.Add("AzureBastion-ResourceGroup-$($azureBastionName)", $($azureBastionResourceGroup))
	}
	else
	{
		Write-Output "Azure Bastion ResourceGroup: []"
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