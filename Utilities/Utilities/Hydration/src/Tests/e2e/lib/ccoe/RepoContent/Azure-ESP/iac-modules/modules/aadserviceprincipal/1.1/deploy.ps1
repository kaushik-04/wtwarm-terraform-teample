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

#region configure Set-SPN function
$params = @{
    ParametersFilePath = "$ParametersFilePath"
}

Write-Output "Set-SPN with parameters"
$params
Set-SPN @params
Write-Output "Set-SPN OK"
#endregion
