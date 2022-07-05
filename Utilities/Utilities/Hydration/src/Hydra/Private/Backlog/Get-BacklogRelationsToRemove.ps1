<#
.SYNOPSIS
Given the local and remote backlog data get the set of relations to remove

.DESCRIPTION
Given the local and remote backlog data get the set of relations to remove

.PARAMETER localBacklogRelations
Optional. The local backlog data to use for the evaluation

.PARAMETER remoteBacklogRelations
Optional. The remote backlog data to use for the evaluation

.EXAMPLE
Get-BacklogRelationsToRemove -localBacklogRelations @(@{ sourceItem = @{ id = 1 }; targetItem = @{ id = 2 }; relationType = 'Child' }) -remoteBacklogRelations @(@{ sourceItem = @{ id = 10 }; targetItem = @{ id = 11 }; relationType = 'Child' })

Get the [set] of relations that are missing in the remote data. Would conclude that the provided remote item has to be rmeoved as it is not locally defined.
#>
function Get-BacklogRelationsToRemove {

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

    # Evaluate Relations to remove
    # ----------------------------
    $relationsToRemove = [System.Collections.ArrayList]@()

    foreach ($remoteRelation in $remoteBacklogRelationsSimplified) {

        $notExpected = -not $localBacklogRelationsSimplified -or -not (Confirm-RelationContained -listToCheck $localBacklogRelationsSimplified -itemToCompare $remoteRelation)
        $notYetCovered = -not (Confirm-RelationContained -listToCheck $relationsToRemove -itemToCompare $remoteRelation)
        if ($notExpected -and $notYetCovered) {

            $matchingDetailedItem = $remoteBacklogRelations | Where-Object {
                $_.sourceItem.Id -eq $remoteRelation.SourceItemId -and
                $_.targetItem.Id -eq $remoteRelation.targetItemId -and
                $_.relationType -eq $remoteRelation.relationType
            }

            $null = $relationsToRemove.Add(
                [PSCustomObject]@{
                    SourceItem   = $matchingDetailedItem.sourceItem
                    TargetItem   = $matchingDetailedItem.targetItem
                    RelationType = $remoteRelation.relationType
                }
            )
        }
    }
    return $relationsToRemove
}