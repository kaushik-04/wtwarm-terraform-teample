# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

Describe "[Misc] Get-HydraSchema" -Tag Build {

    It "Should return schema" {
        Get-HydraSchema  | Should -Not -BeNullOrEmpty
    }
}

