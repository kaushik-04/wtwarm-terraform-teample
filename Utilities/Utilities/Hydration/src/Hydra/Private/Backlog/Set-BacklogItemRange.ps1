<#
.SYNOPSIS
Update all backlog items of the given local data set

.DESCRIPTION
Update all backlog items of the given local data set

.PARAMETER workItemsToUpdate
Mandatory. The local backlog data to update the remote backlog with

.PARAMETER Organization
Mandatory. The organization to update the items in. E.g. 'contoso'

.PARAMETER DryRun
Simulate an end2end execution

.EXAMPLE
Set-BacklogItemRange -workItemsToUpdate @(@{ id = 1; 'Work Item Type' = 'Epic'; Title = 'Item 1'; gen_relationString = 'Epic=Item 1'; GEN_PropertiesToUpdate = @('title')}; @{ ID = 2; 'Work Item Type' = 'Epic'; Title = 'Item 2'; gen_relationString = 'Epic=Item 2'; GEN_PropertiesToUpdate = @('Work Item Type')}}) -Organization 'contoso'

Update the provided work items in organization [contoso]. The first is updated due to a change in title, the second due to a change in its type.
#>
function Set-BacklogItemRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $workItemsToUpdate,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    $ProcessingStartTime = Get-Date

    # REST collection
    $boardCommandList = [System.Collections.ArrayList]@()

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($workItemToUpdate in $workItemsToUpdate) {

        if ($workItemToUpdate.'GEN_PropertiesToUpdate') {

            if ($DryRun) {
                $dryAction = @{
                    Op = '^'
                    Id = $workItemToUpdate.Id
                }

                foreach ($propertyToUpdate in $workItemToUpdate.'GEN_PropertiesToUpdate') {
                    $remotePropertyName = Get-BacklogPropertyCounterpart -localPropertyName $propertyToUpdate

                    if ($propertyToUpdate -like "*Date*") {
                        $oldValue = ($matchingRemote.fields.$remotePropertyName) ? ([DateTime]$matchingRemote.fields.$remotePropertyName).ToString('yyyy-MM-dd') : '()'
                        $newValue = ([DateTime]$workItemToUpdate.$propertyToUpdate).ToString('yyyy-MM-dd')
                    }
                    else {
                        $oldValue = ($matchingRemote.fields.$remotePropertyName) ? $matchingRemote.fields.$remotePropertyName : '()'
                        $newValue = $workItemToUpdate.$propertyToUpdate
                    }
                    $dryAction[$propertyToUpdate] = "[$oldValue => $newValue]"
                }
                $null = $dryRunActions.Add($dryAction)
            }
            else {
                $addItemInputObject = @{
                    boardCommandList = $boardCommandList
                    itemToProcess    = $workItemToUpdate
                    Organization     = $Organization
                    total            = $workItemsToUpdate.Count
                }
                if ($PSCmdlet.ShouldProcess(("Batch request 'update workitem [Id:{0}|Type:{1}|Title:{2}]'" -f $workItemToUpdate.Id, $workItemToUpdate.'Work Item Type', $workItemToUpdate.title), "Add")) {
                    Add-BacklogBatchUpdateWorkItemRequest @addItemInputObject
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould update work items:"
        $dryRunString += "`n========================"

        $columns = @('#', 'Op', 'Id') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op','Id')})
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }

    # Flush remaining commands
    if ($boardCommandList.count -gt 0) {
        Clear-BacklogItemCommandBatch -boardCommandList $boardCommandList -Organization $Organization
    }

    $elapsedTime = (get-date) - $ProcessingStartTime
    $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
    Write-Verbose ("BacklogItem update took [{0}]" -f $totalTime)
}