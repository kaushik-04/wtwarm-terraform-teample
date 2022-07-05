# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] Get-ProjectTeamPropertiesToUpdate" -Tag Build {

        $testcases = @(
            @{
                localTeam  = @{
                    Id          = '1234'
                    Name        = 'titleA'
                    Description = 'descriptionA'
                }
                remoteTeam = @{
                    Id            = '1234'
                    Name          = 'titleA'
                    Description   = 'descriptionA'
                    somethingElse = 'somethingElse'
                }
                expected   = @()
            },
            @{
                localTeam  = @{
                    Id          = '1234'
                    Name        = 'titleA'
                    Description = 'descriptionA'
                }
                remoteTeam = @{
                    Id            = '1234'
                    Name          = 'titleB'
                    Description   = 'descriptionA'
                    somethingElse = 'somethingElse'
                }
                expected   = @('Name')
            },
            @{
                localTeam  = @{
                    Id          = '1234'
                    Name        = 'titleA'
                    Description = 'descriptionA'
                }
                remoteTeam = @{
                    Id            = '1234'
                    Name          = 'titleB'
                    Description   = 'descriptionB'
                    somethingElse = 'somethingElse'
                }
                expected   = @('Name', 'Description')
            }
        )
        It "Should find team properties to update" -TestCases $testcases {
            param (
                $localTeam,
                $remoteTeam,
                $expected
            )
            $foundItems = Get-ProjectTeamPropertiesToUpdate -localTeam $localTeam -remoteTeam $remoteTeam

            $expected.Count | Should -Be $foundItems.Count
            foreach($expectedElem in $expected) {
                $foundItems | Should -Contain $expectedElem
            }
        }
    }
}
