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
    Throw "Set-PolicyDefinitions - Path '$ParametersFilePath' not found"
}

#endregion

#region configure Set-PolicyDefinitions function

$params = @{
    ParametersFilePath = "$ParametersFilePath"
}

Write-Output "Set-PolicyDefinitions with parameters"
$params
Set-PolicyDefinitions @params
Write-Output "Set-PolicyDefinitions OK"
#endregion

