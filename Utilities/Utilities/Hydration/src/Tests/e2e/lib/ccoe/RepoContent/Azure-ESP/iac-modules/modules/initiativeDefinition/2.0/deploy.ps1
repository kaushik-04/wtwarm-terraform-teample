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
    Throw "Set-InitiativeDefinitions - Path '$ParametersFilePath' not found"
}
$file = Get-Content -Raw -Path $ParametersFilePath | ConvertFrom-Json
Write-Output "Set-InitiativeDefinitions - File '$ParametersFilePath' read"
#endregion


#region configure Set-InitiativeDefinitions function

$params = @{
    ParameterFilePath = $ParametersFilePath
}


Write-Output "Set-InitiativeDefinitions with parameters"
$params
Set-InitiativeDefinitions @params
Write-Output "Set-InitiativeDefinitions OK"
#endregion

