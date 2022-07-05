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
    Throw "Set-PolicyAssignments - Path '$ParametersFilePath' not found"
}
$file = Get-Content -Raw -Path $ParametersFilePath | ConvertFrom-Json
Write-Output "Set-PolicyAssignments - File '$ParametersFilePath' read"
#endregion

#region configure Set-PolicyAssignments function

$params = @{
    ParametersFilePath = $ParametersFilePath
}


Write-Output "Set-PolicyAssignments with parameters"
$params
Set-PolicyAssignments @params
Write-Output "Set-PolicyAssignments OK"
#endregion

$ParametersFile = Get-Item -Path $ParametersFilePath
$JSON = $ParametersFile | Get-Content
$ParameterObject = $JSON | ConvertFrom-Json
$Outofscope = $ParameterObject.parameters.properties.value.policyAssignment.managedIdentity.outofscope
if ($Outofscope) {
    Write-Output "Fix-PolicyPermission with parameters"
    Fix-PolicyPermission @params
    Write-Output "Fix-PolicyPermission OK"
}


