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
    Throw "Set-SecurityCenterConfiguration - Path '$ParametersFilePath' not found"
}

#endregion

#region configure Set-SecurityCenterConfiguration function

$params = @{
    ParametersFilePath = "$ParametersFilePath"
}

Write-Output "Set-SecurityCenterConfiguration with parameters"
$params
Set-SecurityCenterConfiguration @params
Write-Output "Set-SecurityCenterConfiguration OK"
#endregion