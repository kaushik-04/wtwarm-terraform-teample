# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] Get-DevOpsProcessWorkItemTypeStatePropertiesToUpdate" -Tag Build {

        $testcases = @(
            @{
                localState  = @{
                    Id            = '1234'
                    Color         = 'eeeeee'
                    StateCategory = 'Proposed'
                }
                remoteState = @{
                    Id            = '1234'
                    Color         = '0000'
                    StateCategory = 'InProgress'
                }
                expected    = @('Color', 'StateCategory')
            }
            @{
                localState  = @{
                    Id            = '1234'
                    Color         = 'eeeeee'
                    StateCategory = 'Completed'
                }
                remoteState = @{
                    Id            = '1234'
                    Color         = 'eeeeee'
                    StateCategory = 'Completed'
                }
                expected    = @()
            }
        )
        It "Should check work item type state properties" -TestCases $testcases {
            param (
                $localState,
                $remoteState,
                $expected
            )
            $foundItems = Get-DevOpsProcessWorkItemTypeStatePropertiesToUpdate -localState $localState -remoteState $remoteState

            $expected.Count | Should -Be $foundItems.Count
            foreach ($expectedElem in $expected) {
                $foundItems | Should -Contain $expectedElem
            }
        }
    }
}
