<#
.SYNOPSIS
Add a correctly formatted batch item for a relation creation to the stack of commands

.DESCRIPTION
Add a correctly formatted batch item for a relation creation to the stack of commands
The function automatically flushes the commands if certain requirements demand it.

.PARAMETER boardCommandList
Mandatory. The command arraylist to store the formatted items in

.PARAMETER itemToProcess
Mandatory. An object containing all data required to craft the specific request. Differs depending on the operation & target

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER total
Optional. The a 'total' number of requests to show next to the 'flush' output. E.g. if executing a total of 100 items and it is flushed after 25, one would get [25/100] shown as an output

.EXAMPLE
Add-BacklogBatchRequest -boardCommandList $boardCommandList -itemToProcess @{ SourceItem = @{ Id = 1; title = 'Item 1' }; TargetItem = @{ Id = 2; title = 'Item 2 } } -organization 'contoso'

Generate a command to create the relationship [Item 1 -> Child Of -> Item 2] in organization [contoso]
#>
function Add-BacklogBatchCreateRelationRequest {

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

    $restInfo = Get-RelativeConfigData -configToken 'RESTBoardWorkItemUpdate'
    $requestItem = @{
        method = $restInfo.method
        uri     = $restInfo.uri -f $itemToProcess.SourceItem.Id
        headers = @{
            "Content-Type" = Get-RelativeConfigData -configToken 'PATCH_ContentType'
        }
        body    = @(
            @{
                op    = 'add'
                path  = "/relations/-"
                value = @{
                    rel        = "System.LinkTypes.Hierarchy-Reverse"
                    url        = ((Get-RelativeConfigData -configToken 'RESTBoardWorkItemRelationAdd').Uri -f [uri]::EscapeDataString($Organization), $itemToProcess.TargetItem.Id)
                    attributes = @{
                        name = "Parent"
                    }
                }
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
        Write-Verbose ("Create Relation: Execute [{0}|$total] requests. Flush at item [{1}|Child|{2}] due to concurrent update limit [$apiCapacity]." -f $boardCommandList.Count, $itemToProcess.SourceItem.title, $itemToProcess.TargetItem.title)
        Clear-BacklogItemCommandBatch -boardCommandList $boardCommandList -Organization $Organization
    }
}