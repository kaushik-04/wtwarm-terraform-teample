# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] Get-DevOpsProcessPropertiesToUpdate" -Tag Build {

        $testcases = @(
            @{
                localProcess  = @{
                    Id          = '1234'
                    Description = 'DescriptionA'
                }
                remoteProcess = @{
                    Id          = '1234'
                    Description = 'ChangedDescription'
                }
                expected      = @('Description')
            }
            @{
                localProcess  = @{
                    Id          = '1234'
                    Description = 'DescriptionA'
                }
                remoteProcess = @{
                    Id          = '1234'
                    Description = 'DescriptionA'
                }
                expected      = @()
            }
        )
        It "Should check process properties" -TestCases $testcases {
            param (
                $localProcess,
                $remoteProcess,
                $expected
            )
            $foundItems = Get-DevOpsProcessPropertiesToUpdate -localProcess $localProcess -remoteProcess $remoteProcess

            $expected.Count | Should -Be $foundItems.Count
            foreach ($expectedElem in $expected) {
                $foundItems | Should -Contain $expectedElem
            }
        }
    }
}
