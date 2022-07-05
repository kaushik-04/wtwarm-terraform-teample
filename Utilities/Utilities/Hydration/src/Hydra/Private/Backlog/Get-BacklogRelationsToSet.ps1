<#
.SYNOPSIS
Given the local and remote backlog data get the set of relations to set

.DESCRIPTION
Given the local and remote backlog data get the set of relations to set

.PARAMETER localBacklogRelations
Optional. The local backlog data to use for the evaluation

.PARAMETER remoteBacklogRelations
Optional. The remote backlog data to use for the evaluation

.EXAMPLE
Get-BacklogRelationsToSet -localBacklogRelations @(@{ sourceItem = @{ id = 1 }; targetItem = @{ id = 2 }; relationType = 'Child' }) -remoteBacklogRelations @(@{ sourceItem = @{ id = 10 }; targetItem = @{ id = 11 }; relationType = 'Child' })

Get the [set] of relations that are missing in the remote data. Would conclude that the provided local item is missing in the remote data.
#>
function Get-BacklogRelationsToSet {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $false)]
        [PSCustomObject[]] $localBacklogRelations = @(),

        [Parameter(Mandatory = $false)]
        [PSCustomObject[]] $remoteBacklogRelations = @()
    )


    # Prepare data for analysis
    $localBacklogRelationsSimplified = $localBacklogRelations | Foreach-Object {
        [PSCustomObject]@{
            SourceItemId = $_.sourceItem.Id
            TargetItemId = $_.targetItem.Id
            RelationType = $_.relationType
        }
    }

    $remoteBacklogRelationsSimplified = $remoteBacklogRelations | Foreach-Object {
        [PSCustomObject]@{
            SourceItemId = $_.sourceItem.Id
            TargetItemId = $_.targetItem.Id
            RelationType = $_.relationType
        }
    }

    # Evaluate Relations to create
    # ----------------------------
    $relationsToSet = [System.Collections.ArrayList]@()
    foreach ($expectedRelation in $localBacklogRelationsSimplified) {

        $notYetExisting = -not $remoteBacklogRelationsSimplified -or -not (Confirm-RelationContained -listToCheck $remoteBacklogRelationsSimplified -itemToCompare $expectedRelation)
        $notYetCovered = -not (Confirm-RelationContained -listToCheck $relationsToSet -itemToCompare $expectedRelation)
        if ($notYetExisting -and $notYetCovered) {

            $matchingDetailedItem = $localBacklogRelations | Where-Object {
                $_.sourceItem.Id -eq $expectedRelation.SourceItemId -and
                $_.targetItem.Id -eq $expectedRelation.targetItemId -and
                $_.relationType -eq $expectedRelation.relationType
            }

            $null = $relationsToSet.Add(
                [PSCustomObject]@{
                    SourceItem   = $matchingDetailedItem.sourceItem
                    TargetItem   = $matchingDetailedItem.targetItem
                    RelationType = $expectedRelation.relationType
                }
            )
        }
    }
    return $relationsToSet
}