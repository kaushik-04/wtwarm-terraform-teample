# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f  (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

Describe "[Backlog] Test Hierarchical Board Hydration [csv]" -Tag Build {

    <#
        Simulated Scenario:
        ===================
        Expected:
        ---------
            ID Work Item Type Title 1  Title 2     Title 3        Title 4 State
            -- -------------- -------  -------     -------        ------- -----
            100 Epic           Epic 100                                    New
            110 Feature                 Feature 110                        New
            120 Feature                 Feature 120                        New
            130 Feature                 Feature 130                        New
            131 User Story                          User Story 131         Active
            1312 Task                                               Task 1  New
            1311 Task                                               Task 2  New
            140 Feature                 Feature 140                        New
            150 Feature                 Feature 150                        New
            151 User Story                          User Story 151         Active
            1511 Task                                               Task 1  New
            1512 Task                                               Task 2  New
            200 Epic           Epic 200                                    New
            210 Feature                 Feature 210                        New
            220 Feature                 Feature 220                        New
            230 Feature                 Feature 230                        New
            231 User Story                          User Story 231         Active
            240 Feature                 Feature 240                        New

        Actual:
        -------
            ID Work Item Type Title 1  Title 2     Title 3        Title 4 State
            -- -------------- -------  -------     -------        ------- -----
            100 Epic           Epic 100                                    New
            110 Feature                 Feature 110                        New
            120 Feature                 Feature 120                        New
            130 Feature                 Feature 130                        New
        x   151 User Story                          User Story 151         Active
        x   1511 Task                                               Task 1  New
        x   1512 Task                                               Task 2  New
        x   6001 User Story                         Remove 6001            New
        x   6002 User Story                         Remove 6002            New
            131 User Story                          User Story 131         Active
            1312 Task                                               Task 1  New
            1311 Task                                               Task 2  New
            140 Feature                 Feature 140                        New
            150 Feature                 Feature 150                        New
        x   230 Feature                 Feature 230                        New
        x   6003 User Story                         Remove 6003            New
        x   231 User Story                          User Story 231         Active
            200 Epic           Epic 200                                    New
            210 Feature                 Feature 210                        New
            220 Feature                 Feature 220                        New
            240 Feature                 Feature 240                        New

    #>

    InModuleScope $ModuleName {

        It "Should hydrate board without error" {

            # Load data
            $localBacklogDataPath = Join-Path $PSScriptRoot 'resources\SyncBoardBuildLocal.csv'
            $localBacklogData = Import-BacklogCompatibleCSV $localBacklogDataPath

            # Fetch Remote Data Mock - Returns different results for multiple invocations
            $script:GetBacklogItemsCreatedMockCalled = 0
            $getBacklogItemsCreatedScipt = {
                $script:GetBacklogItemsCreatedMockCalled++
                switch ($script:GetBacklogItemsCreatedMockCalled) {
                    1 {
                        # Initial state
                        return (Get-Content -Path (Join-Path $PSScriptRoot 'resources\SyncBoardBuildRemote1.json') -Raw | ConvertFrom-Json)
                    }
                    2 {
                        # State after missing board items are created
                        return (Get-Content -Path (Join-Path $PSScriptRoot 'resources\SyncBoardBuildRemote2.json') -Raw | ConvertFrom-Json)
                    }
                    3 {
                        # State after excess items are removed
                        return (Get-Content -Path (Join-Path $PSScriptRoot 'resources\SyncBoardBuildRemote3.json') -Raw | ConvertFrom-Json)
                    }
                    4 {
                        # State after excess relations are removed
                        return (Get-Content -Path (Join-Path $PSScriptRoot 'resources\SyncBoardBuildRemote4.json') -Raw | ConvertFrom-Json)
                    }
                }
            }

            Mock Get-BacklogItemsCreated -MockWith $getBacklogItemsCreatedScipt -ParameterFilter { $Project -eq 'Module Playground' -and $Organization -eq 'contoso' -and $expandCategory -eq 'Relations' } -Verifiable

            # Work Item Create Flush
            # ----------------------
            $1stCommandBatchScript = {
                $localBacklogData[9].Id = '15101'
                $localBacklogData[10].Id = '151101' # Assign ID to new elem Task 1
                $localBacklogData[11].Id = '151201' # Assign ID to new elem Task 2
                $localBacklogData[15].Id = '23001' # Assign ID to new elem User Story 230
                $localBacklogData[16].Id = '23101' # Assign ID to new elem User Story 231
                $boardCommandList.RemoveRange(0, $boardCommandList.Count)
            }
            $1stCommandBatchFilter = {
                $boardCommandList.count -eq 5 -and
                ($boardCommandList | Where-Object { $_.request.uri -eq '/Module%20Playground/_apis/wit/workitems/$Feature?api-version=6.0' -and $_.title -eq 'Feature 230' }) -and # Create
                ($boardCommandList | Where-Object { $_.request.uri -eq '/Module%20Playground/_apis/wit/workitems/$User Story?api-version=6.0' -and $_.title -eq 'User Story 151' }) -and # Create
                ($boardCommandList | Where-Object { $_.request.uri -eq '/Module%20Playground/_apis/wit/workitems/$User Story?api-version=6.0' -and $_.title -eq 'User Story 231' }) -and # Create
                ($boardCommandList | Where-Object { $_.request.uri -eq '/Module%20Playground/_apis/wit/workitems/$Task?api-version=6.0' -and $_.title -eq 'Task 1' }) -and # Create
                ($boardCommandList | Where-Object { $_.request.uri -eq '/Module%20Playground/_apis/wit/workitems/$Task?api-version=6.0' -and $_.title -eq 'Task 2' }) # Create
            }
            Mock Clear-BacklogItemCommandBatch -ParameterFilter $1stCommandBatchFilter -MockWith $1stCommandBatchScript -Verifiable

            # Relation Create Flush
            # ---------------------
            $2ndCommandBatchScript = {
                $boardCommandList.RemoveRange(0, $boardCommandList.Count)
            }
            $2ndCommandBatchFilter = {
                $boardCommandList.count -eq 5 -and
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/15101?api-version=6.0' -and $_.request.body.value.url.Split('/')[-1] -eq 150 -and $_.request.body.path -eq '/relations/-' }) -and # Create
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/151101?api-version=6.0' -and $_.request.body.value.url.Split('/')[-1] -eq 15101 -and $_.request.body.path -eq '/relations/-' }) -and # Create
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/151201?api-version=6.0' -and $_.request.body.value.url.Split('/')[-1] -eq 15101 -and $_.request.body.path -eq '/relations/-' }) -and # Create
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/23001?api-version=6.0' -and $_.request.body.value.url.Split('/')[-1] -eq 200 -and $_.request.body.path -eq '/relations/-' }) -and # Create
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/23101?api-version=6.0' -and $_.request.body.value.url.Split('/')[-1] -eq 23001 -and $_.request.body.path -eq '/relations/-' }) # Create
            }
            Mock Clear-BacklogItemCommandBatch -ParameterFilter $2ndCommandBatchFilter -MockWith $2ndCommandBatchScript -Verifiable

            # Work Item Remove Flush
            # ---------------------
            $3rdCommandBatchScript = {
                $boardCommandList.RemoveRange(0, $boardCommandList.Count)
            }
            $3rdCommandBatchFilter = {
                $boardCommandList.count -eq 16 -and
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/151?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/1511?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/1512?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/230?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/231?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/6001?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/6002?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/6003?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove

                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/recyclebin/151?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/recyclebin/1511?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/recyclebin/1512?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/recyclebin/230?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/recyclebin/231?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/recyclebin/6001?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/recyclebin/6002?api-version=6.0' -and $_.request.method -eq 'DELETE' }) -and # Remove
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/recyclebin/6003?api-version=6.0' -and $_.request.method -eq 'DELETE' }) # Remove
            }
            Mock Clear-BacklogItemCommandBatch -ParameterFilter $3rdCommandBatchFilter -MockWith $3rdCommandBatchScript

            ##############
            # EXECUTION #
            ##############
            $inputParameters = @{
                localBacklogData  = $localBacklogData
                Organization      = 'contoso'
                Project           = 'Module Playground'
                removeExcessItems = $true
                DryRun            = $false
            }
            Sync-Backlog @inputParameters

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}

Describe "[Backlog] Test Hierarchical Board Update By Id [csv]" -Tag Build {

    InModuleScope $ModuleName {

        It "Should re-hydrate board without error" {

            # Load data
            $localBacklogDataPath = Join-Path $PSScriptRoot 'resources\SyncBoardBuildUpdateByIdLocal.csv'
            $localBacklogData = Import-BacklogCompatibleCSV $localBacklogDataPath

            # Fetch Remote Data Mock - Returns different results for multiple invocations
            $script:GetBacklogItemsCreatedMockCalled = 0
            $getBacklogItemsCreatedScipt = {
                $script:GetBacklogItemsCreatedMockCalled++
                switch ($script:GetBacklogItemsCreatedMockCalled) {
                    1 {
                        # Initial state
                        return (Get-Content -Path (Join-Path $PSScriptRoot 'resources\SyncBoardBuildUpdateByIdRemote1.json') -Raw | ConvertFrom-Json)
                    }
                    2 {
                        # State after missing board items are created
                        return (Get-Content -Path (Join-Path $PSScriptRoot 'resources\SyncBoardBuildUpdateByIdRemote1.json') -Raw | ConvertFrom-Json)
                    }
                    3 {
                        # State after missing relations are created
                        return (Get-Content -Path (Join-Path $PSScriptRoot 'resources\SyncBoardBuildUpdateByIdRemote2.json') -Raw | ConvertFrom-Json)
                    }
                    4 {
                        # State after excess items are removed
                        return (Get-Content -Path (Join-Path $PSScriptRoot 'resources\SyncBoardBuildUpdateByIdRemote2.json') -Raw | ConvertFrom-Json)
                    }
                }
            }
            Mock Get-BacklogItemsCreated -MockWith $getBacklogItemsCreatedScipt -ParameterFilter { $Project -eq 'Module Playground' -and $Organization -eq 'contoso' -and $expandCategory -eq 'Relations' } -Verifiable

            # Work Item Create/Update Flush
            # -----------------------------
            $1stCommandBatchScript = {
                $boardCommandList.RemoveRange(0, $boardCommandList.Count)
            }
            $1stCommandBatchFilter = {
                $boardCommandList.count -eq 11 -and
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13456?api-version=6.0' -and $_.title -eq 'Epic 100 New' }) -and # Update
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13457?api-version=6.0' -and $_.title -eq 'Feature 110 New' }) -and # Update
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13458?api-version=6.0' -and $_.title -eq 'Feature 120 New' }) -and # Update
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13459?api-version=6.0' -and $_.title -eq 'Feature 130 New' }) -and # Update
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13460?api-version=6.0' -and $_.title -eq 'User Story 131 New' }) -and # Update
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13461?api-version=6.0' -and $_.title -eq 'Task 1 New' }) -and # Update
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13464?api-version=6.0' -and $_.title -eq 'Feature 150' }) -and # Update
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13468?api-version=6.0' -and $_.title -eq 'Epic 200' }) -and # Update
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13469?api-version=6.0' -and $_.title -eq 'Feature 210' }) -and # Update
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13470?api-version=6.0' -and $_.title -eq 'Feature 220' }) -and # Update
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13473?api-version=6.0' -and $_.title -eq 'Feature 240' }) # Update
            }
            Mock Clear-BacklogItemCommandBatch -ParameterFilter $1stCommandBatchFilter -MockWith $1stCommandBatchScript -Verifiable

            # Relation Create Flush
            # ---------------------
            $2ndCommandBatchScript = {
                $boardCommandList.RemoveRange(0, $boardCommandList.Count)
            }
            $2ndCommandBatchFilter = {
                $boardCommandList.count -eq 1 -and
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13471?api-version=6.0' -and $_.request.body.value.url.Split('/')[-1] -eq 13456 -and $_.request.body.path -eq '/relations/-' }) # Create
            }
            Mock Clear-BacklogItemCommandBatch -ParameterFilter $2ndCommandBatchFilter -MockWith $2ndCommandBatchScript -Verifiable

            # Work Item Remove Flush
            # ---------------------
            $3rdCommandBatchScript = {
                $boardCommandList.RemoveRange(0, $boardCommandList.Count)
            }
            $3rdCommandBatchFilter = {
                $boardCommandList.count -eq 1 -and
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/13471?api-version=6.0' -and $_.request.body.op -eq 'remove' -and $_.request.body.path -eq '/relations/1' }) # Remove
            }
            Mock Clear-BacklogItemCommandBatch -ParameterFilter $3rdCommandBatchFilter -MockWith $3rdCommandBatchScript

            #############
            # EXECUTION #
            #############
            $inputParameters = @{
                localBacklogData  = $localBacklogData
                Organization      = 'contoso'
                Project           = 'Module Playground'
                removeExcessItems = $true
                DryRun            = $false
            }
            Sync-Backlog @inputParameters

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}

Describe "[Backlog] Test Flat Board Update [csv]" -Tag Build {

    InModuleScope $ModuleName {

        It "Should hydrate board without error" {

            # Load data
            $localBacklogDataPath = Join-Path $PSScriptRoot 'resources\SyncBoardBuildUpdateFlatLocal.csv'
            $localBacklogData = Import-BacklogCompatibleCSV $localBacklogDataPath

            # Fetch Remote Data Mock - Returns different results for multiple invocations
            $script:GetBacklogItemsCreatedMockCalled = 0
            $getBacklogItemsCreatedScipt = {
                $script:GetBacklogItemsCreatedMockCalled++
                switch ($script:GetBacklogItemsCreatedMockCalled) {
                    1 {
                        # Initial state
                        return (Get-Content -Path (Join-Path $PSScriptRoot 'resources\SyncBoardBuildUpdateFlatRemote1.json') -Raw | ConvertFrom-Json)
                    }
                }
            }
            Mock Get-BacklogItemsCreated -MockWith $getBacklogItemsCreatedScipt -ParameterFilter { $Project -eq 'Module Playground' -and $Organization -eq 'contoso' -and $expandCategory -eq 'Relations' } -Verifiable

            # Work Item Create Flush
            # ----------------------
            $0stCommandBatchScript = {
                $boardCommandList.RemoveRange(0, $boardCommandList.Count)
            }
            $0stCommandBatchFilter = {
                $boardCommandList.count -eq 4 -and
                ($boardCommandList | Where-Object { $_.request.uri -eq '/Module%20Playground/_apis/wit/workitems/$Epic?api-version=6.0' -and $_.title -eq 'Epic 1' }) -and # Create
                ($boardCommandList | Where-Object { $_.request.uri -eq '/Module%20Playground/_apis/wit/workitems/$Epic?api-version=6.0' -and $_.title -eq 'Epic 2' }) -and # Create
                ($boardCommandList | Where-Object { $_.request.uri -eq '/Module%20Playground/_apis/wit/workitems/$Epic?api-version=6.0' -and $_.title -eq 'Epic 3' }) -and # Create
                ($boardCommandList | Where-Object { $_.request.uri -eq '/Module%20Playground/_apis/wit/workitems/$Feature?api-version=6.0' -and $_.title -eq 'Feature 1' }) # Create
            }
            Mock Clear-BacklogItemCommandBatch -ParameterFilter $0stCommandBatchFilter -MockWith $0stCommandBatchScript -Verifiable

            # Work Item Update Flush
            # ----------------------
            $1stCommandBatchScript = {
                $boardCommandList.RemoveRange(0, $boardCommandList.Count)
            }
            $1stCommandBatchFilter = {
                $boardCommandList.count -eq 1
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/100?api-version=6.0' -and $_.title -eq 'User Story 1' }) # Update
            }
            Mock Clear-BacklogItemCommandBatch -ParameterFilter $1stCommandBatchFilter -MockWith $1stCommandBatchScript -Verifiable

            # Work Item Remove Flush
            # ---------------------
            $2ndCommandBatchScript = {
                $boardCommandList.RemoveRange(0, $boardCommandList.Count)
            }
            $2ndCommandBatchFilter = {
                $boardCommandList.count -eq 1 -and
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/999?api-version=6.0' -and $_.request.method -eq 'DELETE' }) # Remove
            }
            Mock Clear-BacklogItemCommandBatch -ParameterFilter $2ndCommandBatchFilter -MockWith $2ndCommandBatchScript

            #############
            # EXECUTION #
            #############
            $inputParameters = @{
                localBacklogData  = $localBacklogData
                Organization      = 'contoso'
                Project           = 'Module Playground'
                removeExcessItems = $true
                DryRun            = $false
            }
            Sync-Backlog @inputParameters

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}
