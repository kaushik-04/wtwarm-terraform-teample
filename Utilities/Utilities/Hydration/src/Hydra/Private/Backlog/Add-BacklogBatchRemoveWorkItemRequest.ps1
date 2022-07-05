<#
.SYNOPSIS
Add a correctly formatted batch item to remove a work item to the stack of commands

.DESCRIPTION
Add a correctly formatted batch item to remove a work item to the stack of commands
The function automatically flushes the commands if certain requirements demand it.

.PARAMETER boardCommandList
Mandatory. The command arraylist to store the formatted items in

.PARAMETER remoteBacklogData
Optional. The remote backlog data. Must be provided if removing existing work items

.PARAMETER itemToProcess
Mandatory. An object containing all data required to craft the specific request. Differs depending on the operation & target

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER total
Optional. The a 'total' number of requests to show next to the 'flush' output. E.g. if executing a total of 100 items and it is flushed after 25, one would get [25/100] shown as an output

.EXAMPLE
Add-BacklogBatchRequest -itemToProcess @{ id = 1 } -organization 'contoso' -boardCommandList $boardCommandList

Generate a command to remove the work item with id 1 from organization [contoso]
#>
function Add-BacklogBatchRemoveWorkItemRequest {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList] $boardCommandList,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $itemToProcess,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [int] $total
    )

    # Add 'Remove item'
    $itemRemoveRestInfo = Get-RelativeConfigData -configToken 'RESTBoardWorkItemRemove'
    $null = $boardCommandList.Add(
        @{
            request = @{
                method = $itemRemoveRestInfo.method
                uri    = $itemRemoveRestInfo.uri -f $itemToProcess.Id
            }
        }
    )

# Add 'Remove item from bin'
$itemRemoveRestInfo = Get-RelativeConfigData -configToken 'RESTBoardWorkItemRecycleBinRemove'
    $null = $boardCommandList.Add(
        @{
            request = @{
                method = $itemRemoveRestInfo.method
                uri    = $itemRemoveRestInfo.uri -f $itemToProcess.Id
            }
        }
    )

    $apiCapacity = Get-RelativeConfigData -configToken 'BoardBatchCapacity'
    if ($boardCommandList.Count -eq $apiCapacity) {
        Write-Verbose ("Remove Item: Execute [{0}|$total] requests. Flush at item [{1}] due to concurrent update limit [$apiCapacity]." -f $boardCommandList.Count, $itemToProcess.id)
        Clear-BacklogItemCommandBatch -boardCommandList $boardCommandList -Organization $Organization
    }
}