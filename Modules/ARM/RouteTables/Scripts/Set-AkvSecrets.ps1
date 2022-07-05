<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		Set-AkvSecrets.ps1

		Purpose:	Set Route Table Key Secrets

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
		All coded passwords or secrets supplied from input files must be created and provided by the customer.
		Ensure all passwords used by any script are generated and provided by the customer
		==============================================================================================

	.SYNOPSIS
		Set Route Table Key Secrets.

	.DESCRIPTION
		Set Route Table Key Secrets.

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Route Table Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER routeTableName
		Specify the Route Table Name output parameter.

	.PARAMETER routeTableResourceId
		Specify the Route Table ResourceId output parameter.

	.PARAMETER routeTableResourceGroup
		Specify the Route Table ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\Set-AkvSecrets.ps1
			-keyVaultName "$(keyVaultName)"
			-routeTableName "$(routeTableName)"
			-routeTableResourceId "$(routeTableResourceId)"
			-routeTableResourceGroup "$(routeTableResourceGroup)"
#>

#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$routeTableName,

	[Parameter(Mandatory = $false)]
	[string]$routeTableResourceId,

	[Parameter(Mandatory = $false)]
	[string]$routeTableResourceGroup
)

#region - KeyVault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name: $keyVaultName"
	$kvSecretParameters = @{ }

	#region - Route Table Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['routeTableName']))
	{
		Write-Output "Route Table Name: $routeTableName"
		$kvSecretParameters.Add("RouteTable-Name-$($routeTableName)", $($routeTableName))
	}
	else
	{
		Write-Output "Route Table Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['routeTableResourceId']))
	{
		Write-Output "Route Table ResourceId: $routeTableResourceId"
		$kvSecretParameters.Add("RouteTable-ResourceId-$($routeTableName)", $($routeTableResourceId))
	}
	else
	{
		Write-Output "Route Table ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['routeTableResourceGroup']))
	{
		Write-Output "Route Table ResourceGroup: $routeTableResourceGroup"
		$kvSecretParameters.Add("RouteTable-ResourceGroup-$($routeTableName)", $($routeTableResourceGroup))
	}
	else
	{
		Write-Output "Route Table ResourceGroup: []"
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