<#
.SYNOPSIS
Inner function to test if a given item is already contained in a given list in some shape or form

.DESCRIPTION
Inner function to test if a given item is already contained in a given list in some shape or form
Also handles th Child-Parent cases. So if an item with a child relation but the same IDs is already contained in the list, the function will not add the parent counterpart with flipped Ids

.PARAMETER listToCheck
Mandatory. The list with unique items.

.PARAMETER itemToCompare
Mandatory. The item to check for in the listToCheck

.EXAMPLE
Confirm-RelationContained -listToCheck @(@{ sourceItem = @{ id = 1 }; targetItem = @{ id = 2 }; relationType = 'Related' }) -itemToCompare @{ @{ sourceItem = @{ id = 1 }; targetItem = @{ id = 2 }; relationType = 'Related' } }

Check if the given relation '1 -> Related to -> 2' is already contained in the list to check. The given example results to 'true'
#>
function Confirm-RelationContained {

    [CmdletBinding()]
    [OutputType('boolean')]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $listToCheck,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $itemToCompare
    )

    $alreadyDetected = $false
    switch ($itemToCompare.relationType) {
        'Child' {
            $alreadyDetected = ($listToCheck | Where-Object {
                    ($_.SourceItemId -eq $itemToCompare.SourceItemId -and
                        $_.TargetItemId -eq $itemToCompare.TargetItemId -and
                        $_.RelationType -eq $itemToCompare.relationType) -or
                    ($_.TargetItemId -eq $itemToCompare.SourceItemId -and
                        $_.SourceItemId -eq $itemToCompare.TargetItem.Id -and
                        $_.RelationType -eq 'Parent')
                }).Count -gt 0
        }
        'Parent' {
            $alreadyDetected = ($listToCheck | Where-Object {
                    ($_.SourceItemId -eq $itemToCompare.SourceItemId -and
                        $_.TargetItemId -eq $itemToCompare.TargetItemId -and
                        $_.RelationType -eq $itemToCompare.relationType) -or
                    ($_.TargetItemId -eq $itemToCompare.SourceItemId -and
                        $_.SourceItemId -eq $itemToCompare.TargetItemId -and
                        $_.RelationType -eq 'Child')
                }).Count -gt 0
        }
        Default {
            $alreadyDetected = ($listToCheck | Where-Object {
                    ($_.SourceItemId -eq $itemToCompare.sourceItemId -and
                        $_.TargetItemId -eq $itemToCompare.targetItemId -and
                        $_.RelationType -eq $itemToCompare.relationType) -or
                    ($_.TargetItemId -eq $itemToCompare.sourceItemId -and
                        $_.SourceItemId -eq $itemToCompare.targetItemId -and
                        $_.RelationType -eq $itemToCompare.relationType)
                }).Count -gt 0
        }
    }

    return $alreadyDetected
}
