<#
.SYNOPSIS
Sync process-level work item types based on the given configuration

.DESCRIPTION
Sync process-level work item types based on the given configuration

.PARAMETER localWorkItemTypes
Mandatory. The work item types to create

.PARAMETER remoteProcess
Mandatory. The process to create the work item types in

.PARAMETER Organization
Mandatory. The organization to sync the items in

.PARAMETER removeExcessItems
Optional. Control whether or not remove items that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-DevOpsProcessWorkItemTypeList -Organization 'contoso' -remoteProcess @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' } -localWorkItemTypes @(@{ name = "Component"; description = "New description" })

Create the work item type 'Component' in process [contoso|myProcess]
#>
function Sync-DevOpsProcessWorkItemTypeList {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localWorkItemTypes,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteProcess,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    # Fetch remote data
    $remoteWorkItemTypes = Get-DevOpsProcessWorkItemTypeList -Organization $Organization -processId $remoteProcess.Id
    $remoteBacklogLevels = Get-DevOpsProcessBacklogLevelList -Organization $Organization -processId $remoteProcess.Id

    ##############################
    #   Create Work Item Types   #
    ##############################
    if ($workItemsTypesToCreate = $localWorkItemTypes | Where-Object { $_.name -notin $remoteWorkItemTypes.name }) {
        $newWorkItemTypeInputObject = @{
            Organization          = $Organization
            process               = $remoteProcess
            workitemtypesToCreate = $workItemsTypesToCreate
            remoteBacklogLevels   = $remoteBacklogLevels
            DryRun                = $DryRun
        }
        if ($PSCmdlet.ShouldProcess(("Creation of [{0}] work item types in process [{1}]" -f $workItemsTypesToCreate.Count, $remoteProcess.Name), "Initiate")) {
            New-DevOpsProcessWorkItemTypeRange @newWorkItemTypeInputObject
        }
    }
    else {
        Write-Verbose ("No work item types to create for process [{0}]" -f $remoteProcess.Name)
    }

    ##############################
    #   Remove Work Item Types   #
    ##############################
    if ($removeExcessItems) {
        if ($workItemsTypesToRemove = $remoteWorkItemTypes | Where-Object { $_.customization -ne 'system' -and $_.name -notin $localWorkItemTypes.name }) {

            $removeWorkItemTypeInputObject = @{
                Organization          = $Organization
                process               = $remoteProcess
                workItemTypesToRemove = $workItemsTypesToRemove
                DryRun                = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("[{0}] work item types from organization process [{1}]" -f $workItemsTypesToRemove.Count, $remoteProcess.Name), "Remove")) {
                Remove-DevOpsProcessWorkItemTypeRange @removeWorkItemTypeInputObject
            }
        }
        else {
            Write-Verbose ("No work item types to remove from process [{0}]" -f $remoteProcess.Name)
        }
    }

    ##############################
    #   Update Work Item Types   #
    ##############################
    $workItemTypesToUpdate = [System.Collections.ArrayList]@()
    foreach ($remoteWorkItemType in $remoteWorkItemTypes) {
        if ($matchingLocal = $localWorkItemTypes | Where-Object { $_.Name -eq $remoteWorkItemType.Name }) {
            if ($propertiesToUpdate = Get-DevOpsProcessWorkItemTypePropertiesToUpdate -localWorkItemType $matchingLocal -remoteWorkItemType $remoteWorkItemType) {
                $updateObject = @{
                    referenceName = $remoteWorkItemType.referenceName
                    name          = $remoteWorkItemType.name
                }
                foreach ($propertyToUpdate in $propertiesToUpdate) {
                    $updateObject[$propertyToUpdate] = $matchingLocal.$propertyToUpdate
                    $updateObject["Old $propertyToUpdate"] = $remoteWorkItemType.$propertyToUpdate
                }

                if ($matchingLocal.behavior) {
                    $behaviorRef = $remoteBacklogLevels | Where-Object { $_.Name -eq $matchingLocal.behavior.assignedBacklogLevel }

                    $currentBehaviorInputObject = @{
                        Organization              = $Organization
                        Process                   = $remoteProcess
                        workItemTypeReferenceName = $remoteWorkItemType.referenceName
                    }
                    $remoteBehavior = Get-DevOpsProcessWorkItemTypeBehaviorList @currentBehaviorInputObject

                    $assignedBehaviorMatch = $behaviorRef.referenceName -eq $remoteBehavior.behavior.id
                    $assignedBehaviorDefaultMatch = (($matchingLocal.behavior | Get-Member -MemberType 'NoteProperty').Name -contains 'isDefault') -and ($matchingLocal.behavior.isDefault -eq $remoteBehavior.isDefault)
                    if (-not $assignedBehaviorMatch -or -not $assignedBehaviorDefaultMatch) {

                        $updateObject['AssignedBacklogLevel Ref'] = $behaviorRef.referenceName

                        if (-not $assignedBehaviorMatch) {
                            # If current & configured behaviors don't match we need to update
                            $updateObject['AssignedBacklogLevel'] = $matchingLocal.behavior.assignedBacklogLevel
                            $updateObject["Old AssignedBacklogLevel"] = $remoteBehavior.behavior.id
                        }

                        if (-not $assignedBehaviorDefaultMatch) {
                            # If we configured 'isDefault' & it does not match the remote configuration we need to updat
                            $updateObject['isDefault'] = $matchingLocal.behavior.isDefault
                            $updateObject["Old isDefault"] = $remoteBehavior.isDefault
                        }
                    }
                }

                $null = $workItemTypesToUpdate.Add([PSCustomObject]$updateObject)
            }
        }
    }

    if ($workItemTypesToUpdate.Count -gt 0) {
        $setWorkItemTypesInputObject = @{
            Organization          = $Organization
            workItemTypesToUpdate = $workItemTypesToUpdate
            process               = $remoteProcess
            DryRun                = $DryRun
        }
        if ($PSCmdlet.ShouldProcess(("Update of [{0}] work item types in process [{1}]" -f $workItemTypesToUpdate.Count, $remoteProcess.Name), "Initiate")) {
            Set-DevOpsProcessWorkItemTypeRange @setWorkItemTypesInputObject
        }
    }
    else {
        Write-Verbose "No work item types to update"
    }
}