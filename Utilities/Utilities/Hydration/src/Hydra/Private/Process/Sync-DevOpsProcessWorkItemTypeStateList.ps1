<#
.SYNOPSIS
Sync work-item-type-level states based on the given configuration

.DESCRIPTION
Sync work-item-type-level states based on the given configuration

.PARAMETER localWorkItemTypeStates
Mandatory. The work item type states to create

.PARAMETER workItemTypeReferenceName
Mandatory. The internal work item type reference to sync the states in. E.g.
- CustomAgileProcess.CustomChangeRequest (<processname>.<typename> without whitespaces)
- CustomAgileProcess.de81222d-b7be-4a27-9498-53d1b55d08dd (<processname>.<guid> without whitespaces)

.PARAMETER remoteProcess
Mandatory. The process to create the work item type states in

.PARAMETER Organization
Mandatory. The organization to sync the items in

.PARAMETER removeExcessItems
Optional. Control whether or not remove items that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-DevOpsProcessWorkItemTypeStateList -Organization 'contoso' -remoteProcess @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' }  -workItemTypeReferenceName 'Custom.de81222d-b7be-4a27-9498-53d1b55d08dd' -localWorkItemTypeStates @( @{ name = "New"; color = 'eeeeee' })

Sync the state 'New' for the work item type with internal reference 'Custom.de81222d-b7be-4a27-9498-53d1b55d08dd' in process [contoso|myProcess]
#>
function Sync-DevOpsProcessWorkItemTypeStateList {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localWorkItemTypeStates,

        [Parameter(Mandatory = $true)]
        [string] $workItemTypeReferenceName,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteProcess,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )


    $remoteWorkItemTypeStates = Get-DevOpsProcessWorkItemTypeStateList -Organization $Organization -processId $remoteProcess.Id -workItemTypeReferenceName $workItemTypeReferenceName

    ####################################
    #   Create Work Item Type States   #
    ####################################
    if ($workItemsTypeStatesToCreate = $localWorkItemTypeStates | Where-Object { $_.name -notin $remoteWorkItemTypeStates.name }) {
        $newWorkItemTypeInputObject = @{
            Organization               = $Organization
            processId                  = $remoteProcess.Id
            workItemTypeReferenceName  = $workItemTypeReferenceName
            workItemTypeStatesToCreate = $workItemsTypeStatesToCreate
            DryRun                     = $DryRun
        }
        if ($PSCmdlet.ShouldProcess(("Creation of [{0}] states for work item type [{1}|{2}]" -f $workItemsTypeStatesToCreate.Count, $remoteProcess.Name, $localWorkItemType.Name), "Initiate")) {
            New-DevOpsProcessWorkItemTypeStateRange @newWorkItemTypeInputObject
        }
    }
    else {
        Write-Verbose ("No states to create for work item type [{0}|{1}]" -f $remoteProcess.Name, $localWorkItemType.Name)
    }

    ####################################
    #   Remove Work Item Type States   #
    ####################################
    if ($removeExcessItems) {
        if ($workItemsTypeStatesToRemove = $remoteWorkItemTypeStates | Where-Object { $_.name -notin $localWorkItemTypeStates.name }) {

            $removeWorkItemTypeStateInputObject = @{
                Organization               = $Organization
                process                    = $remoteProcess
                workItemTypeReferenceName  = $workItemTypeReferenceName
                workItemTypeStatesToRemove = $workItemsTypeStatesToRemove
                DryRun                     = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("[{0}] states from work item type [{1}|{2}]" -f $workItemsTypeStatesToRemove.Count, $remoteProcess.Name, $localWorkItemType.Name), "Remove")) {
                Remove-DevOpsProcessWorkItemTypeStateRange @removeWorkItemTypeStateInputObject
            }
        }
        else {
            Write-Verbose ("No states to remove from work item type [{0}|{1}]" -f $remoteProcess.Name, $localWorkItemType.Name)
        }
    }

    ####################################
    #   Update Work Item Type States   #
    ####################################
    $statesToUpdate = [System.Collections.ArrayList]@()
    foreach ($remoteWorkItemTypeState in $remoteWorkItemTypeStates) {
        if ($matchingLocal = $localWorkItemTypeStates | Where-Object { $_.Name -eq $remoteWorkItemTypeState.Name }) {
            if ($propertiesToUpdate = Get-DevOpsProcessWorkItemTypeStatePropertiesToUpdate -localState $matchingLocal -remoteState $remoteWorkItemTypeState) {
                $updateObject = @{
                    id   = $remoteWorkItemTypeState.id
                    name = $remoteWorkItemTypeState.name
                }
                foreach ($propertyToUpdate in $propertiesToUpdate) {
                    $updateObject[$propertyToUpdate] = $matchingLocal.$propertyToUpdate
                    $updateObject["Old $propertyToUpdate"] = $remoteWorkItemTypeState.$propertyToUpdate
                }
                $null = $statesToUpdate.Add([PSCustomObject]$updateObject)
            }
        }
    }

    if ($statesToUpdate.Count -gt 0) {
        $setStatesInputObject = @{
            Organization              = $Organization
            statesToUpdate            = $statesToUpdate
            process                   = $remoteProcess
            workItemTypeReferenceName = $workItemTypeReferenceName
            DryRun                    = $DryRun
        }
        if ($PSCmdlet.ShouldProcess(("Update of [{0}] states in work item type [{1}|{2}]" -f $statesToUpdate.Count, $remoteProcess.Name, $remoteWorkItemType.Name), "Initiate")) {
            Set-DevOpsProcessWorkItemTypeStateRange @setStatesInputObject
        }
    }
    else {
        Write-Verbose "No work item type states to update"
    }

}