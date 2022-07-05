# Dot source this script in any Pester test script that requires the module to be imported.

$ModuleName = 'Hydra'
$ModuleBase = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) $ModuleName

# For tests in .\Tests subdirectory
if ((Split-Path $ModuleBase -Leaf) -eq 'Test') {
    $ModuleBase = Split-Path $ModuleBase -Parent
}

# Removes all versions of the module from the session before importing
Get-Module $ModuleName | Remove-Module

# Because ModuleBase includes version number, this imports the required version
# of the module
$ModuleManifestPath = Join-Path $ModuleBase "$ModuleName.psd1"

$null = Import-Module $ModuleManifestPath -ErrorAction 'Stop'

Write-Verbose 'Load Config'
$testConfigPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestConfig.psd1'
$global:TESTCONFIG = Import-PowerShellDataFile -Path (Resolve-Path ($testConfigPath))

if (!$SuppressImportModule) {
    # -Scope Global is needed when running tests from inside of psake, otherwise
    # the module's functions cannot be found in the modules namespace
    $null = Import-Module $ModuleManifestPath -Scope 'Global'
}
