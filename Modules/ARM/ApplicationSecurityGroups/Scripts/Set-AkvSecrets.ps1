<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		Set-AkvSecrets.ps1

		Purpose:	Set Application Security Group Key Secrets

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
		Set Application Security Group Key Secrets.

	.DESCRIPTION
		Set Application Security Group Key Secrets.

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Application Security Group Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER applicationSecurityGroupName
		Specify the Application Security Group Name output parameter.

	.PARAMETER applicationSecurityGroupResourceId
		Specify the Application Security Group ResourceId output parameter.

	.PARAMETER applicationSecurityGroupResourceGroup
		Specify the Application Security Group ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\Set-AkvSecrets.ps1
			-keyVaultName "$(keyVaultName)"
			-applicationSecurityGroupName "$(applicationSecurityGroupName)"
			-applicationSecurityGroupResourceId "$(applicationSecurityGroupResourceId)"
			-applicationSecurityGroupResourceGroup "$(applicationSecurityGroupResourceGroup)"
#>

#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$applicationSecurityGroupName,

	[Parameter(Mandatory = $false)]
	[string]$applicationSecurityGroupResourceId,

	[Parameter(Mandatory = $false)]
	[string]$applicationSecurityGroupResourceGroup
)

#region - KeyVault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name: $keyVaultName"
	$kvSecretParameters = @{ }

	#region - Application Security Group Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['applicationSecurityGroupName']))
	{
		Write-Output "Application Security Group Name: $applicationSecurityGroupName"
		$kvSecretParameters.Add("ApplicationSecurityGroup-Name-$($applicationSecurityGroupName)", $($applicationSecurityGroupName))
	}
	else
	{
		Write-Output "Application Security Group Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['applicationSecurityGroupResourceId']))
	{
		Write-Output "Application Security Group ResourceId: $applicationSecurityGroupResourceId"
		$kvSecretParameters.Add("ApplicationSecurityGroup-ResourceId-$($applicationSecurityGroupName)", $($applicationSecurityGroupResourceId))
	}
	else
	{
		Write-Output "Application Security Group ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['applicationSecurityGroupResourceGroup']))
	{
		Write-Output "Application Security Group ResourceGroup: $applicationSecurityGroupResourceGroup"
		$kvSecretParameters.Add("ApplicationSecurityGroup-ResourceGroup-$($applicationSecurityGroupName)", $($applicationSecurityGroupResourceGroup))
	}
	else
	{
		Write-Output "Application Security Group ResourceGroup: []"
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