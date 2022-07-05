<#
.SYNOPSIS
Get-EnvironmentVariables

.DESCRIPTION
Get-EnvironmentVariables

.EXAMPLE
Get-EnvironmentVariables
#>

function Get-EnvironmentVariables {

  Write-Verbose "----------------------------------"
  Get-ChildItem env:

  Write-Verbose "----------------------------------"
  Write-Host "AZURE_DEVOPS_CLI_PAT: $env:AZURE_DEVOPS_CLI_PAT"
  Write-Host "AZURE_DEVOPS_EXT_PAT: $env:AZURE_DEVOPS_EXT_PAT"
  Write-Host "BUILD_REQUESTEDFOR: $env:BUILD_REQUESTEDFOR"
  Write-Host "ENDPOINT_URL_SYSTEMVSSCONNECTION: $env:ENDPOINT_URL_SYSTEMVSSCONNECTION"
  Write-Host "SYSTEM_COLLECTIONURI: $env:SYSTEM_COLLECTIONURI"
  Write-Host "ORGANIZATIONNAME: $env:ORGANIZATIONNAME"
  Write-Host "SYSTEM_TEAMPROJECT: $env:SYSTEM_TEAMPROJECT"
  Write-Host "SYSTEM_TEAMFOUNDATIONCOLLECTIONURI: $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI"
  Write-Host "SYSTEM_TEAMFOUNDATIONSERVERURI: $env:SYSTEM_TEAMFOUNDATIONSERVERURI"
  Write-Host "AZURE_DEVOPS_EXT_PAT: $env:AZURE_DEVOPS_EXT_PAT"
  Write-Verbose "----------------------------------"
}
