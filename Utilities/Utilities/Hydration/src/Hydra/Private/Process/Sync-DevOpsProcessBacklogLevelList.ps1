<#
.SYNOPSIS
Sync process-level backlog levels based on the given configuration

.DESCRIPTION
Sync process-level backlog levels based on the given configuration

.PARAMETER localBacklogLevels
Mandatory. The backlog levels to create

.PARAMETER Organization
Mandatory. The organization to sync the items in

.PARAMETER remoteProcess
Mandatory. The process to create the backlog levels in

.PARAMETER removeExcessItems
Optional. Control whether or not remove items that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-DevOpsProcessBacklogLevelList -Organization 'contoso' -remoteProcess @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' } -localBacklogLevels @(@{ name = "Level1"; color = "f6546a" }, @{ name = "Level2"; color = "0366fc" })

Create both backlog levels 'Level1' & 'Level 2' in process [contoso|myProcess] if not existing already. If they exists the data may be updated.
#>
function Sync-DevOpsProcessBacklogLevelList {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localBacklogLevels,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteProcess,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    # Refresh remote backlog level data
    $remoteBacklogLevels = Get-DevOpsProcessBacklogLevelList -Organization $Organization -processId $remoteProcess.Id

    #############################
    #   Create Backlog Levels   #
    #############################
    if ($localBacklogLevelsToCreate = $localBacklogLevels | Where-Object { $_.name -notin $remoteBacklogLevels.name }) {
        $newBacklogLevelsInputObject = @{
            Organization          = $Organization
            process               = $remoteProcess
            backlogLevelsToCreate = $localBacklogLevelsToCreate
            DryRun                = $DryRun
        }
        if ($PSCmdlet.ShouldProcess(("Creation of [{0}] backlog levels in process [{1}]" -f $localBacklogLevelsToCreate.Count, $remoteProcess.Name), "Initiate")) {
            New-DevOpsProcessBacklogLevelRange @newBacklogLevelsInputObject
        }
    }
    else {
        Write-Verbose "No backlog levels to create"
    }

    #############################
    #   Remove Backlog Levels   #
    #############################
    if ($removeExcessItems) {
        if ($backlogLevelsToRemove = $remoteBacklogLevels | Where-Object { $_.customization -eq 'custom' -and $_.name -notin $localBacklogLevels.name }) {

            $removeBacklogLevelInputObject = @{
                Organization          = $Organization
                process               = $remoteProcess
                backlogLevelsToRemove = $backlogLevelsToRemove
                DryRun                = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("[{0}] backlog level from process [{1}]" -f $backlogLevelsToRemove.Count, $remoteProcess.Name), "Remove")) {
                Remove-DevOpsProcessBacklogLevelRange @removeBacklogLevelInputObject
            }
        }
        else {
            Write-Verbose "No backlog levels to remove"
        }
    }

    #############################
    #   Update Backlog Levels   #
    #############################
    $backlogLevelsToUpdate = [System.Collections.ArrayList]@()
    foreach ($remoteBacklogLevel in $remotebacklogLevels) {
        if ($matchingLocal = $localbacklogLevels | Where-Object { $_.Name -eq $remoteBacklogLevel.Name -and $remoteBacklogLevel.customization -eq 'custom' }) {
            if ($propertiesToUpdate = Get-DevOpsProcessBacklogLevelPropertiesToUpdate -localBacklogLevel $matchingLocal -remoteBacklogLevel $remoteBacklogLevel) {
                $updateObject = @{
                    id            = $remoteBacklogLevel.id
                    name          = $remoteBacklogLevel.name
                    referenceName = $remoteBacklogLevel.referenceName
                }
                foreach ($propertyToUpdate in $propertiesToUpdate) {
                    $updateObject[$propertyToUpdate] = $matchingLocal.$propertyToUpdate
                    $updateObject["Old $propertyToUpdate"] = $remoteBacklogLevel.$propertyToUpdate
                }
                $null = $backlogLevelsToUpdate.Add([PSCustomObject]$updateObject)
            }
        }
    }

    if ($backlogLevelsToUpdate.Count -gt 0) {
        $setbacklogLevelsInputObject = @{
            Organization          = $Organization
            backlogLevelsToUpdate = $backlogLevelsToUpdate
            process               = $remoteProcess
            DryRun                = $DryRun
        }
        if ($PSCmdlet.ShouldProcess(("Update of [{0}] backlog levels in process [{1}]" -f $backlogLevelsToUpdate.Count, $remoteProcess.Name), "Initiate")) {
            Set-DevOpsProcessBacklogLevelRange @setbacklogLevelsInputObject
        }
    }
    else {
        Write-Verbose "No backlog levels to update"
    }
}