# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Iteration] Get-IterationPropertiesToUpdate" -Tag Build {

        $testCases = @(
            @{
                localIteration     = @{
                    name       = 'Item A'
                    attributes = @{
                        startDate  = '2020-01-01'
                        finishDate = '2020-02-01'
                    }
                }
                remoteIteration    = @{
                    name       = 'Item B'
                    attributes = @{
                        startDate  = '2021-01-01'
                        finishDate = '2021-02-01'
                    }
                }
                expectedProperties = @('Name', 'startDate', 'finishDate')
            }
            @{
                localIteration     = @{
                    name       = 'Item A'
                    attributes = @{
                        startDate  = '2020-01-01'
                        finishDate = '2020-02-01'
                    }
                }
                remoteIteration    = @{
                    name = 'Item A'
                }
                expectedProperties = @('startDate', 'finishDate')
            },
            @{
                localIteration     = @{
                    id                 = 1
                    name               = 'Item A'
                    GEN_RelationString = 'Item A-[_Child_]-Item B'
                }
                remoteIteration    = @{
                    id                 = 1
                    name               = 'Item B'
                    GEN_RelationString = 'Item A-[_Child_]-Item C'
                }
                expectedProperties = @('name', 'GEN_RelationString')
            }
        )

        It "Should detect expected changes: [<expectedProperties>]" -TestCases $testCases {
            
            param (
                [PSCustomObject] $localIteration,
                [PSCustomObject] $remoteIteration,
                [string[]] $expectedProperties
            )

            $foundProperties = Get-IterationPropertiesToUpdate -localIteration $localIteration -remoteIteration $remoteIteration

            foreach ($expectedProperty in $expectedProperties) {
                $foundProperties | Should -Contain $expectedProperty
            }
        }

    }
}