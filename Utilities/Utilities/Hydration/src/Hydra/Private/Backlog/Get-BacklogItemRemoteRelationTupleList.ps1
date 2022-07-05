<#
.SYNOPSIS
Get a flat map [source-target-relation] of the currently deployed board items

.DESCRIPTION
Get a flat map [source-target-relation] of the currently deployed board items
Items may occure multiple times (e.g. 'A-B-Related' & 'B-A-Related')

.PARAMETER remoteBacklogData
Mandatory. The relation data to process

.EXAMPLE
Get-BacklogItemRemoteRelationTupleList -remoteBacklogData $remoteBacklogData

Instead of fetching the data, get a relation map of all board items in the given $remoteBacklogData array
#>
function Get-BacklogItemRemoteRelationTupleList {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $remoteBacklogData
    )

    $formattedList = [System.Collections.ArrayList]@()
    foreach ($itemWithRelations in ($remoteBacklogData | Where-Object { $_.relations.Count -gt 0 } )) {

        foreach ($relationItem in $itemWithRelations.relations) {

            $counterPartItem = $remoteBacklogData | Where-Object { $_.'Id' -eq ([int] $relationItem.url.split('/')[-1]) }
            if (($formattedList | Where-Object {
                        ($_.sourceItem.Id -eq $counterPartItem.Id -and
                            $_.targetItem.Id -eq $itemWithRelations.Id -and
                            $_.RelationType -eq $relationItem.attributes.Name) -or
                        ($_.sourceItem.Id -eq $itemWithRelations.Id -and
                            $_.targetItem.Id -eq $counterPartItem.Id -and
                            $_.RelationType -eq $relationItem.attributes.Name)
                    }).Count -eq 0) {

                $null = $formattedList.Add(
                    [PSCustomObject]@{
                        sourceItem   = $counterPartItem
                        targetItem   = $itemWithRelations
                        RelationType = $relationItem.attributes.Name
                    }
                )
            }
        }
    }

    return $formattedList
}