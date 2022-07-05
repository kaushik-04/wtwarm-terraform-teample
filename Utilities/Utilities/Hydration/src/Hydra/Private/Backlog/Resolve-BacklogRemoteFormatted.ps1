<#
.SYNOPSIS
Resolve and set the corrsponding relation string for each item in the given remote backlog data

.DESCRIPTION
Recursively resolve the child items of the given remote backlog data and set the corrsponding relation string for each item

.PARAMETER parentStack
Optional. The parent stack of items used to buld the relations strings for child items

.PARAMETER remoteItem
Mandatory. The current remote item to process

.PARAMETER remoteBacklogData
Optional. The original set of remote data to process. Used to identify child items

.EXAMPLE
Resolve-BacklogChildItems -remoteItem @{ id = 1; fields = @{ 'System.Title' = 'Item 1'; 'System.WorkItemType' = 'Epic'}} -remoteBacklogData @(@{ id = 1; fields = @{ 'System.Title' = 'Item 1'; 'System.WorkItemType' = 'Epic'}}, @{ id = 2; fields = @{ 'System.Title' = 'Item 2'; 'System.WorkItemType' = 'Epic'}})

Determine the relation string of the given remote item and all its potential child items. In this example it has none and would result in the remote item getting the relation string property with value 'Epic=Title 1' assigned
#>
function Resolve-BacklogChildItems {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [System.Collections.ArrayList] $parentStack = [System.Collections.ArrayList]@(),

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteItem,

        [Parameter(Mandatory = $false)]
        [PSCustomObject[]] $remoteBacklogData = @()
    )

    # Build & set relation string on item
    $relationStringProperty = 'GEN_RelationString'
    $relationString = ''
    for ($parentIndex = 0; $parentIndex -lt $parentStack.Count; $parentIndex++) {
        $relationString += "{0}={1}{2}" -f $parentStack[$parentIndex].item.fields.'System.WorkItemType', $parentStack[$parentIndex].item.fields.'System.Title', (([String]::IsNullOrEmpty($parentStack[$parentIndex].relationType)) ? '' : ("-[_{0}_]-" -f $parentStack[$parentIndex].relationType))
    }
    $relationString += ('{0}={1}' -f $remoteItem.fields.'System.WorkItemType', $remoteItem.fields.'System.Title')

    if ([String]::IsNullOrEmpty($remoteItem.$relationStringProperty)) {
        $remoteItem | Add-Member -NotePropertyName $relationStringProperty -NotePropertyValue ''
    }
    $remoteItem.$relationStringProperty = $relationString

    # Drill down into child relations
    $itemRelations = $remoteItem.relations | Where-Object { $_.rel -eq 'System.LinkTypes.Hierarchy-Forward' } # only parent->child relations
    if ($itemRelations.count -gt 0) {

        # Invoke recursive
        foreach ($childRelation in $itemRelations) {

            $null = $parentStack.Add(
                @{
                    item         = $remoteItem
                    relationType = $childRelation.attributes.Name
                }
            )

            # Find actual item
            $childItem = $remoteBacklogData | Where-Object { $_.'Id' -eq ([int] $childRelation.url.split('/')[-1]) }
            Resolve-BacklogChildItems -parentStack $parentStack -remoteItem $childItem -remoteBacklogData $remoteBacklogData
        }
    }

    # Pop stack again
    if ($parentStack.Count -gt 0) {
        $null = $parentStack.RemoveAt($parentStack.Count - 1)
    }
}

<#
.SYNOPSIS
Resolve all relation strings for the remote items in the given remote backlog array

.DESCRIPTION
Resolve all relation strings for the remote items in the given remote backlog array
Target Format for each item (Read right-to-left): 'Epic=Epic 2-[_Related_]-Feature=Feature 23-[_Child_]-User Story=User Story 231'

.PARAMETER remoteBacklogData
The remote backlog items to resolve

.EXAMPLE
Resolve-BacklogRemoteFormatted -remoteBacklogData $remoteremoteData

Determine all relations string for the items in the $remoteBacklogData array
#>
function Resolve-BacklogRemoteFormatted {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $remoteBacklogData
    )

    # Set relation string property on object
    foreach ($remoteItem in $remoteBacklogData | Where-Object { [String]::IsNullOrEmpty($_.fields.'System.Parent') }) {

        # Either a lonley wolf, or top level parent
        $recursionInputObject = @{
            remoteItem        = $remoteItem
            remoteBacklogData = $remoteBacklogData
        }
        Resolve-BacklogChildItems @recursionInputObject
    }
}