<#
.SYNOPSIS
Convert the given board data into a relation map array list

.DESCRIPTION
Convert the given board data into a relation map array list

.PARAMETER localBacklogData
The local board data to convert

.EXAMPLE
Get-BacklogItemLocalRelationTupleList -localBacklogData $localBacklogData

Convert the data in the $localBacklogData array list
#>
function Get-BacklogItemLocalRelationTupleList {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localBacklogData
    )

    $titleColumns = ($localBacklogData | Get-Member -Name Title*).Name

    $hasHierarchy = $titleColumns -match 'Title [0-9]+'
    if ($hasHierarchy) {
        # Create Relations
        $hierarchyDepth = ($titleColumns | Measure-Object -Maximum).Maximum.Split(' ')[1]
        Write-Debug "Evaluate relations. Item hierarchy of depth [$hierarchyDepth] found"

        $fraudElements = ($localBacklogData | Where-Object { [String]::IsNullOrEmpty($_.'ID') })
        if ($fraudElements.Count -gt 0) {
            Write-Error ("All board elements require an ID to process the relations. [{0}] elements are missing the ID property." -f $fraudElements.Count)
            return
        }

        # Processing
        $relationsToSet = [System.Collections.ArrayList] @()
        $parentStack = [System.Collections.ArrayList] @()
        $indentLevel = 1
        for ($itemCounter = 0; $itemCounter -lt $localBacklogData.Count; $itemCounter++) {

            if ([String]::IsNullOrEmpty($localBacklogData[$itemCounter]."Title $indentLevel")) {
                # Current Cell is empty
                if ((($indentLevel..$hierarchyDepth) | Where-Object { -not [String]::IsNullOrEmpty($localBacklogData[$itemCounter]."Title $_") }).Count -gt 0) {
                    # Non-empty cell is to the right. Add previous item to parent stack, indent one to the right and check the same row again
                    $null = $parentStack.Add($localBacklogData[$itemCounter - 1])
                    $indentLevel++
                    $itemCounter--
                    continue
                }
                else {
                    # Non-empty cell is to the left. Remove deepest item from parent stack, indent one to the left and check the same row again
                    $null = $parentStack.RemoveAt($parentStack.Count - 1)
                    $indentLevel--
                    $itemCounter--
                    continue
                }
            }

            # Set relation string property on object
            if ($parentStack.count -gt 0) {
                $null = $relationsToSet.Add(
                    [PSCustomObject]@{
                        sourceItem   = $localBacklogData[$itemCounter]
                        targetItem   = $parentStack[-1]
                        RelationType = 'Child'
                    }
                )
            }
        }

        return $relationsToSet
    }
    else {
        Write-Verbose "No item hierarchy found in provided data file"
    }
}