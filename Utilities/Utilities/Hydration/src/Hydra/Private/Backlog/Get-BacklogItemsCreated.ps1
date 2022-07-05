<#
.SYNOPSIS
Get the board items that already exist in the given project

.DESCRIPTION
Get the board items that already exist in the given project. By default only returns the IDs.

.PARAMETER Organization
Mandatory. The organization to fetch the areas from. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to fetch the areas from. E.g. 'Module Playground'

.PARAMETER fetchDetails
Optional. Specify whether to only return the IDs of the existing items, or fetch their details like title, status etc. too

.PARAMETER expandCategory
The specific area to fetch the details for. Can be 'None', 'Relations', 'Fields', 'Links' or 'All'. Defaults to ''None'

.PARAMETER DryRun
Simulate and end2end execution

.EXAMPLE
Get-BacklogItemsCreated -Project 'Module Playground' -Organization 'contoso'

Get the remote backlog item IDs

.EXAMPLE
Get-BacklogItemsCreated -Project 'Module Playground' -Organization 'contoso' -fetchDetails

Get the remote backlog items, expanded with their details (e.g. title, created by, etc.)

.EXAMPLE
Get-BacklogItemsCreated -Project 'Module Playground' -Organization 'contoso' -fetchDetails -expandCategory 'Relations'

Get the remote backlog items, expanded with their details (e.g. title, created by, etc.) and including their relations

.NOTES
The function logic follows a 2 step approach (wiql fetch + api fetch) as the API only returns the first 200 items, and WIQL only the IDs

Beware: For an yet unknown reason, the invocation returned the IDs of work items from a single different project.
#>
function Get-BacklogItemsCreated {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    [OutputType('System.Object[]')]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [switch] $fetchDetails,

        [Parameter(Mandatory = $false)]
        [ValidateSet('None', 'Relations', 'Fields', 'Links', 'All')]
        [string] $expandCategory = 'None',

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTBoardWorkItemGetWiql'
    $restInputObject = @{
        method = $restInfo.method
        uri    = $restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project)
        body   = "{ `"query`": `"SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.TeamProject] = '$Project' `" }"
    }
    $existingItems = Invoke-RESTCommand @restInputObject

    if ($existingItems.workitems) {

        if ($fetchDetails) {

            $detailedItems = [System.Collections.ArrayList]@()

            $idBuckets = @()
            # The api returns only a maximum of 200 items. Hence we need to slice the requests up if we request more than 200 results
            $apiCapacity = Get-RelativeConfigData -configToken 'BoardBatchCapacity'
            if ($existingItems.workitems.count -gt $apiCapacity) {
                $idBuckets = Split-Array -InputArray $existingItems.workitems.id -SplitSize $apiCapacity
                Write-Debug ("Remote data refresh: [{0}] buckets of $apiCapacity items to query details for" -f $idBuckets.Count)
            }
            else {
                # No more than 200 items. No buckets required
                $idBuckets = , $existingItems.workitems.id
                Write-Debug ("Remote data refresh: One bucket of [{0}] items to query details for" -f $existingItems.count)
            }

            foreach ($bucket in $idBuckets) {

                $restInfo = Get-RelativeConfigData -configToken 'RESTBoardWorkItemGetBatch'
                $restInputObject = @{
                    method = $restInfo.Method
                    uri    = $restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project)
                    body   = '{0} "$expand": "{1}", "Ids": [{2}] {3}' -f '{', $expandCategory, ($bucket -join ','), '}'
                }
                $itemsResponse = Invoke-RESTCommand @restInputObject
                if ($itemsResponse.value) {
                    $detailedItems.AddRange($itemsResponse.value)
                } else {
                    Write-Verbose ("No details found for IDs [{0}]" -f ($bucket -join ','))
                }
            }
            return $detailedItems
        }
        else {
            return $existingItems.workitems.Id
        }
    }
    elseif (-not [String]::IsNullOrEmpty($existingItems.errorCode)) {
        if ($existingItems.message -like "*project does not exist*" -and $dryRun) {
            return @()
        }
        Write-Error ("An error occured while fetching the workitems: [{0}]" -f $existingItems.message)
    }
    else {
        Write-Verbose "No existing board items found"
        return @()
    }
}