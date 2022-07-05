[cmdletbinding()]
param(
    [Parameter(Mandatory)]
    [string] $ParametersFilePath
)

#region Import module
$ModulePath = Get-ChildItem -Path $PSScriptRoot\scripts -File -Recurse -Include '*.ps1', '*.psm1'
$ModulePath | ForEach-Object {
    Write-Output "Loading $($_.FullName)"
    Get-Module $_.BaseName | Remove-Module -Force
    Import-Module $_.FullName -Force -DisableNameChecking
}
#endregion

#region Check parameters file
if (-not (Test-Path -Path $ParametersFilePath)) {
    Throw "Remove-UndocumentedFirewallRules - Path '$ParametersFilePath' not found"
}

#endregion

#region configure Set-SecurityCenterConfiguration function

$params = @{
    ParametersFilePath = "$ParametersFilePath"
}

Write-Output "Remove-UndocumentedFirewallRules with parameters"
$params
Remove-UndocumentedFirewallRules @params
Write-Output "Remove-UndocumentedFirewallRules OK"
#endregion