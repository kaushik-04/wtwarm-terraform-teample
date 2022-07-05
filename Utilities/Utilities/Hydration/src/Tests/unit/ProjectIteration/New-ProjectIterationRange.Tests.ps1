# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {

    Describe "[Iteration] Test project Iteration creation" -Tag Build {

        It "Should craete exected project Iterations" {


            # Load data
            $localProjectDataPath = Join-Path $PSScriptRoot 'resources\NewProjectIterationRange.json'
            $localProjectData = ConvertFrom-Json (Get-Content -Path $localProjectDataPath -Raw)
            $flatlocalIterations = Resolve-ClassificationNodesFormatted -Nodes $localProjectData -project 'Module Playground'

            # Create mocks
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*/classificationnodes/Iterations*" -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).name -eq 'Iteration 1' -and
                (ConvertFrom-Json $body).attributes.startDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-01').ToString('yyyy-MM-ddThh:mm:ssZ') -and
                (ConvertFrom-Json $body).attributes.finishDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-06-01').ToString('yyyy-MM-ddThh:mm:ssZ')
            } -MockWith { return @{name = 'Iteration 1' } } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*/classificationnodes/Iterations*" -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).name -eq 'Iteration 2'
            } -MockWith { return @{name = 'Iteration 2' } } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*/classificationnodes/Iterations*" -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).name -eq 'Iteration 3'
            } -MockWith { return @{name = 'Iteration 3' } } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}*" -f [uri]::EscapeDataString('Iteration 3')) -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).name -eq 'Iteration 3.1' -and
                (ConvertFrom-Json $body).attributes.startDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-04').ToString('yyyy-MM-ddThh:mm:ssZ') -and
                (ConvertFrom-Json $body).attributes.finishDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-11').ToString('yyyy-MM-ddThh:mm:ssZ')
            } -MockWith { return @{name = 'Iteration 3.1' } } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}*" -f [uri]::EscapeDataString('Iteration 3')) -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).name -eq 'Iteration 3.2' -and
                (ConvertFrom-Json $body).attributes.startDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-12').ToString('yyyy-MM-ddThh:mm:ssZ') -and
                (ConvertFrom-Json $body).attributes.finishDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-18').ToString('yyyy-MM-ddThh:mm:ssZ')
            } -MockWith { return @{name = 'Iteration 3.2' } } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}/{1}*" -f [uri]::EscapeDataString('Iteration 3'), [uri]::EscapeDataString('Iteration 3.2')) -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).name -eq 'Iteration 3.2.1' -and
                (ConvertFrom-Json $body).attributes.startDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-04').ToString('yyyy-MM-ddThh:mm:ssZ') -and
                (ConvertFrom-Json $body).attributes.finishDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-11').ToString('yyyy-MM-ddThh:mm:ssZ')
            } -MockWith { return @{name = 'Iteration 3.2.1' } } -Verifiable

            # Non intended invocation
            Mock Out-File -MockWith { throw "This invocation in 'Invoke-RESTCommand' should never be reached" }

            $inputObject = @{
                Organization = 'contoso'
                Project      = 'Module Playground'
                Iterations   = $flatlocalIterations
                DryRun       = $false
            }
            { New-ProjectIterationRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}