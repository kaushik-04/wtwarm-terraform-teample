<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		Set-AkvSecrets.ps1

		Purpose:	Set Load Balancer Key Secrets

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
		Set Load Balancer Key Secrets.

	.DESCRIPTION
		Set Load Balancer Key Secrets.

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Load Balancer Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER loadBalancerName
		Specify the Load Balancer Name output parameter.

	.PARAMETER loadBalancerResourceId
		Specify the Load Balancer ResourceId output parameter.

	.PARAMETER loadBalancerResourceGroup
		Specify the Load Balancer ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\Set-AkvSecrets.ps1
			-keyVaultName "$(keyVaultName)"
			-loadBalancerName "$(loadBalancerName)"
			-loadBalancerResourceId "$(loadBalancerResourceId)"
			-loadBalancerResourceGroup "$(loadBalancerResourceGroup)"
#>

#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$loadBalancerName,

	[Parameter(Mandatory = $false)]
	[string]$loadBalancerResourceId,

	[Parameter(Mandatory = $false)]
	[string]$loadBalancerResourceGroup
)

#region - KeyVault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name: $keyVaultName"
	$kvSecretParameters = @{ }

	#region - Load Balancer Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['loadBalancerName']))
	{
		Write-Output "Load Balancer Name: $loadBalancerName"
		$kvSecretParameters.Add("LoadBalancer-Name-$($loadBalancerName)", $($loadBalancerName))
	}
	else
	{
		Write-Output "Load Balancer Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['loadBalancerResourceId']))
	{
		Write-Output "Load Balancer ResourceId: $loadBalancerResourceId"
		$kvSecretParameters.Add("LoadBalancer-ResourceId-$($loadBalancerName)", $($loadBalancerResourceId))
	}
	else
	{
		Write-Output "Load Balancer ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['loadBalancerResourceGroup']))
	{
		Write-Output "Load Balancer ResourceGroup: $loadBalancerResourceGroup"
		$kvSecretParameters.Add("LoadBalancer-ResourceGroup-$($loadBalancerName)", $($loadBalancerResourceGroup))
	}
	else
	{
		Write-Output "Load Balancer ResourceGroup: []"
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