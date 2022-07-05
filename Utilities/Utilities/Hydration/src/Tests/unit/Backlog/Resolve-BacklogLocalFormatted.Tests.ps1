# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

# TODO: Add test wether the title is correctly identified

Describe "[Backlog] Relation Hierarchy should be correctly detected" -Tag Unit {

    InModuleScope $ModuleName {

        # Load data
        $configuredlocalBacklogDataPath = Join-Path $PSScriptRoot 'resources\ResolveLocalRelationString.csv'
        $configuredlocalBacklogData = Import-BacklogCompatibleCSV $configuredlocalBacklogDataPath

        # Generate strings
        Resolve-BacklogLocalFormatted -localBacklogData $configuredlocalBacklogData

        $testCases = @(
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString | Where-Object { -not [String]::IsNullOrEmpty($_) }; expected = 14 }
        )

        It "Should identify the correct number of relations [<expected>]" -TestCases $testCases {

            param (
                [string[]] $relationStrings,
                [int] $expected
            )
            $relationStrings.Count | Should -Be $expected
        }

        $testCases = @(
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 1' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 1-[_Child_]-Feature=Feature 11' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 1-[_Child_]-Feature=Feature 12' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 1-[_Child_]-Feature=Feature 13' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 1-[_Child_]-Feature=Feature 14' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 1-[_Child_]-User Story=User Story 11' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 1-[_Child_]-User Story=User Story 11-[_Child_]-User Story=User Story 111' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 1-[_Child_]-User Story=User Story 11-[_Child_]-User Story=User Story 112' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 2' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 2-[_Child_]-Feature=Feature 21' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 2-[_Child_]-Feature=Feature 22' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 2-[_Child_]-Feature=Feature 23' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 2-[_Child_]-Feature=Feature 23-[_Child_]-User Story=User Story 231' },
            @{ relationStrings = $configuredlocalBacklogData.GEN_RelationString; expected = 'Epic=Epic 2-[_Child_]-Feature=Feature 24' }
        )

        It "Should identify relation [<expected>]" -TestCases $testCases {

            param (
                [string[]] $relationStrings,
                [string] $expected
            )
            $relationStrings | Should -Contain $expected
        }

    }
}
