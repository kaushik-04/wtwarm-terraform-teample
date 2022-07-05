# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {

    Describe "[Area] Test project area creation" -Tag Build {

        It "Should craete exected project areas" {


            # Load data
            $localProjectDataPath = Join-Path $PSScriptRoot 'resources\NewProjectAreaRange.json'
            $localProjectData = ConvertFrom-Json (Get-Content -Path $localProjectDataPath -Raw)
            $flatlocalAreas = Resolve-ClassificationNodesFormatted -Nodes $localProjectData -project 'Module Playground'

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*/classificationnodes/Areas*" -and ($body -like "*Area 1*") -and $method -eq 'POST' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*/classificationnodes/Areas*" -and ($body -like "*Area 2*") -and $method -eq 'POST' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*/classificationnodes/Areas*" -and ($body -like "*Area 3*") -and $method -eq 'POST' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Areas/{0}*" -f [uri]::EscapeDataString('Area 3')) -and ($body -like "*Area 31*") -and $method -eq 'POST' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Areas/{0}/{1}*" -f [uri]::EscapeDataString('Area 3'), [uri]::EscapeDataString('Area 31')) -and ($body -like "*Area 311*") -and $method -eq 'POST' } -Verifiable

            $inputObject = @{
                Organization = 'contoso'
                Project      = 'Module Playground'
                AreaPaths    = $flatlocalAreas
                DryRun       = $false
            }
            { New-ProjectAreaRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}