<#
.SYNOPSIS
Sync organization-level processes based on the given configuration

.DESCRIPTION
Sync organization-level processes based on the given configuration.
This function only covers the top-level, i.e. the processes exluding their contained data points like backlog levels

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
function Sync-DevOpsProcessList {

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

    # Fetch remote data
    $remoteProcesses = Get-DevOpsProcessList -Organization $Organization

    ########################
    #   REMOVE PROCESSES   #
    ########################
    if ($removeExcessItems) {
        if ($processesToRemove = $remoteProcesses | Where-Object { $_.type -ne 'system' -and $_.name -notin $localProcesses.name }) {

            $removeProcessInputObject = @{
                Organization      = $Organization
                processesToRemove = $processesToRemove
                DryRun            = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("[{0}] processes from organization [{1}]" -f $processesToRemove.Count, $Organization), "Remove")) {
                Remove-DevOpsProcessRange @removeProcessInputObject
            }
        }
        else {
            Write-Verbose "No processes to remove"
        }
    }

    ########################
    #   CREATE PROCESSES   #
    ########################

    if ($processesToCreate = $localProcesses | Where-Object { $_.name -notin $remoteProcesses.name }) {
        $newProcessInputObject = @{
            Organization      = $Organization
            processesToCreate = $processesToCreate
            DryRun            = $DryRun
        }
        if ($PSCmdlet.ShouldProcess(("Creation of [{0}] processes in organization [{1}]" -f $processesToCreate.Count, $Organization), "Initiate")) {
            New-DevOpsProcessRange @newProcessInputObject
        }
    }
    else {
        Write-Verbose "No processes to create"
    }

    ########################
    #   UPDATE PROCESSES   #
    ########################

    $processesToUpdate = [System.Collections.ArrayList]@()
    foreach ($remoteProcess in $remoteProcesses) {
        if ($matchingLocal = $localProcesses | Where-Object { $_.Name -eq $remoteProcess.Name }) {
            if ($propertiesToUpdate = Get-DevOpsProcessPropertiesToUpdate -localProcess $matchingLocal -remoteProcess $remoteProcess) {
                $updateObject = @{
                    id   = $remoteProcess.id
                    name = $remoteProcess.name
                }
                foreach ($propertyToUpdate in $propertiesToUpdate) {
                    $updateObject[$propertyToUpdate] = $matchingLocal.$propertyToUpdate
                    $updateObject["Old $propertyToUpdate"] = $remoteProcess.$propertyToUpdate
                }
                $null = $processesToUpdate.Add([PSCustomObject]$updateObject)
            }
        }
    }

    if ($processesToUpdate.Count -gt 0) {
        $setProcessesInputObject = @{
            Organization      = $Organization
            processesToUpdate = $processesToUpdate
            DryRun            = $DryRun
        }
        if ($PSCmdlet.ShouldProcess(("Update of [{0}] processes in organization [{1}]" -f $processesToUpdate.Count, $Organization), "Initiate")) {
            Set-DevOpsProcessRange @setProcessesInputObject
        }
    }
    else {
        Write-Verbose "No processes to update"
    }
}