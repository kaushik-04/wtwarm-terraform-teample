# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {

    Describe "[Iteration] Test project Iteration creation" -Tag Build {

        It "Should update iterations as expected" {

            # Set mocks
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*/classificationnodes/Iterations*" -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).id -eq 1 -and
                (ConvertFrom-Json $body).name -eq 'Iteration 1 New'
            } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}*" -f [uri]::EscapeDataString('Iteration 1')) -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).id -eq 11 -and
                (ConvertFrom-Json $body).attributes.startDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2020-06-01').ToString('yyyy-MM-ddThh:mm:ssZ')
            } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}/{1}*" -f [uri]::EscapeDataString('Iteration 1'), [uri]::EscapeDataString('Iteration 1.1')) -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).id -eq 111 -and
                (ConvertFrom-Json $body).name -eq 'Iteration 1.1.1 New' -and
                (ConvertFrom-Json $body).attributes.startDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2020-06-01').ToString('yyyy-MM-ddThh:mm:ssZ') -and
                (ConvertFrom-Json $body).attributes.finishDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-10-02').ToString('yyyy-MM-ddThh:mm:ssZ')
            } -Verifiable

            # Non intended invocation
            Mock Out-File -MockWith { throw "This invocation in 'Invoke-RESTCommand' should never be reached" }

            $inputObject = @{
                Organization = 'contoso'
                Project      = 'Module Playground'
                Iterations   = @(
                    @{
                        id                 = 1
                        Name               = "Iteration 1 New"
                        'Old Name'         = "Iteration 1"
                        url                = "https://dev.azure.com/contoso/Module%20Playground/_apis/wit/classificationNodes/Iterations/Iteration%201"
                        GEN_RelationString = "Module Playground-[_Child_]-Iteration 1"
                    },
                    @{
                        id                 = 11
                        Startdate          = "2020-06-01"
                        "Old Startdate"    = "2020-01-01"
                        url                = "https://dev.azure.com/contoso/Module%20Playground/_apis/wit/classificationNodes/Iterations/Iteration%201/Iteration%201.1"
                        GEN_RelationString = "Module Playground-[_Child_]-Iteration 1-[_Child_]-Iteration 1.1"
                    },
                    @{
                        id                 = 111
                        Name               = "Iteration 1.1.1 New"
                        "Old Name"         = "Iteration 1.1.1"
                        Startdate          = "2020-06-01"
                        "Old Startdate"    = "-"
                        Finishdate         = "2021-10-02"
                        "Old Finshdate"    = "2020-09-01"
                        url                = "https://dev.azure.com/contoso/Module%20Playground/_apis/wit/classificationNodes/Iterations/Iteration%201/Iteration%201.1/Iteration%201.1.1"
                        GEN_RelationString = "Module Playground-[_Child_]-Iteration 1-[_Child_]-Iteration 1.1-[_Child_]-Iteration 1.1.1"
                    }
                )
                DryRun       = $false
            }
            { Set-ProjectIterationRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}
