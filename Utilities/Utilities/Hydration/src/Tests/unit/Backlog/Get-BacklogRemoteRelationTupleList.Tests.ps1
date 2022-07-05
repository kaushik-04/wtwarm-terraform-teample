# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {

    # Overwrite private function as Mocks only work in test cases
    function Get-BacklogItemsCreated {
        $relationDataPath = Join-Path $PSScriptRoot 'resources\GetRemoteRelationTupleList.json'
        return  ConvertFrom-Json (Get-Content -Path $relationDataPath -Raw)
    }

    Describe "[Backlog] Test Relation Item Format" -Tag Unit {

        $relationDataPath = Join-Path $PSScriptRoot 'resources\GetRemoteRelationTupleList.json'
        $relationData = ConvertFrom-Json (Get-Content -Path $relationDataPath -Raw)
        $res = Get-BacklogItemRemoteRelationTupleList -remoteBacklogData $relationData

        $numberTestCase = @(
            @{result = $res; expected = 18 }
        )
        It "Should find the correct number of relations" -TestCases $numberTestCase {
            param(
                [PSCustomObject[]] $result,
                [int] $expected
            )
            $result.Count | Should -Be $expected
        }

        $testCases = @(
            @{ sourceItem = 140; targetItem = 241; RelationType = 'Related'; result = $res },
            @{ sourceItem = 110; targetItem = 100; RelationType = 'Related'; result = $res },

            @{ sourceItem = 120; targetItem = 100; RelationType = 'Child'; result = $res },
            @{ sourceItem = 130; targetItem = 100; RelationType = 'Child'; result = $res },
            @{ sourceItem = 140; targetItem = 100; RelationType = 'Child'; result = $res },
            @{ sourceItem = 210; targetItem = 200; RelationType = 'Child'; result = $res },
            @{ sourceItem = 241; targetItem = 240; RelationType = 'Child'; result = $res },
            @{ sourceItem = 220; targetItem = 200; RelationType = 'Child'; result = $res },
            @{ sourceItem = 230; targetItem = 200; RelationType = 'Child'; result = $res },
            @{ sourceItem = 240; targetItem = 200; RelationType = 'Child'; result = $res },

            @{ sourceItem = 100; targetItem = 120; RelationType = 'Parent'; result = $res },
            @{ sourceItem = 100; targetItem = 130; RelationType = 'Parent'; result = $res },
            @{ sourceItem = 100; targetItem = 140; RelationType = 'Parent'; result = $res },
            @{ sourceItem = 200; targetItem = 210; RelationType = 'Parent'; result = $res },
            @{ sourceItem = 240; targetItem = 241; RelationType = 'Parent'; result = $res },
            @{ sourceItem = 200; targetItem = 220; RelationType = 'Parent'; result = $res },
            @{ sourceItem = 200; targetItem = 230; RelationType = 'Parent'; result = $res },
            @{ sourceItem = 200; targetItem = 240; RelationType = 'Parent'; result = $res }
        )

        It "Should detect [<sourceitem>|<relationtype>|<targetItem>]" -TestCases $testCases {

            param (
                [int] $sourceItem,
                [int] $targetItem,
                [string] $relationType,
                [PSCustomObject[]] $results
            )
            $found = $results | Where-Object { $_.sourceItem.Id -eq $sourceItem -and $_.targetItem.Id -eq $targetItem -and $_.relationType -eq $relationType }
            $found.Count | Should -Be 1
        }
    }
}