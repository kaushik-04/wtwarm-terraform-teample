# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent))

InModuleScope $ModuleName {

    Describe "[Project] Should Get-DevOpsProcessList" -Tag Integration {

        It "Should not throw fetching the id" {

            $HydrationDefinitionPath = Join-Path $PSScriptRoot 'resources\hydrationDefinitionBefore.json'
            $definition = ConvertFrom-Json (Get-Content -Path $HydrationDefinitionPath -Raw)

            { Get-DevOpsProcessList -Organization $definition.organizationName -ErrorAction 'Stop' } | Should -Not -Throw
        }
    }
}