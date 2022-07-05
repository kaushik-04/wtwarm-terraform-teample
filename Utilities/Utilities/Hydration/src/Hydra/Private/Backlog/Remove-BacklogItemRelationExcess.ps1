<#
.SYNOPSIS
Remove any excess relation from the remote organization

.DESCRIPTION
Remove any excess relation from the remote organization

.PARAMETER relationsToRemove
Mandatory. The array of relations to remove.

.PARAMETER remoteBacklogData
Mandatory. An array of work item that exist in the target organization

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Remove-BacklogItemRelationExcess -relationsToRemove @(@{ sourceItem = @{ id = 1 }; targetItem = @{ id = 2 }; relationType = 'Related' }) -Organization 'contoso'

Remove the relation '1 -> Related To -> 2' from the organization 'conntoso'
#>
function Remove-BacklogItemRelationExcess {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $relationsToRemove,

        [Parameter(Mandatory = $false)]
        [PSCustomObject[]] $remoteBacklogData,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    # Remove excess relations
    $ProcessingStartTime = Get-Date

    $boardCommandList = [System.Collections.ArrayList]@()

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($relationToRemove in $relationsToRemove) {

        if ($DryRun) {
            $null = $dryRunActions.Add(
                [PSCustomObject]@{
                    op            = '-'
                    'Child Id'    = $relationToRemove.sourceItem.Id
                    'Child Type'  = $relationToRemove.sourceItem.fields.'System.WorkItemType'
                    'Child Name'  = $relationToRemove.sourceItem.fields.'System.Title'
                    'Parent Id'   = $relationToRemove.targetItem.Id
                    'Parent Type' = $relationToRemove.targetItem.fields.'System.WorkItemType'
                    'Parent Name' = $relationToRemove.targetItem.fields.'System.Title'
                }
            )
        }
        else {
            $addItemInputObject = @{
                boardCommandList  = $boardCommandList
                itemToProcess     = $relationToRemove
                remoteBacklogData = $remoteBacklogData
                Organization      = $Organization
                total             = $relationsToRemove.Count
            }
            if ($PSCmdlet.ShouldProcess(("Batch request 'remote relation [Source:[Id:{0}|Type:{1}|Title:{2}]=>{3}=>Target:[Id:{4}|Type:{5}|Title:{6}]]'" -f $relationToRemove.sourceItem.Id, $relationToRemove.sourceItem.'Work Item Type', $relationToRemove.sourceItem.title, $relationToRemove.relation, $relationToRemove.targetItem.Id, $relationToRemove.targetItem.'Work Item Type', $relationToRemove.targetItem.title), "Add")) {
                Add-BacklogBatchRemoveRelationRequest @addItemInputObject
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould remove hierarchy relations:"
        $dryRunString += "`n=================================="
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }

    # Flush remaining commands
    if ($boardCommandList.count -gt 0) {
        Clear-BacklogItemCommandBatch -boardCommandList $boardCommandList -Organization $Organization
    }

    $elapsedTime = (get-date) - $ProcessingStartTime
    $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
    Write-Verbose ("Excess BacklogItem removal took [{0}]" -f $totalTime)
}