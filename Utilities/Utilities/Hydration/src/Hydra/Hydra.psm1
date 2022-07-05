
<#
<copyright file="hydration.Common.psm1" company="Microsoft">
	Copyright (c) Microsoft. All Rights Reserved.
</copyright>
<summary>
	Common Utility Functions for Azure DevOps Hydration.
</summary>
#>


[cmdletbinding()]
param()

# Load central config file; Config File can be referenced within module scope by $script:CONFIG
Write-Verbose 'Load Config'
$moduleConfigPath = Join-Path $PSScriptRoot 'ModuleConfig.psd1'
$script:CONFIG = Import-PowerShellDataFile -Path (Resolve-Path ($moduleConfigPath))

$moduleRoot = $PSScriptRoot
Write-Verbose "The module root it [$moduleRoot]"

Write-Verbose 'Import everything in sub folders public, private, classes folder'
$functionFolders = @('Public', 'Private', 'Classes')
ForEach ($folder in $functionFolders) {
    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder
    If (Test-Path -Path $folderPath) {
        Write-Verbose "Importing from $folder"
        $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1' -recurse
        ForEach ($function in $functions) {
            Write-Verbose ("  Importing [{0}]" -f $function.BaseName)
            . $($function.FullName)
        }
    }
}
$publicFunctions = (Get-ChildItem -Path "$PSScriptRoot\Public" -Filter '*.ps1').BaseName
Export-ModuleMember -Function $publicFunctions
