<#
.SYNOPSIS
Run Azure Pipelines.

.DESCRIPTION
This script is used to run Azure Pipelines.
If this scripts is run within an Azure Pipeline the environment variable AZURE_DEVOPS_EXT_PAT needs to be set with $(System.AccessToken) within your pipeline.
Since tty is not supported within a pipelune run, az devops login is using the token which is set via AZURE_DEVOPS_EXT_PAT.

.REQUIREMENTS
Azure CLI 2.13.0
Azure CLI extension devops 0.18.0

.PARAMETER folderPath
Optional. The name of the Pipelines folder.

.PARAMETER AzureDevOpsOrganization
Optional. The name of the Azure DevOps organization.

.PARAMETER AzureDevOpsProject
Optional. The name of the Azure DevOps project.

.EXAMPLE
Run-AzurePipelines
#>

function Run-AzurePipelines {
    
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string] $folderPath,

    [Parameter(Mandatory)]
    [string] $AzureDevOpsOrganization,

    [Parameter(Mandatory)]
    [string] $AzureDevOpsProject,

    [Parameter()]
    [string] $accessToken
  )

  try {
    Write-Verbose "----------------------------------"
    Write-Verbose "Installing Azure CLI extension devops"
    az config set extension.use_dynamic_install=yes_without_prompt   # to allow installing extensions without prompt
    az extension add --upgrade -n azure-devops

    if ($accessToken) {
      Write-Verbose "Login to Azure DevOps with personal access token"
      $env:AZURE_DEVOPS_EXT_PAT = $accessToken
    }
    else {
      Write-Verbose "Login to Azure DevOps with System.AccessToken from Azure Pipeline"
      Write-Output $env:AZURE_DEVOPS_EXT_PAT | az devops login
    }

    Write-Verbose "Setting default Azure DevOps configuration to $AzureDevOpsOrganization and $AzureDevOpsProject"
    az devops configure --defaults organization=$AzureDevOpsOrganization project="$AzureDevOpsProject" --use-git-aliases true

    Write-Verbose "Get and list all Pipelines in $folderPath"
    $pipelines = az pipelines list --organization $AzureDevOpsOrganization --project $AzureDevOpsProject --folder-path $folderPath | ConvertFrom-Json
    $pipelines.Name

    foreach ($pipeline in $pipelines) {
      Write-Verbose "Starting Azure Pipeline $($pipeline.Name) ... " -Verbose
      az pipelines run --id $($pipeline.Id)
    }
    Write-Verbose "----------------------------------"
    Write-Verbose "Logout of Azure DevOps"
    az devops logout
  }
  catch {
    Write-Warning ("Reason: [{0}]" -f $_.Exception.Message)
  }
}
