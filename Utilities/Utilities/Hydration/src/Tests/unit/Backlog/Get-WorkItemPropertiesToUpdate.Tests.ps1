# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

Describe "[Backlog] Should detect correct work item properties to update" -Tag Unit {

    InModuleScope $ModuleName {

        # Load data
        $remoteItemsPath = Join-Path $PSScriptRoot 'resources\GetWorkItemPropertiesToUpdateRemote.json'
        $remoteItems = ConvertFrom-Json (Get-Content -Path $remoteItemsPath -Raw)
        
        $localItemsPath = Join-Path $PSScriptRoot 'resources\GetWorkItemPropertiesToUpdateLocal.json'
        $localItems = ConvertFrom-Json (Get-Content -Path $localItemsPath -Raw) -Depth 10
        Resolve-BacklogLocalFormatted -localBacklogData $localItems

        $testCases = @()
        for ($lineIndex = 0; $lineIndex -lt $localItems.Count; $lineIndex++) {
            $testCases += @{
                localItem  = $localItems[$lineIndex]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[$lineIndex].Id } 
            }
        }
        
        $testCases = @(
            @{
                # ID: 5 - Bug 1 - Same
                localItem  = $localItems[0]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[0].Id } 
                expected   = @()
            }
            @{
                # ID: 5 - Bug 1 - Diff
                localItem  = $localItems[1]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[1].Id } 
                expected   = @(
                    'Activity',
                    'Area Path',
                    'Completed Work',
                    'Iteration Path',
                    'Original Estimate',
                    'Priority',
                    'Reason',
                    'Repro Steps',
                    'Resolved Reason',
                    'Severity',
                    'State',
                    'Story Points',
                    'System Info',
                    'Team Project',
                    'Title',
                    'Value Area',
                    'Work Item Type'
                )
            }
            @{
                # ID: 1 - Epic 1 - Same
                localItem  = $localItems[2]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[2].Id } 
                expected   = @()
            }
            @{
                # ID: 1 - Epic 1 - Diff
                localItem  = $localItems[3]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[3].Id } 
                expected   = @(
                    'Area Path',
                    'Business Value',
                    'Description',
                    'Effort',
                    'Iteration Path',
                    'Priority',
                    'Reason',
                    'Risk',
                    'Start Date',
                    'State',
                    'Target Date',
                    'Team Project',
                    'Time Criticality',
                    'Title',
                    'Value Area',
                    'Work Item Type'
                )
            }
            @{
                # ID: 2 - Feature 1 - Same
                localItem  = $localItems[4]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[4].Id } 
                expected   = @()
            }
            @{
                # ID: 2 - Feature 1 - Diff
                localItem  = $localItems[5]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[5].Id } 
                expected   = @(
                    'Area Path',
                    'Business Value',
                    'Description',
                    'Effort',
                    'Iteration Path',
                    'Priority',
                    'Reason',
                    'Risk',
                    'Start Date',
                    'State',
                    'Target Date',
                    'Team Project',
                    'Time Criticality',
                    'Title',
                    'Value Area',
                    'Work Item Type'
                )
            }
            @{
                # ID: 6 - Issue 1 - Same
                localItem  = $localItems[6]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[6].Id } 
                expected   = @()
            }
            @{
                # ID: 6 - Issue 1 - Diff
                localItem  = $localItems[7]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[7].Id } 
                expected   = @(
                    'Area Path',
                    'Due Date',
                    'Iteration Path',
                    'Priority',
                    'Reason',
                    'Stack Rank',
                    'State',
                    'Team Project',
                    'Title',
                    'Work Item Type'
                )
            }
            @{
                # ID: 3 - Task 1 - Same
                localItem  = $localItems[8]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[8].Id } 
                expected   = @()
            }
            @{
                # ID: 3 - Task 1 - Diff
                localItem  = $localItems[9]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[9].Id } 
                expected   = @(
                    'Activity',
                    'Area Path',
                    'Completed Work',
                    'Description',
                    'Iteration Path',
                    'Original Estimate',
                    'Priority',
                    'Reason',
                    'State',
                    'Team Project',
                    'Title',
                    'Work Item Type'
                )
            }
            @{
                # ID: 4 - User Story 5 - Same
                localItem  = $localItems[10]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[10].Id } 
                expected   = @()
            }
            @{
                # ID: 4 - User Story 5 - Diff
                localItem  = $localItems[11]
                remoteItem = $remoteItems | Where-Object { $_.Id -eq $localItems[11].Id } 
                expected   = @(
                    'Acceptance Criteria',
                    'Area Path',
                    'Description',
                    'Iteration Path',
                    'Priority',
                    'Reason',
                    'Risk',
                    'State',
                    'Story Points',
                    'Team Project',
                    'Title',
                    'Value Area',
                    'Work Item Type'
                )
            }
        )

        It "Should identify poperty diff [<localItem.Title>|<remoteItem.fields.'System.Title'>|#<expected.count>]" -TestCases $testCases {

            param (
                [PSCustomObject] $localItem,
                [PSCustomObject] $remoteItem,
                [string[]] $expected
            )

            $propertiesToUpdate = Get-WorkItemPropertiesToUpdate -localWorkItem $localItem -remoteWorkItem $remoteItem

            foreach ($expectedProperty in $expected) {
                $propertiesToUpdate | Should -Contain $expectedProperty
            }
            $propertiesToUpdate.Count | Should -Be $expected.Count
        }
    }
}
