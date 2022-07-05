<#
.SYNOPSIS
Prepare the environment with required Modules

.PARAMETER Modules
The list of the modules that should be installed and imported before continuing using this module

.EXAMPLE
Initialize-CSPEnvironment -Modules PartnerCenter

Installs and imports the PartnerCenter Module

#>
Function Initialize-AADEnvironment {
    [Cmdletbinding()]
    param(
        [String[]]
        $Modules = ("AzureAD")
    )
    Write-Verbose "Processing Modules"
    foreach ($Module in $Modules) {
        Write-Verbose "Processing: $Module"
        if (Get-Module -ListAvailable -Name $Module) {
            Write-Verbose "Processing: $Module - Is installed"
        } else {
            Write-Verbose "Processing: $Module - Is not installed. Installing now."
            Install-Module -Name $Modules -AllowClobber -Force
        }
    }
    Write-Verbose "Processing: $Modules - Importing modules"
    Import-Module -Name $Modules
}
