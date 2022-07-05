<#
.SYNOPSIS
Flush/execute the batch commands that are in in the provided command list

.DESCRIPTION
Flush/execute the batch commands that are in in the provided command list

.PARAMETER boardCommandList
Mandatory. The arraylist that holds the formatted command-itemss

.PARAMETER localBacklogData
Optional. The local backlog data. Should be provided if 'create workitem' commands are in the list of commands to flush. If so, the local data is extended with the IDs of the created items.

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.EXAMPLE
Clear-BacklogItemCommandBatch -boardCommandList $boardCommandList -Organization 'contoso'

.EXAMPLE
Clear-BacklogItemCommandBatch -boardCommandList $boardCommandList -localBacklogData @( @{ title = 'Title 1', 'Work Item Type' = 'Epic' }, @{ title = 'Title 2', 'Feature' = 'Epic' } ) -Organization 'contoso'

Flush all commands that are in the boardCommandList list and if any create workitem commands are included, try to assign matching IDs to the given localBacklogData
#>
function Clear-BacklogItemCommandBatch {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList] $boardCommandList,

        [Parameter(Mandatory = $false)]
        [PSCustomObject[]] $localBacklogData,

        [Parameter(Mandatory = $false)]
        [string] $Organization
    )

    if ($boardCommandList.Count -gt 0) {

        # If only one item is in the list we have to make sure the body is still formatted as an array
        $body = ($boardCommandList.Count -eq 1) ? (ConvertTo-Json (, $boardCommandList.request) -Depth 10) : (ConvertTo-Json $boardCommandList.request -Depth 10)

        $restInfo = Get-RelativeConfigData -configToken 'RESTBoardBatchSet'
        $restInputObject = @{
            method = $restInfo.method
            uri    = $restInfo.uri -f [uri]::EscapeDataString($Organization)
            body   = $body
        }
        if ($PSCmdlet.ShouldProcess(("[{0}] commands in stack") -f $boardCommandList.Count), "Flush") {
            $itemsResponse = (Invoke-RESTCommand @restInputObject).value
        }

        for ($responseIndex = 0; $responseIndex -lt $itemsResponse.Count; $responseIndex++) {

            if ($itemsResponse[$responseIndex].code -in (Get-RelativeConfigData -configToken 'BoardBatchReponseSuccess')) {
                # Handle SUCCESS response
                if ($itemsResponse[$responseIndex].body) {
                    $parsedResponse = ConvertFrom-Json $itemsResponse[$responseIndex].body
                    if (-not [String]::IsNullOrEmpty($parsedResponse.Id) -and $localBacklogData.count -gt 0) {
                        # Assign Id
                        $matchingBacklogItem = $localBacklogData | Where-Object { $_.Title -eq $parsedResponse.fields.'System.Title' -and [String]::IsNullOrEmpty($_.Id) }
                        if ($matchingBacklogItem) {
                            $firstMatching = $matchingBacklogItem[0] # first matching one that does not have an id
                            if (($firstMatching | Get-Member -MemberType "NoteProperty" ).Name -notcontains "Id") {
                                $firstMatching | Add-Member -NotePropertyName 'Id' -NotePropertyValue ''
                            }
                            $firstMatching.Id = $parsedResponse.id
                        }
                    }
                }
            }
            else {
                # Handle ERROR response
                $originalRequestBody = ($boardCommandList.request)[$responseIndex].body | ConvertTo-Json | ConvertFrom-Json | Format-Table | Out-String
                $originalRequestUri = ($boardCommandList.request)[$responseIndex].uri

                $parsedResponse = ConvertFrom-Json $itemsResponse[$responseIndex].body
                if ($parsedResponse.errorMessage) {
                    Write-Warning ("`nGot error [{0}] `n  for batch request `n[{1}]`n[{2}]" -f $parsedResponse.errorMessage, $originalRequestUri, $originalRequestBody)
                }
                else {
                    Write-Warning ("`nGot error [{0}] `n  for batch request `n[{1}]`n[{2}]" -f $parsedResponse.value.Message, $originalRequestUri, $originalRequestBody)
                }
            }
        }

        # Clear stack after execution
        $boardCommandList.RemoveRange(0, $boardCommandList.Count)
    }
}