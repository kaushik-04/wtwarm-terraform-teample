[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $path
)

Describe "[Process] Azure DevOps Process Specs" {

    $HydrationDefinitionObj = ConvertFrom-Json (Get-Content -Path $path -Raw)

    $initialExpectedNumberOfProcessesTestCase = @(
        @{
            configuredProcesses = $HydrationDefinitionObj.processes
            organizationName    = $HydrationDefinitionObj.organizationName
        }
    )
    It "Should have expected number of processes" -TestCases $initialExpectedNumberOfProcessesTestCase {

        param (
            [PSCustomObject[]] $configuredProcesses,
            [string] $organizationName
        )

        $remoteProcesses = Get-DevOpsProcessList -Organization $organizationName | Where-Object { $_.type -ne 'system' }

        $remoteProcesses.Count | Should -Be $configuredProcesses.Count
    }

    $testCases = @()
    foreach ($processObj in $HydrationDefinitionObj.processes) {
        $testCases += @{
            processObj       = $processObj
            organizationName = $HydrationDefinitionObj.organizationName
        }
    }

    It "Should have expected process [<organizationName>|<processObj.name>] deployed" -TestCases $testCases {

        param(
            [PSCustomObject] $processObj,
            [string] $organizationName
        )

        $global:processObj = $processObj
        $global:organizationName = $organizationName

        InModuleScope 'Hydra' {

            $remoteProcesses = Get-DevOpsProcessList -Organization $organizationName | Where-Object { $_.type -ne 'system' }

            $matchingRemoteProcess = $remoteProcesses | Where-Object {
                $_.Name -eq $processObj.Name -and
                (-not $processObj.Description -or ($processObj.Description -and $_.description -eq $processObj.Description))
            }
            $matchingRemoteProcess | Should -Not -BeNullOrEmpty

            $remoteBacklogLevels = Get-DevOpsProcessBacklogLevelList -Organization $organizationName -processId $matchingRemoteProcess.Id

            # Backlog Level
            if ($expectedBacklogLevels = $processObj.backlogLevels) {

                # test amount
                ($remoteBacklogLevels | Where-Object { $_.customization -eq 'custom' }).Count | Should -Be $expectedBacklogLevels.Count -Because ('the existing custom backlog level count for process [{0}] should equal the locally configured' -f $matchingRemoteProcess.name)

                # test content
                foreach ($expectedBacklogLevel in $expectedBacklogLevels) {
                    $matchingBacklogLevel = $remoteBacklogLevels | Where-Object { $_.Name -eq $expectedBacklogLevel.Name }
                    $matchingBacklogLevel | Should -Not -BeNullOrEmpty -Because ("The expected backlog level [{0}] should exist in the target process [{1}]" -f $expectedBacklogLevel.Name, $processObj.Name)
                }
            }

            # Work Item Types
            if ($expectedWorkItemTypes = $processObj.workitemtypes) {

                $remoteWorkItemTypes = Get-DevOpsProcessWorkItemTypeList -Organization $organizationName -processId $matchingRemoteProcess.Id

                # test amount
                ($remoteWorkItemTypes | Where-Object { $_.customization -eq 'custom' }).Count | Should -Be $expectedWorkItemTypes.Count -Because ('the existing custom work item type count for process [{0}] should equal the locally configured' -f $matchingRemoteProcess.Name)

                # test content
                foreach ($expectedWorkItemType in $expectedWorkItemTypes) {

                    $matchingWorkItemType = $remoteWorkItemTypes | Where-Object {
                        $_.Name -eq $expectedWorkItemType.Name -and
                        $_.color -eq $expectedWorkItemType.Color -and
                        $_.icon -eq $expectedWorkItemType.Icon
                    }
                    $matchingWorkItemType | Should -Not -BeNullOrEmpty

                    # Backlog Level Behavior
                    if ($expectedWorkItemType.behavior) {
                        $expectedBehaviorRef = $remoteBacklogLevels | Where-Object { $_.Name -eq $expectedWorkItemType.behavior.assignedBacklogLevel }

                        $currentBehaviorInputObject = @{
                            Organization              = $organizationName
                            Process                   = $matchingRemoteProcess
                            workItemTypeReferenceName = $matchingWorkItemType.referenceName
                        }
                        $remoteBehavior = Get-DevOpsProcessWorkItemTypeBehaviorList @currentBehaviorInputObject

                        if ($expectedWorkItemType.behavior.assignedBacklogLevel) {
                            $remoteBehavior.behavior.id | Should -Be $expectedBehaviorRef.referenceName
                        }

                        if ((($expectedWorkItemType.behavior | Get-Member -MemberType 'NoteProperty').Name -contains 'isDefault')) {
                            $remoteBehavior.isDefault | Should -Be $expectedWorkItemType.behavior.isDefault
                        }
                    }

                    # States
                    if ($expectedStates = $expectedWorkItemType.states) {

                        $remoteStates = Get-DevOpsProcessWorkItemTypeStateList -Organization $organizationName -processId $matchingRemoteProcess.Id -workItemTypeReferenceName $matchingWorkItemType.referenceName

                        # test amount
                        ($remoteStates | Where-Object { $_.customizationType -eq 'custom' }).Count | Should -Be $expectedStates.Count -Because ('the existing remote work item type [{0}] states count should equal the locally configured' -f $matchingWorkItemType.Name)

                        # test content
                        foreach ($expectedState in $expectedStates) {

                            $matchingRemote = $remoteStates | Where-Object {
                                $_.Name -eq $expectedState.Name -and
                                $_.color -eq $expectedState.Color -and
                                $_.stateCategory -eq $expectedState.StateCategory
                            }
                            $matchingRemote | Should -Not -BeNullOrEmpty
                        }
                    }
                }
            }
        }
    }
}