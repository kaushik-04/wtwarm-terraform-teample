<#
.SYNOPSIS
Create all backlog items of the given local data set

.DESCRIPTION
Create all backlog items of the given local data set

.PARAMETER workItemsToCreate
Mandatory. The local backlog data to create the remote backlog with

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to create the items in. E.g. 'Module Playground'

.PARAMETER DryRun
Simulate an end2end execution

.EXAMPLE
New-BacklogItemRange -workItemsToCreate @(@{ id = 1; 'Work Item Type' = 'Epic'; Title = 'Item 1'; gen_relationString = 'Epic=Item 1'}; @{ ID = 2; 'Work Item Type' = 'Epic'; Title = 'Item 2'; gen_relationString = 'Epic=Item 2'}}) -Organization 'contoso' -project 'Module Playground'

Create the provided 3 work items in project [contoso|Module Playground]
#>
function New-BacklogItemRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $workItemsToCreate,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun,

        [Parameter(Mandatory = $true)]
        [string] $Project
    )

    $ProcessingStartTime = Get-Date

    # REST collection
    $boardCommandList = [System.Collections.ArrayList]@()

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($backlogItem in $workItemsToCreate) {

        ##############
        #   CREATE   #
        ##############
        if ($DryRun) {
            $null = $dryRunActions.Add(
                [PSCustomObject]@{
                    Op    = '+'
                    Type  = $backlogItem.'Work Item Type'
                    Title = $backlogItem.title
                }
            )
        }
        else {
            $addItemInputObject = @{
                boardCommandList = $boardCommandList
                itemToProcess    = $backlogItem
                localBacklogData = $workItemsToCreate
                Organization     = $Organization
                Project          = $Project
                total            = $workItemsToCreate.Count
            }
            if ($PSCmdlet.ShouldProcess(("Batch request 'create workitem [Type:{0}|Title:{1}]'" -f $backlogItem.'Work Item Type', $backlogItem.title), "Add")) {
                Add-BacklogBatchCreateWorkItemRequest @addItemInputObject
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould create work items:"
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
        Clear-BacklogItemCommandBatch -boardCommandList $boardCommandList -localBacklogData $localBacklogData -Organization $Organization
    }

    if ($DryRun) {
        # Assign pseudo-ids for further processing
        $fraudElementsToAdjust = ($localBacklogData | Where-Object { [String]::IsNullOrEmpty($_.'ID') })
        for ($index = 0; $index -lt $fraudElementsToAdjust.Count; $index++) {
            $pseudoId = "<Pseudo-$index>"
            Write-Debug ("NOTE: Assigning pseudo index [$pseudoId] to item [Type:{0}|Title:{1}] as its missing an Id for the dry run." -f $fraudElementsToAdjust[$index].'Work Item Type', $fraudElementsToAdjust[$index].Title)
            if (($fraudElementsToAdjust[$index] | Get-Member -MemberType "NoteProperty" ).Name -notcontains "Id") {
                $fraudElementsToAdjust[$index] | Add-Member -NotePropertyName 'Id' -NotePropertyValue ''
            }
            $fraudElementsToAdjust[$index].'Id' = $pseudoId
        }
    }

    $elapsedTime = (get-date) - $ProcessingStartTime
    $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
    Write-Verbose ("BacklogItem create took [{0}]" -f $totalTime)
}