# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

<#
Data in CSV (configured) vs JSON (deployed)

```mermaid
flowchart BT;
307 -- Child --> 306
311 -- Child --> 306
313 -- Child --> 306
309 -. Removed:Related .- 306
309 -- Added:Child --> 306
315 -. Removed:Related .- 306
307 -. Removed:Related .- 310
315 -. Related .- 312
314 -- Child --> 312
316 -- Child --> 312
310 -- Child --> 315
308 -- Child --> 312
314 -. Added:Related .- 316
308 -. Added:Related .- 316
```
#>

Describe "[Backlog] Test correct missing & excess relation detection" -Tag Unit {

    InModuleScope $ModuleName {

        # Load data
        $diveringDeployedDataPath = Join-Path $PSScriptRoot 'resources\MeasureRelationRemote.json'
        $diveringDeployedData = ConvertFrom-Json (Get-Content -Path $diveringDeployedDataPath -Raw)
        $diveringDeployedDataFormatted = Get-BacklogItemRemoteRelationTupleList -remoteBacklogData $diveringDeployedData  | Where-Object { $_.relationType -eq 'Child' }

        $configuredlocalBacklogDataPath = Join-Path $PSScriptRoot 'resources\MeasureRelationLocal.csv'
        $configuredlocalBacklogData = Import-BacklogCompatibleCSV $configuredlocalBacklogDataPath
        $configuredlocalBacklogDataFormatted = Get-BacklogItemLocalRelationTupleList -localBacklogData $configuredlocalBacklogData

        ################
        # REMOVE TESTS #
        ################

        $inputParameters = @{
            localBacklogRelations  = $configuredlocalBacklogDataFormatted
            remoteBacklogRelations = $diveringDeployedDataFormatted
        }
        $relationsToRemove = Get-BacklogRelationsToRemove @inputParameters


        $removeCountTestCases = @(
            @{
                foundRelationsToRemove = $relationsToRemove
                expected               = 1
            }
        )
        It "Should identify the correct number of relations to remove" -TestCases $removeCountTestCases {

            param(
                [PSCustomObject[]] $foundRelationsToRemove,
                [int] $expected
            )

            $foundRelationsToRemove.Count | Should -Be $expected
        }

        $removeTestCases = @(
            @{
                SourceItemId           = 200
                targetItemId           = 110
                RelationType           = 'Child'
                foundRelationsToRemove = $relationsToRemove
            }
        )
        It "to remove" -TestCases $removeTestCases {

            param(
                [int] $SourceItemId,
                [int] $targetItemId,
                [string] $relationType,
                [PSCustomObject[]] $foundRelationsToRemove
            )

            ($foundRelationsToRemove | Where-Object { $_.SourceItem.Id -eq $SourceItemId -and $_.targetItem.Id -eq $targetItemId -and $_.RelationType -eq $relationType }).Count | Should -Be 1
        }
    }
}
