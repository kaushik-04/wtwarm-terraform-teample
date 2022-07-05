# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

Describe "[Backlog] Relation Tuples should be correctly detected" -Tag Unit {

    InModuleScope $ModuleName {

        # Load data
        $configuredlocalBacklogDataPath = Join-Path $PSScriptRoot 'resources\GetRelationTupleList.csv'
        $configuredlocalBacklogData = Import-BacklogCompatibleCSV $configuredlocalBacklogDataPath

        # Generate strings
        $tuples = Get-BacklogItemLocalRelationTupleList -localBacklogData $configuredlocalBacklogData

        $testCases = @(
            @{ tuples = $tuples; expected = 12 }
        )

        It "Should identify the correct number of relation tuples [<expected>]" -TestCases $testCases {

            param (
                [PSCustomObject[]] $tuples,
                [int] $expected
            )
            $tuples.Count | Should -Be $expected
        }

        $testCases = @(
            @{
                tuples               = $tuples
                expectedSourceItemId = 'f11'
                expectedTargetItemId = 'e1'
                expectedRelationType = 'Child'
            },
            @{
                tuples               = $tuples
                expectedSourceItemId = 'f12'
                expectedTargetItemId = 'e1'
                expectedRelationType = 'Child'
            },
            @{
                tuples               = $tuples
                expectedSourceItemId = 'f13'
                expectedTargetItemId = 'e1'
                expectedRelationType = 'Child'
            },
            @{
                tuples               = $tuples
                expectedSourceItemId = 'f14'
                expectedTargetItemId = 'e1'
                expectedRelationType = 'Child'
            },
            @{
                tuples               = $tuples
                expectedSourceItemId = 'u11'
                expectedTargetItemId = 'e1'
                expectedRelationType = 'Child'
            },
            @{
                tuples               = $tuples
                expectedSourceItemId = 'u111'
                expectedTargetItemId = 'u11'
                expectedRelationType = 'Child'
            },
            @{
                tuples               = $tuples
                expectedSourceItemId = 'u112'
                expectedTargetItemId = 'u11'
                expectedRelationType = 'Child'
            },
            @{
                tuples               = $tuples
                expectedSourceItemId = 'f21'
                expectedTargetItemId = 'e2'
                expectedRelationType = 'Child'
            },
            @{
                tuples               = $tuples
                expectedSourceItemId = 'f22'
                expectedTargetItemId = 'e2'
                expectedRelationType = 'Child'
            },
            @{
                tuples               = $tuples
                expectedSourceItemId = 'f23'
                expectedTargetItemId = 'e2'
                expectedRelationType = 'Child'
            },
            @{
                tuples               = $tuples
                expectedSourceItemId = 'u231'
                expectedTargetItemId = 'f23'
                expectedRelationType = 'Child'
            },
            @{
                tuples               = $tuples
                expectedSourceItemId = 'f24'
                expectedTargetItemId = 'e2'
                expectedRelationType = 'Child'
            }
        )

        It "Should identify relation tuple [<expectedSourceItemId>|<expectedRelationType>|<expectedTargetItemId>]" -TestCases $testCases {

            param (
                [PSCustomObject[]] $tuples,
                [string] $expectedSourceItemId,
                [string] $expectedTargetItemId,
                [string] $expectedRelationType
            )
            ($tuples | Where-Object {
                    $_.sourceItem.Id -eq $expectedSourceItemId -and
                    $_.targetItem.Id -eq $expectedTargetItemId -and
                    $_.relationType -eq $expectedRelationType
                }) | Should -Not -BeNullOrEmpty
        }

    }
}
