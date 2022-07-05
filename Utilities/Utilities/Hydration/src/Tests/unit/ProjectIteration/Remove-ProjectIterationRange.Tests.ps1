# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Iteration] Test project iteration removal" -Tag Build {

        It "Should remove exected project iterations" {

            # Load data
            $remoteProjectDataPath = Join-Path $PSScriptRoot 'resources\RemoveProjectIterationRange.json'
            $remoteProjectData = (ConvertFrom-Json (Get-Content -Path $remoteProjectDataPath -Raw)).value
            $flatRemoteIterations = Resolve-ClassificationNodesFormatted -Nodes $remoteProjectData

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}*" -f [uri]::EscapeDataString('Iteration 1')) -and $method -eq 'DELETE' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}*" -f [uri]::EscapeDataString('Iteration 2')) -and $method -eq 'DELETE' } -Verifiable

            # Non intended invocation
            Mock Out-File -MockWith { throw "This invocation in 'Invoke-RESTCommand' should never be reached" }

            $inputObject = @{
                Organization   = 'contoso'
                Project        = 'Module Playground'
                IterationPaths = $flatRemoteIterations
                DryRun         = $false
            }
            { Remove-ProjectIterationRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw


            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}