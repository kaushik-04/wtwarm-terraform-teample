<#
.SYNOPSIS
A private function to recursively resolve the relation strings for the given item and its children

.DESCRIPTION
A private function to recursively resolve the relation strings for the given item and its children

.PARAMETER parentStack
Optional. A stack of parent items that is passed through the hierarchy to build the proper relation string

.PARAMETER ClassificationNode
Mandatory. The ClassificationNode to process

.PARAMETER flatClassificationNodeList
Mandatory. A flat list that receives each processed item

.EXAMPLE
Resolve-ClassificationNodesChildItems -ClassificationNode @{ name = 'itemA'; children = @( @{ name = 'ItemB' })} -flatClassificationNodeList $flatClassificationNodeList

Resolve the relation string for itemA and recursively its child itemB. Both are returned as entries of the given flatClassificationNodeList
#>
function Resolve-ClassificationNodesChildItems {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [System.Collections.ArrayList] $parentStack = [System.Collections.ArrayList]@(),

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $ClassificationNode,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList] $flatClassificationNodeList
    )

    $relationStringProperty = 'GEN_RelationString'
    # Build & set relation string on item
    $relationString = ''
    for ($parentIndex = 0; $parentIndex -lt $parentStack.Count; $parentIndex++) {
        $relationString += "{0}{1}" -f $parentStack[$parentIndex].name, ("-[_Child_]-")
    }
    $relationString += $ClassificationNode.name

    if (($ClassificationNode | Get-Member -MemberType "NoteProperty").Name -notcontains $relationStringProperty) {
        $ClassificationNode | Add-Member -NotePropertyName $relationStringProperty -NotePropertyValue ''
    }
    $ClassificationNode.$relationStringProperty = $relationString
    $null = $flatClassificationNodeList.Add($ClassificationNode)

    if ($ClassificationNode.children.count -gt 0) {
        # Invoke recursive
        foreach ($child in $ClassificationNode.children) {
            $null = $parentStack.Add($ClassificationNode)
            Resolve-ClassificationNodesChildItems -parentStack $parentStack -ClassificationNode $child -flatClassificationNodeList $flatClassificationNodeList
        }
    }

    # Pop stack again
    if ($parentStack.Count -gt 0) {
        $null = $parentStack.RemoveAt($parentStack.Count - 1)
    }
}


<#
.SYNOPSIS
Resolve the relation strings for the given ClassificationNode list

.DESCRIPTION
Resolve the relation strings for the given ClassificationNode list
Each item receives a hierarchy property that illustrates its location in the given hierarchy.
For example, if you have an itemA and an itemB that is a child of itemA they get the following properties added:
- itemA: GEN_relationString = itemA
- itemB: GEN_relationString = itemA-[_Child_]-itemB

.PARAMETER Project
Mandatory. The project to currently processed. If provided is consdered the root ClassificationNode path and added to the list. E.g. 'Module Playground'
Should be provided for local data if the root is not provided.

.PARAMETER nodes
Mandatory. The project nodes to process

.EXAMPLE
Resolve-ProjectClassificationNodeFormatted -project 'Module Playground' -nodes @(@{ name = 'itemA'; children = @( @{ name = 'ItemB' })},  @{ name = 'itemC'})

Resolve the relations strings of the given items A, B & C and consider 'Module Playground' as the top level ClassificationNode path parent / root

.EXAMPLE
Resolve-ClassificationNodesFormatted -nodes @(@{ name = 'itemA'; children = @( @{ name = 'ItemB' })},  @{ name = 'itemC'})

Resolve the relations strings of the given items A, B & C
#>
function Resolve-ClassificationNodesFormatted {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $false)]
        [string] $project,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $nodes
    )

    # Add root if not existing
    if ((-not [String]::IsNullOrEmpty($project))) {
        $nodes = @(
            [PSCustomObject]@{
                Name     = $project
                Children = $nodes
            }
        )
    }

    $flatClassificationNodeList = [System.Collections.ArrayList]@()
    foreach ($node in $nodes) {
        Resolve-ClassificationNodesChildItems -ClassificationNode $node -flatClassificationNodeList $flatClassificationNodeList
    }

    return $flatClassificationNodeList
}