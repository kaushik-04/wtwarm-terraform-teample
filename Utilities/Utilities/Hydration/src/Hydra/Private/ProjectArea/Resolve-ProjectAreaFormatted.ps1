<#
.SYNOPSIS
A private function to recursively resolve the relation strings for the given item and its children

.DESCRIPTION
A private function to recursively resolve the relation strings for the given item and its children

.PARAMETER parentStack
Optional. A stack of parent items that is passed through the hierarchy to build the proper relation string

.PARAMETER area
Mandatory. The area to process

.PARAMETER flatAreaList
Mandatory. A flat list that receives each processed item

.EXAMPLE
Resolve-AreaChildItems -area @{ name = 'itemA'; children = @( @{ name = 'ItemB' })} -flatAreaList $flatAreaList

Resolve the relation string for itemA and recursively its child itemB. Both are returned as entries of the given flatAreaList
#>
function Resolve-AreaChildItems {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [System.Collections.ArrayList] $parentStack = [System.Collections.ArrayList]@(),

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $area,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList] $flatAreaList
    )

    $relationStringProperty = 'GEN_RelationString'
    # Build & set relation string on item
    $relationString = ''
    for ($parentIndex = 0; $parentIndex -lt $parentStack.Count; $parentIndex++) {
        $relationString += "{0}{1}" -f $parentStack[$parentIndex].name, ("-[_Child_]-")
    }
    $relationString += $area.name

    if (($area | Get-Member -MemberType "NoteProperty").Name -notcontains $relationStringProperty) {
        $area | Add-Member -NotePropertyName $relationStringProperty -NotePropertyValue ''
    }
    $area.$relationStringProperty = $relationString
    $null = $flatAreaList.Add($area)

    if ($area.children.count -gt 0) {
        # Invoke recursive
        foreach ($child in $area.children) {
            $null = $parentStack.Add($area)
            Resolve-AreaChildItems -parentStack $parentStack -area $child -flatAreaList $flatAreaList
        }
    }

    # Pop stack again
    if ($parentStack.Count -gt 0) {
        $null = $parentStack.RemoveAt($parentStack.Count - 1)
    }
}


<#
.SYNOPSIS
Resolve the relation strings for the given area paths list

.DESCRIPTION
Resolve the relation strings for the given area paths list
Each item receives a hierarchy property that illustrates its location in the given hierarchy.
For example, if you have an itemA and an itemB that is a child of itemA they get the following properties added:
- itemA: GEN_relationString = itemA
- itemB: GEN_relationString = itemA-[_Child_]-itemB

.PARAMETER Project
Mandatory. The project to currently processed. If provided is consdered the root area path and added to the list. E.g. 'Module Playground'
Should be provided for local data if the root is not provided.

.PARAMETER Areas
Mandatory. The project areas to process

.EXAMPLE
Resolve-ProjectAreaFormatted -project 'Module Playground' -areas @(@{ name = 'itemA'; children = @( @{ name = 'ItemB' })},  @{ name = 'itemC'})

Resolve the relations strings of the given items A, B & C and consider 'Module Playground' as the top level area path parent

.EXAMPLE
Resolve-ProjectAreaFormatted -areas @(@{ name = 'itemA'; children = @( @{ name = 'ItemB' })},  @{ name = 'itemC'})

Resolve the relations strings of the given items A, B & C
#>
function Resolve-ProjectAreaFormatted {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $false)]
        [string] $project,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $Areas
    )

    # Add root if not existing
    if ((-not [String]::IsNullOrEmpty($project)) -and -not ($areas.Count -eq 1)) {
        $Areas = @(
            [PSCustomObject]@{
                Name     = $project
                Children = $Areas
            }
        )
    }

    $flatAreaList = [System.Collections.ArrayList]@()
    foreach ($area in $areas) {
        Resolve-AreaChildItems -area $area -flatAreaList $flatAreaList
    }

    return $flatAreaList
}