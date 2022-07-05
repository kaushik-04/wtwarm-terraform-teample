<#
.SYNOPSIS
Add a correctly formatted batch item to create a workitem to the stack of commands

.DESCRIPTION
Add a correctly formatted batch item to create a workitem to the stack of commands
The function automatically flushes the commands if certain requirements demand it.

.PARAMETER boardCommandList
Mandatory. The command arraylist to store the formatted items in

.PARAMETER localBacklogData
Optional. The local backlog data provided. Must be provided for workitem create/update entries

.PARAMETER itemToProcess
Mandatory. An object containing all data required to craft the specific request. Differs depending on the operation & target

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to create the items in. E.g. 'Module Playground'

.PARAMETER total
Optional. The a 'total' number of requests to show next to the 'flush' output. E.g. if executing a total of 100 items and it is flushed after 25, one would get [25/100] shown as an output

.EXAMPLE
Add-BacklogBatchRequest -itemToProcess @{ title = 'Title 1'; 'Work Item Type' = 'Epic'; } -organization 'contoso' -project 'Module Playground' -localBacklogData $localBacklogData -boardCommandList $boardCommandList

Generate a command to create the 'Epic' work item 'Title 1' in project [contoso/Module Playground]
#>
function Add-BacklogBatchCreateWorkItemRequest {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList] $boardCommandList,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localBacklogData,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $itemToProcess,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [int] $total
    )

    # Build item
    $restInfo = Get-RelativeConfigData -configToken 'RESTBoardWorkItemCreate'
    $requestItem = @{
        method  = $restInfo.method
        uri     = $restInfo.uri -f [uri]::EscapeDataString($Project), ($itemToProcess.'Work Item Type' -replace '_', '')
        headers = @{
            "Content-Type" = Get-RelativeConfigData -configToken 'PATCH_ContentType'
        }
        body    = @(
            @{
                op    = 'add'
                path  = '/id'
                # For new items, the value MUST be negative and unique (per request) to generate a new ID
                value = [int]((($boardCommandList.request.body | Where-Object { $_.path -eq '/id' }).value | Measure-Object -Minimum).Minimum - 1)
            }
        )
    }
    $availableProperties = ($itemToProcess | Get-Member -MemberType 'NoteProperty').Name
    $relevantProperties = $availableProperties | Where-Object {
        $_ -notin @('id', 'Work Item Type') -and
        $_ -notlike "Title *" -and
        $_ -notlike "GEN_*" -and
        (-not [String]::IsNullOrEmpty($itemToProcess.$_)) }
    foreach ($property in $relevantProperties) {
        $remotePropertyName = Get-BacklogPropertyCounterpart -localPropertyName $property

        if($property -in @('Board Column', 'Board Column Done', 'Board Lane')) {
            Write-Warning ('Item [{0}]: The properties [Board Column], [Board Column Done] & [Board Lane] are currently not supported and will be ignored' -f $itemToProcess.title)
            continue
        }

        $requestItem.body += @{
            op    = 'add'
            path  = "/fields/$remotePropertyName"
            from  = $null
            value = $itemToProcess.$property
        }
    }

    # If we find a duplicate board item without an ID during creation, we need to flush first to avoid ambiguity
    if (($boardCommandList | Where-Object { $_.title -eq $itemToProcess.title -and $_.request.uri -eq $requestItem.uri }).Count -gt 0) {
        Write-Verbose ('Create Item: Execute [{0}|{1}] requests. Flush at item [{2}] due to ambiguity.' -f $boardCommandList.count, $total, $itemToProcess.title)
        Clear-BacklogItemCommandBatch -boardCommandList $boardCommandList -localBacklogData $localBacklogData -Organization $Organization
    }

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
        Write-Verbose ("Create Item: Execute [{0}|$total] requests. Flush at item [{1}] due to concurrent update limit [$apiCapacity]." -f $boardCommandList.Count, $itemToProcess.title)
        Clear-BacklogItemCommandBatch -boardCommandList $boardCommandList -localBacklogData $localBacklogData -Organization $Organization
    }
}