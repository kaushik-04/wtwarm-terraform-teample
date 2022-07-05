[cmdletbinding()]
param(
    [Parameter(Mandatory)]
    [string] $ParametersFilePath
)

#region Import module
$ModulePath = Get-ChildItem -Path $PSScriptRoot\scripts -File -Recurse -Include 'AADServicePrincipal.psm1'
$ModulePath | ForEach-Object {
    Write-Output "Loading $($_.FullName)"
    Get-Module $_.BaseName | Remove-Module -Force
    Import-Module $_.FullName -Force -DisableNameChecking
}
#endregion

#region deploy Service Principal
Write-Output "Deploy-AADServicePrincipal with parameters"
$params = @{
    ParametersFilePath = "$ParametersFilePath"
}
Write-Output ($params | Out-String)
Deploy-AADServicePrincipal @params
Write-Output "Deploy-AADServicePrincipal OK"
#endregion