<#
.SYNOPSIS
Sync organization-level processes based on the given configuration

.DESCRIPTION
Sync organization-level processes based on the given configuration. This includes work item types, states, backlog-levels & behavior assignment (i.e. level-assignments for backlog item types)
This includes all data points included like backlog levels, work item types, work item types & work item type behaviors

.PARAMETER localProcesses
Mandatory. The locally defined processes. E.g. @{ name = "Process 1"; parentProcess = "Agile" }

.PARAMETER Organization
Mandatory. The organization to sync the processes in

.PARAMETER removeExcessItems
Optional. Control whether or not remove items that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-DevOpsOrgProcessList -localProcesses @(@{ name = "Process 1"; parentProcess = "Agile" },@{ name = "Process 2"; parentProcess = "Agile" }) -organization 'contoso'

Create both processes 'Process 1' & 'Process 2' of type 'Agile' in organization 'contoso' if not existing already. If they exists the data may be updated.
#>
function Sync-DevOpsOrgProcessList {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localProcesses,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    $SyncProcessingStartTime = Get-Date

    ######################
    #   SYNC PROCESSES   #
    ######################
    $syncProcessesInputObject = @{
        localProcesses    = $localProcesses
        Organization      = $Organization
        removeExcessItems = $removeExcessItems
        DryRun            = $DryRun
    }
    if ($PSCmdlet.ShouldProcess(("[{0}] configured processes" -f $localProcesses.Count), "Sync")) {
        Sync-DevOpsProcessList @syncProcessesInputObject
        start-sleep 10 # Wait for propagation
    }


    # Refresh remote process data
    $remoteProcesses = Get-DevOpsProcessList -Organization $Organization

    foreach ($localProcess in $localProcesses) {

        $matchingRemoteProcess = $remoteProcesses | Where-Object { $_.name -eq $localProcess.Name }

        if (-not $matchingRemoteProcess) {
            if ($DryRun) {
                $matchingRemoteProcess = @{
                    id   = '0'
                    name = $localProcess.Name
                }
            }
            else {
                Write-Error ("Did not find matching remote process by name [{0}]" -f $localProcess.Name)
                continue
            }
        }

        ##############################
        #   PROCESS BACKLOG LEVELS   #
        ##############################
        if ($localProcess.backlogLevels) {
            $syncProcessBacklogLevelsInputObject = @{
                localBacklogLevels = $localProcess.backlogLevels
                remoteProcess      = $matchingRemoteProcess
                Organization       = $Organization
                removeExcessItems  = $removeExcessItems
                DryRun             = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("[{0}] configured backlog levels for process [{1}]" -f $localProcess.backlogLevels.Count, $localProcess.Name), "Sync")) {
                Sync-DevOpsProcessBacklogLevelList @syncProcessBacklogLevelsInputObject
            }
        }

        ###############################
        #   PROCESS WORK ITEM TYPES   #
        ###############################
        if ($localProcess.workitemtypes) {

            $syncProcessWorkItemTypesInputObject = @{
                localWorkItemTypes = $localProcess.workitemtypes
                remoteProcess      = $matchingRemoteProcess
                Organization       = $Organization
                removeExcessItems  = $removeExcessItems
                DryRun             = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("[{0}] configured work item types for process [{1}]" -f $localProcess.workitemtypes.Count, $localProcess.Name), "Sync")) {
                Sync-DevOpsProcessWorkItemTypeList @syncProcessWorkItemTypesInputObject
            }

            # Refresh work item type data
            $remoteWorkItemTypes = Get-DevOpsProcessWorkItemTypeList -Organization $Organization -processId $matchingRemoteProcess.Id

            foreach ($localWorkItemType in $localProcess.workitemtypes) {

                if ($localWorkItemType.states) {

                    $remoteWorkItemType = $remoteWorkItemTypes | Where-Object { $_.name -eq $localWorkItemType.Name }
                    if (-not $remoteWorkItemType -and $DryRun) {
                        $remoteWorkItemType = @{
                            id            = '0'
                            name          = $localWorkItemType.Name
                            referenceName = '{0}.{1}' -f $localProcesses.name, $localWorkItemType.Name
                        }
                    }

                    #####################################
                    #   PROCESS WORK ITEM TYPE STATES   #
                    #####################################
                    $syncProcessWorkItemTypeStatesInputObject = @{
                        localWorkItemTypeStates   = $localWorkItemType.states
                        workItemTypeReferenceName = $remoteWorkItemType.referenceName
                        remoteProcess             = $matchingRemoteProcess
                        Organization              = $Organization
                        removeExcessItems         = $removeExcessItems
                        DryRun                    = $DryRun
                    }
                    if ($PSCmdlet.ShouldProcess(("[{0}] configured work item type states for work item type [{1}|{2}]" -f $localWorkItemType.states.Count, $localProcess.Name, $localWorkItemType.Name), "Sync")) {
                        Sync-DevOpsProcessWorkItemTypeStateList @syncProcessWorkItemTypeStatesInputObject
                    }
                }
                else {
                    Write-Verbose ("No states for work item type [{0}|{1}] configured" -f $localProcess.Name, $localWorkItemType.Name)
                }
            }
        }
        else {
            Write-Verbose ("No work item types for process [{0}] configured" -f $localProcesses.Name)
        }
    }

    $elapsedTime = (get-date) - $SyncProcessingStartTime
    $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
    Write-Verbose ("DevOps process sync took [{0}]" -f $totalTime)
}