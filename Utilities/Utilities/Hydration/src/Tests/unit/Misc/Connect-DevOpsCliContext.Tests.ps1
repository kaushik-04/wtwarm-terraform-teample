# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {

    Describe "[Misc] Connect-DevOps" -Tag Build {
    
        It "Should prompt for login" {
            Connect-DevOps -WhatIf
        }
    }
}