# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] Get-DevOpsProcessBacklogLevelPropertiesToUpdate" -Tag Build {

        $testcases = @(
            @{
                localBacklogLevel  = @{
                    Id          = '1234'
                    Color        = 'eeeeeee'
                }
                remoteBacklogLevel = @{
                    Id            = '1234'
                    Color        = '000000'
                }
                expected   = @('Color')
            }
            @{
                localBacklogLevel  = @{
                    Id          = '1234'
                    Color        = 'eeeeeee'
                }
                remoteBacklogLevel = @{
                    Id            = '1234'
                    Color        = 'eeeeeee'
                }
                expected   = @()
            }
        )
        It "Should check backlog level properties" -TestCases $testcases {
            param (
                $localBacklogLevel,
                $remoteBacklogLevel,
                $expected
            )
            $foundItems = Get-DevOpsProcessBacklogLevelPropertiesToUpdate -localBacklogLevel $localBacklogLevel -remoteBacklogLevel $remoteBacklogLevel

            $expected.Count | Should -Be $foundItems.Count
            foreach($expectedElem in $expected) {
                $foundItems | Should -Contain $expectedElem
            }
        }
    }
}
