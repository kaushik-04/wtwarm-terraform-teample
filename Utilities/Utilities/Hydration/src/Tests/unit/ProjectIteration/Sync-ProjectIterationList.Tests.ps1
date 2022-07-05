# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {

    Describe "[Iteration] Sync-ProjectIterationList" -Tag Build {

        It "Should remove & add all Iterations as expected" {

            # Load data
            $localProjectDataPath = Join-Path $PSScriptRoot 'resources\SyncProjectIterationListLocal.json'
            $localProjectData = ConvertFrom-Json (Get-Content -Path $localProjectDataPath -Raw)

            $remoteProjectDataRootPath = Join-Path $PSScriptRoot 'resources\SyncProjectIterationListRemoteRoot.json'
            $remoteProjectDataRoot = ConvertFrom-Json (Get-Content -Path $remoteProjectDataRootPath -Raw)

            # Get data mocks
            Mock Invoke-RESTCommand -MockWith { return $remoteProjectDataRoot } -ParameterFilter { $uri -like "*classificationnodes/Iterations*" -and $method -eq 'GET' } -Verifiable

            # Fetch Remote Data Mock - Returns different results for multiple invocations
            $script:InvokeRESTCommandTreedMockCalled = 0
            $getBacklogItemsCreatedScipt = {
                $script:InvokeRESTCommandTreedMockCalled++
                switch ($script:InvokeRESTCommandTreedMockCalled) {
                    1 {
                        # Initial state
                        return (Get-Content -Path (Join-Path $PSScriptRoot 'resources\SyncProjectIterationListRemoteTree.json') -Raw | ConvertFrom-Json)
                    }
                    2 {
                        # State after missing board items are created
                        return (Get-Content -Path (Join-Path $PSScriptRoot 'resources\SyncProjectIterationListRemoteTreePostUpdate.json') -Raw | ConvertFrom-Json)
                    }
                    3 {
                        # State after missing board items are created
                        return (Get-Content -Path (Join-Path $PSScriptRoot 'resources\SyncProjectIterationListRemoteTreePostRemoval.json') -Raw | ConvertFrom-Json)
                    }
                }
            }
            Mock Invoke-RESTCommand -MockWith $getBacklogItemsCreatedScipt -ParameterFilter { $uri -like ("*classificationnodes?ids={0}*" -f $remoteProjectDataRoot.id) -and $method -eq 'GET' } -Verifiable

            # Update mocks
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*/classificationnodes/Iterations*" -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).id -eq 1 -and
                (ConvertFrom-Json $body).attributes.startDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-01').ToString('yyyy-MM-ddThh:mm:ssZ') -and
                (ConvertFrom-Json $body).attributes.finishDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-06-01').ToString('yyyy-MM-ddThh:mm:ssZ')
            } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*/classificationnodes/Iterations*" -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).id -eq 2 -and
                (ConvertFrom-Json $body).name -eq 'Iteration 2 New' -and
                (ConvertFrom-Json $body).attributes.startDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-01').ToString('yyyy-MM-ddThh:mm:ssZ') -and
                (ConvertFrom-Json $body).attributes.finishDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-06-01').ToString('yyyy-MM-ddThh:mm:ssZ')
            } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}*" -f [uri]::EscapeDataString('Iteration 7')) -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).id -eq 71 -and
                (ConvertFrom-Json $body).attributes.startDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-12').ToString('yyyy-MM-ddThh:mm:ssZ') -and
                (ConvertFrom-Json $body).attributes.finishDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-18').ToString('yyyy-MM-ddThh:mm:ssZ')
            } -Verifiable

            # Delete mocks
            # Auto-Deletes 3.1, 3.2 & 3.2.1 as they are childitems of deleted parents
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}*" -f [uri]::EscapeDataString('Iteration 3')) -and $method -eq 'DELETE' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}*" -f [uri]::EscapeDataString('Iteration 5')) -and $method -eq 'DELETE' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}/{1}*" -f [uri]::EscapeDataString('Iteration 6'), [uri]::EscapeDataString('Iteration 6.1')) -and $method -eq 'DELETE' } -Verifiable

            # # Create  mocks
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}*" -f [uri]::EscapeDataString('Iteration 4')) -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).name -eq 'Iteration 4.1' -and
                (ConvertFrom-Json $body).attributes.startDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-04').ToString('yyyy-MM-ddThh:mm:ssZ') -and
                (ConvertFrom-Json $body).attributes.finishDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-11').ToString('yyyy-MM-ddThh:mm:ssZ')
            } -MockWith { return @{ name = 'Iteration 4.1' } } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}*" -f [uri]::EscapeDataString('Iteration 4')) -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).name -eq 'Iteration 4.2' -and
                (ConvertFrom-Json $body).attributes.startDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-12').ToString('yyyy-MM-ddThh:mm:ssZ') -and
                (ConvertFrom-Json $body).attributes.finishDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-18').ToString('yyyy-MM-ddThh:mm:ssZ')
            } -MockWith { return @{ name = 'Iteration 4.2' } } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Iterations/{0}*" -f [uri]::EscapeDataString('Iteration 4')) -and
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).name -eq 'Iteration 4.2.1' -and
                (ConvertFrom-Json $body).attributes.startDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-04').ToString('yyyy-MM-ddThh:mm:ssZ') -and
                (ConvertFrom-Json $body).attributes.finishDate.ToString('yyyy-MM-ddThh:mm:ssZ') -eq ([DateTime]'2021-01-11').ToString('yyyy-MM-ddThh:mm:ssZ')
            } -MockWith { return @{ name = 'Iteration 4.2.1' } } -Verifiable

            # Non intended invocation
            Mock Out-File -MockWith { throw "This invocation in 'Invoke-RESTCommand' should never be reached" }

            $inputObject = @{
                localIterations   = $localProjectData.IterationPaths
                Organization      = $localProjectData.OrganizationName
                Project           = $localProjectData.ProjectName
                removeExcessItems = $true
                DryRun            = $false
            }
            { Sync-ProjectIterationList @inputObject } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}