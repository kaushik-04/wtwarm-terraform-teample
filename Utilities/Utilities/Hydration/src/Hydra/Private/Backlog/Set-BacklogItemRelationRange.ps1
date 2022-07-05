<#
.SYNOPSIS
Create all relations in the given list or relations to set

.DESCRIPTION
Create all relations in the given list or relations to set

.PARAMETER relationsToSet
Mandatory. The array of relations to set

.PARAMETER localBacklogData
Optional. The local backlog data provided.

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Set-BacklogItemRelationRange -Organization 'contoso' -relationsToSet @(@{ relationtype = 'Child'; sourceItem = @{ id = 1}; targetItem = @{ id = 2 }})

Create the relation '1 -> Child Of -> 2' of the given 'relationsToSet' array in the organization 'contoso/Module Playground'
#>
function Set-BacklogItemRelationRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $relationsToSet,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    # Create/Update plain items
    $ProcessingStartTime = Get-Date

    $boardCommandList = [System.Collections.ArrayList]@()

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($relationToSet in $relationsToSet) {

        if ($DryRun) {
            $null = $dryRunActions.Add(
                [PSCustomObject]@{
                    op            = '+'
                    'Child Id'    = $relationToSet.sourceItem.Id
                    'Child Type'  = $relationToSet.sourceItem.'Work Item Type'
                    'Child Name'  = $relationToSet.sourceItem.title
                    'Parent Id'   = $relationToSet.targetItem.Id
                    'Parent Type' = $relationToSet.targetItem.'Work Item Type'
                    'Parent Name' = $relationToSet.targetItem.title
                }
            )
        }
        else {
            $addItemInputObject = @{
                boardCommandList = $boardCommandList
                itemToProcess    = $relationToSet
                Organization     = $Organization
                total            = $relationsToSet.Count
            }
            if ($PSCmdlet.ShouldProcess(("Batch request 'create relation [Source:[Id:{0}|Type:{1}|Title:{2}]=>{3}=>Target:[Id:{4}|Type:{5}|Title:{6}]]'" -f $relationToSet.sourceItem.Id, $relationToSet.sourceItem.'Work Item Type', $relationToSet.sourceItem.title, $relationToSet.relation, $relationToSet.targetItem.Id, $relationToSet.targetItem.'Work Item Type', $relationToSet.targetItem.title), "Add")) {
                Add-BacklogBatchCreateRelationRequest @addItemInputObject
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould add hierarchy relations:"
        $dryRunString += "`n==============================="
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
    Write-Verbose ("BacklogItem relation create/update took [{0}]" -f $totalTime)
}