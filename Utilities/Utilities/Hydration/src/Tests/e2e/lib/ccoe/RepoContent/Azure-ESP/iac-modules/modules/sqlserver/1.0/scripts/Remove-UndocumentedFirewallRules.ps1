<#
Description: This script is used to remove any undocumented firewall rule at SQL server level.
             Undocumeneted means the firewall rule name is not present in the parameter file.
#>

function Remove-UndocumentedFirewallRules {
  [cmdletbinding()]
  param(
      [Parameter(Mandatory)]
      [string] $ParametersFilePath
  )

  # Extracting parameter file properties
  $parametersFile = Get-Content -Raw -Path $ParametersFilePath | ConvertFrom-Json
  $removeUndocumentedFirewallRules = $parametersFile.parameters.removeUndocumentedFirewallRules.value

  if ($removeUndocumentedFirewallRules)
  {
    $resourceGroupName = $parametersFile.parameters.resourceGroupName.value
    $serverName = $parametersFile.parameters.serverName.value
    $firewallRules = $parametersFile.parameters.firewallRules.value
    
    # create an array of strings - only rule names
    $arFirewallRules = $firewallRules | % {$_.ruleName}

    # get existing rules (if server exists) and compare with firewall rules documented in parameter file, if not found the rule gets removed
    $myServer = Get-AzResource -Name $serverName -ResourceType "Microsoft.Sql/servers"
    if ($myServer)
    {
      $curFwRules = Get-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $serverName

      $curFwRules.Where({ $_.FirewallRuleName -ne 'AllowAllWindowsAzureIps' }) | ForEach-Object {
          if ($arFirewallRules -contains $_.FirewallRuleName) {
              Write-Host (-join("OK - ", $_.FirewallRuleName))
          }
          else {
              Write-Host (-join("Parameter file does NOT contain rule ", $_.FirewallRuleName))
              Write-Host "Deleting undocumented rule..."
              Remove-AzSqlServerFirewallRule -FirewallRuleName $_.FirewallRuleName -ResourceGroupName $resourceGroupName -ServerName $serverName -Force
              Write-Host "Deleted"
          }
      }
    }
  }
  else {
    Write-Host "Firewall rules not checked - 'removeUndocumentedFirewallRules' parameter is set to 'false'"
  }
}