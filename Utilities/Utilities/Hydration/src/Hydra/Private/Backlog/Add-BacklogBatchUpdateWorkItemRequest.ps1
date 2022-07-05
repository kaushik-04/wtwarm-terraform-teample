<#
.SYNOPSIS
Add a correctly formatted batch item to update a workitem to the stack of commands

.DESCRIPTION
Add a correctly formatted batch item to update a workitem to the stack of commands
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
Add-BacklogBatchRequest -itemToProcess @{ id = 1; 'state' = 'Closed'; } -organization 'contoso' -project 'Module Playground' -boardCommandList $boardCommandList

Generate a command to update the work item with id 1 with a new state 'closed' in project [contoso/Module Playground]
#>
function Add-BacklogBatchUpdateWorkItemRequest {

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
        method  = $restInfo.method
        uri     = $restInfo.uri -f $itemToProcess.Id
        headers = @{
            "Content-Type" = Get-RelativeConfigData -configToken 'PATCH_ContentType'
        }
        body    = ''
    }

    $body = [System.Collections.ArrayList]@()
    $itemProperties = ($itemToProcess | Get-Member -MemberType 'NoteProperty').Name
    $relevantProperties = ($itemProperties | Where-Object { $_ -notin @('id') -and $_ -notlike "Title *" -and $_ -notlike "GEN_*" -and (-not [String]::IsNullOrEmpty($itemToProcess.$_)) })
    foreach ($property in $relevantProperties) {
        $remotePropertyName = Get-BacklogPropertyCounterpart -localPropertyName $property

        if($property -in @('Board Column', 'Board Column Done', 'Board Lane')) {
            Write-Warning ('Item [{0}]: The properties [Board Column], [Board Column Done] & [Board Lane] are currently not supported and will be ignored' -f $itemToProcess.title)
            continue
        }

        $null = $body.Add(
            @{
                op    = 'add'
                path  = "/fields/$remotePropertyName"
                value = $itemToProcess.$property
            }
        )
    }
    $requestItem.body = $body

    # Add item
    $null = $boardCommandList.Add(
        @{
            title        = $itemToProcess.title
            workitemtype = $itemToProcess.'Work Item Type'
            request      = $requestItem
        }
    )

    $apiCapacity = Get-RelativeConfigData -configToken 'BoardBatchCapacity'
    if ($boardCommandList.Count -eq $apiCapacity) {
        Write-Verbose ("Update Item: Execute [{0}|$total] requests. Flush at item [{1}] due to concurrent update limit [$apiCapacity]." -f $boardCommandList.Count, $itemToProcess.title)
        Clear-BacklogItemCommandBatch -boardCommandList $boardCommandList -Organization $Organization
    }
}