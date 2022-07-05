<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		Set-AkvSecrets.ps1

		Purpose:	Set Analysis Services Key Secrets

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
		Set Analysis Services Key Secrets.

	.DESCRIPTION
		Set Analysis Services Key Secrets.

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Analysis Services Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER analysisServicesName
		Specify the Analysis Services Name output parameter.

	.PARAMETER analysisServicesResourceId
		Specify the Analysis Services ResourceId output parameter.

	.PARAMETER analysisServicesResourceGroup
		Specify the Analysis Services ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\AnalysisServices.akv.set.secrets.ps1
			-keyVaultName "$(keyVaultName)"
			-analysisServicesName "$(analysisServicesName)"
			-analysisServicesResourceId "$(analysisServicesResourceId)"
			-analysisServicesResourceGroup "$(analysisServicesResourceGroup)"
#>

#Requires -Version 5
#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$analysisServicesName,

	[Parameter(Mandatory = $false)]
	[string]$analysisServicesResourceId,

	[Parameter(Mandatory = $false)]
	[string]$analysisServicesResourceGroup
)

#region - KeyVault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name: $keyVaultName"
	$kvSecretParameters = @{ }

	#region - Analysis Services Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['analysisServicesName']))
	{
		Write-Output "Analysis Services Name: $analysisServicesName"
		$kvSecretParameters.Add("AnalysisServices-Name-$($analysisServicesName)", $($analysisServicesName))
	}
	else
	{
		Write-Output "Analysis Services Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['analysisServicesResourceId']))
	{
		Write-Output "Analysis Services ResourceId: $analysisServicesResourceId"
		$kvSecretParameters.Add("AnalysisServices-ResourceId-$($analysisServicesName)", $($analysisServicesResourceId))
	}
	else
	{
		Write-Output "Analysis Services ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['analysisServicesResourceGroup']))
	{
		Write-Output "Analysis Services ResourceGroup: $analysisServicesResourceGroup"
		$kvSecretParameters.Add("AnalysisServices-ResourceGroup-$($analysisServicesName)", $($analysisServicesResourceGroup))
	}
	else
	{
		Write-Output "Analysis Services ResourceGroup: []"
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