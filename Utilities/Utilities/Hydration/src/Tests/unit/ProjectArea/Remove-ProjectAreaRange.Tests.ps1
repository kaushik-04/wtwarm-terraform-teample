# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Area] Test project area removal" -Tag Build {

        It "Should remove exected project areas" {

            # Load data
            $remoteProjectDataPath = Join-Path $PSScriptRoot 'resources\RemoveProjectAreaRange.json'
            $remoteProjectData = (ConvertFrom-Json (Get-Content -Path $remoteProjectDataPath -Raw)).value
            $flatRemoteAreas = Resolve-ClassificationNodesFormatted -Nodes $remoteProjectData

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Areas/{0}*" -f [uri]::EscapeDataString('Area 1')) -and $method -eq 'DELETE' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Areas/{0}*" -f [uri]::EscapeDataString('Area 2')) -and $method -eq 'DELETE' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Areas/{0}*" -f [uri]::EscapeDataString('Area 3')) -and $method -eq 'DELETE' } -Verifiable

            $inputObject = @{
                Organization = 'contoso'
                Project      = 'Module Playground'
                AreaPaths    = $flatRemoteAreas
                DryRun       = $false
            }
            { Remove-ProjectAreaRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw


            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}