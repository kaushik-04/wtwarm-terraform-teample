<#
.SYNOPSIS
Remove any excess items from the given organization

.DESCRIPTION
Removed any provided excess remote work item

.PARAMETER excessItems
Mandatory. An array of remote works item to remove

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Remove-BacklogItemExcess -excessItems @(@{ id = 3}) -Organization 'contoso'

Remove item '3' from the target organization 'contoso'
#>
function Remove-BacklogItemExcess {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $excessItems,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    $ProcessingStartTime = Get-Date

    $boardCommandList = [System.Collections.ArrayList]@()
    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($excessItem in $excessItems) {
        if ($DryRun) {
            $null = $dryRunActions.Add(
                [PSCustomObject]@{
                    op    = '-'
                    id    = $excessItem.Id
                    type  = $excessItem.fields.'System.WorkItemType'
                    title = $excessItem.fields.'System.Title'
                }
            )
        }
        else {
            $addItemInputObject = @{
                boardCommandList = $boardCommandList
                itemToProcess    = @{ id = $excessItem.id }
                Organization     = $Organization
                total            = $excessItems.Count
            }
            if ($PSCmdlet.ShouldProcess(("Batch request '{0} {1} [Id:{2}|Type:{3}|Title:{4}]'" -f $addItemInputObject.Operation, $addItemInputObject.target, $excessItem.Id, $excessItem.fields.'System.WorkItemType', $excessItem.fields.'System.Title'), "Add")) {
                Add-BacklogBatchRemoveWorkItemRequest @addItemInputObject
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould remove work items:"
        $dryRunString += "`n========================"
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