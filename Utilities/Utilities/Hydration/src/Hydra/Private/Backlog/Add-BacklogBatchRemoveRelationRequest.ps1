<#
.SYNOPSIS
Add a correctly formatted batch item to remove a relation to the stack of commands

.DESCRIPTION
Add a correctly formatted batch item to remove a relation to the stack of commands
The function automatically flushes the commands if certain requirements demand it.

.PARAMETER boardCommandList
Mandatory. The command arraylist to store the formatted items in

.PARAMETER remoteBacklogData
Optional. The remote backlog data. Must be provided if removing existing relations

.PARAMETER itemToProcess
Mandatory. An object containing all data required to craft the specific request. Differs depending on the operation & target

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER total
Optional. The a 'total' number of requests to show next to the 'flush' output. E.g. if executing a total of 100 items and it is flushed after 25, one would get [25/100] shown as an output

.EXAMPLE
Add-BacklogBatchRequest -itemToProcess @{ SourceItem = @{ Id = 1; title = 'Item 1' }; TargetItem = @{ Id = 2; title = 'Item 2 } } -organization 'contoso' -remoteBacklogData $remoteBacklogData

Generate a command to remove the relationship [Item 1 -> Child Of -> Item 2] from organization [contoso]
#>
function Add-BacklogBatchRemoveRelationRequest {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList] $boardCommandList,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $remoteBacklogData,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $itemToProcess,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [int] $total
    )

    $sourceItemRelations = [Collections.Generic.List[Object]]($remoteBacklogData | Where-Object { $_.Id -eq $itemToProcess.sourceItem.Id }).relations
    $relationIndex = $sourceItemRelations.FindIndex( { $args[0].url.EndsWith(('/{0}' -f $itemToProcess.targetItem.Id)) })

    $restInfo = Get-RelativeConfigData -configToken 'RESTBoardWorkItemUpdate'
    $requestItem = @{
        method  = $restInfo.method
        uri     = $restInfo.uri -f $itemToProcess.SourceItem.Id
        headers = @{
            "Content-Type" = Get-RelativeConfigData -configToken 'PATCH_ContentType'
        }
        body    = @(
            @{
                op   = 'remove'
                path = "/relations/$relationIndex"
            }
        )
    }

    # Add item
    $null = $boardCommandList.Add(
        @{
            request = $requestItem
        }
    )

    $apiCapacity = Get-RelativeConfigData -configToken 'BoardBatchCapacity'
    if ($boardCommandList.Count -eq $apiCapacity) {
        Write-Verbose ("Remove Relation: Execute [{0}|$total] requests. Flush at item [{1}|Child|{2}] due to concurrent update limit [$apiCapacity]." -f $boardCommandList.Count, $itemToProcess.SourceItem.title, $itemToProcess.TargetItem.title)
        Clear-BacklogItemCommandBatch -boardCommandList $boardCommandList -Organization $Organization
    }
}