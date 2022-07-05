<#
.SYNOPSIS
Resolve all relation strings for the local items in the given local backlog array

.DESCRIPTION
Resolve all relation strings for the local items in the local remote backlog array
Target Format for each item (Read right-to-left): 'Epic=Epic 2-[_Related_]-Feature=Feature 23-[_Child_]-User Story=User Story 231'

.PARAMETER localBacklogData
The local backlog items to resolve

.EXAMPLE
Resolve-BacklogLocalFormatted -localBacklogData $localBacklogData

Resolve the relations string of the given $localBacklogData array
#>
function Resolve-BacklogLocalFormatted {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localBacklogData
    )

    $titleColumns = ($localBacklogData | Get-Member -Name Title*).Name

    # Determine Title
    foreach ($backlogItem in $localBacklogData) {
        if ([String]::IsNullOrEmpty($backlogItem.'Title')) {
            foreach ($titleColumn in $titleColumns) {
                if (-not [String]::IsNullOrEmpty($backlogItem.$titleColumn)) {
                    if (($backlogItem | Get-Member -MemberType "NoteProperty" ).Name -notcontains "Title") {
                        $backlogItem | Add-Member -NotePropertyName 'Title' -NotePropertyValue ''
                    }
                    $backlogItem.'Title' = $backlogItem.$titleColumn
                    break
                }
            }
        } else {
            # Add top-level title for consistency of hierarchical & non-hierachical files
            if (($backlogItem | Get-Member -MemberType "NoteProperty" ).Name -notcontains "Title 1") {
                $backlogItem | Add-Member -NotePropertyName 'Title 1' -NotePropertyValue ''
            }
            $backlogItem.'Title 1' = $backlogItem.'Title'
        }
    }

    # Determine Relation String
    $hasHierarchy = $titleColumns -match 'Title [0-9]+'
    $relationStringProperty = 'GEN_RelationString'
    if ($hasHierarchy) {

        $hierarchyDepth = ($titleColumns | Measure-Object -Maximum).Maximum.Split(' ')[1]

        # Processing
        $parentStack = [System.Collections.ArrayList] @()
        $indentLevel = 1
        for ($itemCounter = 0; $itemCounter -lt $localBacklogData.Count; $itemCounter++) {

            if ([String]::IsNullOrEmpty($localBacklogData[$itemCounter]."Title $indentLevel")) {
                # Current Cell is empty
                if ((($indentLevel..$hierarchyDepth) | Where-Object { -not [String]::IsNullOrEmpty($localBacklogData[$itemCounter]."Title $_") }).Count -gt 0) {
                    # Non-empty cell is to the right
                    $null = $parentStack.Add(
                        [PSCustomObject]@{
                            relationType = $localBacklogData[$itemCounter - 1]."GEN_Relation"
                            item         = $localBacklogData[$itemCounter - 1]
                        }
                    )
                    $indentLevel++
                    $itemCounter--
                    continue
                }
                else {
                    # Non-empty cell is to the left
                    $null = $parentStack.RemoveAt($parentStack.Count - 1)
                    $indentLevel--
                    $itemCounter--
                    continue
                }
            }

            # Set relation string property on object
            if ($parentStack.count -eq 0) {
                if ([String]::IsNullOrEmpty($localBacklogData[$itemCounter].$relationStringProperty)) {
                    $localBacklogData[$itemCounter] | Add-Member -NotePropertyName $relationStringProperty -NotePropertyValue ''
                }
                $localBacklogData[$itemCounter].$relationStringProperty = '{0}={1}' -f $localBacklogData[$itemCounter].'Work Item Type', $localBacklogData[$itemCounter].title
            }
            else {
                if ([String]::IsNullOrEmpty($localBacklogData[$itemCounter].$relationStringProperty)) {
                    $localBacklogData[$itemCounter] | Add-Member -NotePropertyName $relationStringProperty -NotePropertyValue ''
                }

                $relationString = ''
                for ($parentIndex = 0; $parentIndex -lt $parentStack.Count; $parentIndex++) {
                    $relationString += '{0}={1}{2}' -f $parentStack[$parentIndex].item.'Work Item Type', $parentStack[$parentIndex].item.title, (([String]::IsNullOrEmpty($parentStack[$parentIndex + 1].relationType)) ? '' : ("-[_{0}_]-" -f $parentStack[$parentIndex + 1].relationType))
                }

                if ([String]::IsNullOrEmpty($localBacklogData[$itemCounter]."GEN_Relation")) {
                    if (($localBacklogData[$itemCounter] | Get-Member -MemberType "NoteProperty" ).Name -notcontains "GEN_Relation") {
                        $localBacklogData[$itemCounter] | Add-Member -NotePropertyName "GEN_Relation" -NotePropertyValue ''
                    }
                    $localBacklogData[$itemCounter]."GEN_Relation" = 'Child'
                }
                $relationString += "-[_{0}_]-{1}={2}" -f $localBacklogData[$itemCounter]."GEN_Relation", $localBacklogData[$itemCounter].'Work Item Type', $localBacklogData[$itemCounter].title

                $localBacklogData[$itemCounter].$relationStringProperty = $relationString
            }
        }
    }
    else {
        Write-Verbose "No item hierarchy found in provided data file"

        foreach ($backlogItem in $localBacklogData) {
            if (($backlogItem | Get-Member -MemberType "NoteProperty" ).Name -notcontains $relationStringProperty) {
                $backlogItem | Add-Member -NotePropertyName $relationStringProperty -NotePropertyValue ''
            }
            $backlogItem.$relationStringProperty = '{0}={1}' -f $backlogItem.'Work Item Type', $backlogItem.title
        }
    }
}