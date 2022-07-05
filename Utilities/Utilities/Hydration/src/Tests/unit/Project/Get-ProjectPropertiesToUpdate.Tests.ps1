# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Project] Get-ProjectPropertiesToUpdate tests" -Tag Build {

        $testcases = @(
            @{
                localProject  = @{
                    Id          = '1234'
                    Name        = 'titleA'
                    Description = 'descriptionA'
                    Visibility  = 'private'
                }
                remoteProject = @{
                    Id            = '1234'
                    Name          = 'titleA'
                    Description   = 'descriptionA'
                    Visibility    = 'private'
                    somethingElse = 'somethingElse'
                }
                expected      = @()
            },
            @{
                localProject  = @{
                    Id          = '1234'
                    Name        = 'titleA'
                    Description = 'descriptionA'
                    Visibility  = 'private'
                }
                remoteProject = @{
                    Id            = '1234'
                    Name          = 'titleB'
                    Description   = 'descriptionA'
                    Visibility    = 'private'
                    somethingElse = 'somethingElse'
                }
                expected      = @('Name')
            },
            @{
                localProject  = @{
                    Id          = '1234'
                    Name        = 'titleA'
                    Visibility  = 'private'
                    Description = 'descriptionA'
                }
                remoteProject = @{
                    Id            = '1234'
                    Name          = 'titleB'
                    Description   = 'descriptionB'
                    Visibility    = 'public'
                    somethingElse = 'somethingElse'
                }
                expected      = @('Name', 'Description', 'Visibility')
            }
        )
        It "Should check project properties" -TestCases $testcases {
            param (
                $localProject,
                $remoteProject,
                $expected
            )
            $foundItems = Get-ProjectPropertiesToUpdate -localProject $localProject -remoteProject $remoteProject

            $expected.Count | Should -Be $foundItems.Count
            foreach ($expectedElem in $expected) {
                $foundItems | Should -Contain $expectedElem
            }
        }
    }
}
