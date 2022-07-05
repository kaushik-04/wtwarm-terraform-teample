# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] Get-DevOpsProcessWorkItemTypePropertiesToUpdate" -Tag Build {

        $testcases = @(
            @{
                localWorkItemType  = @{
                    Id          = '1234'
                    Color       = 'eeeeee'
                    Icon        = 'some_icon'
                    Description = 'DescriptionA'
                }
                remoteWorkItemType = @{
                    Id          = '1234'
                    Color       = '0000'
                    Icon        = 'another_icon'
                    Description = 'ChangedDescription'
                }
                expected           = @('Color','Icon','Description')
            }
            @{
                localWorkItemType  = @{
                    Id          = '1234'
                    Color       = 'eeeeee'
                    Icon        = 'some_icon'
                    Description = 'DescriptionA'
                }
                remoteWorkItemType = @{
                    Id          = '1234'
                    Color       = 'eeeeee'
                    Icon        = 'some_icon'
                    Description = 'DescriptionA'
                }
                expected           = @()
            }
        )
        It "Should check work item type properties" -TestCases $testcases {
            param (
                $localWorkItemType,
                $remoteWorkItemType,
                $expected
            )
            $foundItems = Get-DevOpsProcessWorkItemTypePropertiesToUpdate -localWorkItemType $localWorkItemType -remoteWorkItemType $remoteWorkItemType

            $expected.Count | Should -Be $foundItems.Count
            foreach ($expectedElem in $expected) {
                $foundItems | Should -Contain $expectedElem
            }
        }
    }
}
