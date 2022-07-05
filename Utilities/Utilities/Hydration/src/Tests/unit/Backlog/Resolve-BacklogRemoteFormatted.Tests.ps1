# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

Describe "[Backlog] Relation Hierarchy should be correctly detected" -Tag Unit {

    InModuleScope $ModuleName {

        # Load data
        $remoteBacklogDataPath = Join-Path $PSScriptRoot 'resources\ResolveRemoteRelationString.json'
        $remoteBacklogData = ConvertFrom-Json (Get-Content -Path $remoteBacklogDataPath -Raw)

        # Generate strings
        Resolve-BacklogRemoteFormatted -remoteBacklogData $remoteBacklogData

        $testCases = @(
            @{ relationStrings = $remoteBacklogData.GEN_RelationString | Where-Object { -not [String]::IsNullOrEmpty($_) }; expected = $remoteBacklogData.Count }
        )

        It "Should identify all relation strings [<expected>]" -TestCases $testCases {

            param (
                [string[]] $relationStrings,
                [int] $expected
            )
            $relationStrings.Count | Should -Be $expected
        }

        $testCases = @(
            @{ relationStrings = $remoteBacklogData.GEN_RelationString; expected = 'Epic=Epic 100' },
            @{ relationStrings = $remoteBacklogData.GEN_RelationString; expected = 'Epic=Epic 100-[_Child_]-Feature=Feature 120' },
            @{ relationStrings = $remoteBacklogData.GEN_RelationString; expected = 'Epic=Epic 100-[_Child_]-Feature=Feature 120-[_Child_]-User Story=User Story 999' },
            @{ relationStrings = $remoteBacklogData.GEN_RelationString; expected = 'Epic=Epic 100-[_Child_]-Feature=Feature 130' },
            @{ relationStrings = $remoteBacklogData.GEN_RelationString; expected = 'Epic=Epic 100-[_Child_]-Feature=Feature 130-[_Child_]-User Story=User Story 888' },
            @{ relationStrings = $remoteBacklogData.GEN_RelationString; expected = 'Epic=Epic 100-[_Child_]-Feature=Feature 130-[_Child_]-User Story=User Story 999' },
            @{ relationStrings = $remoteBacklogData.GEN_RelationString; expected = 'Feature=Feature 110' },
            @{ relationStrings = $remoteBacklogData.GEN_RelationString; expected = 'Feature=Feature 110-[_Child_]-User Story=User Story 111' },
            @{ relationStrings = $remoteBacklogData.GEN_RelationString; expected = 'User Story=User Story 131' }
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