# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

Describe "[Backlog] Test correct id identification logic" -Tag Unit {

    InModuleScope $ModuleName {

        It "Should match by id" {

            $localBacklogData = @(
                [PSCustomObject]@{
                    id                 = 1
                    GEN_relationString = 'Epic=Test 1 - DummyTitle 1'
                },
                [PSCustomObject]@{
                    id                 = 2
                    GEN_relationString = 'Feature=Test 1 - DummyTitle 2'
                }
            )
            $remoteBacklogData = @(
                [PSCustomObject]@{
                    id                 = 1
                    GEN_relationString = 'Epic=Test 1 - OtherTitle 1'
                },
                [PSCustomObject]@{
                    id                 = 2
                    GEN_relationString = 'Feature=Test 1 - OtherTitle 2'
                }
            )

            ##############
            # EXECUTION #
            ##############
            $inputParameters = @{
                localBacklogData  = $localBacklogData
                remoteBacklogData = $remoteBacklogData
            }
            Resolve-BacklogLocalItemId @inputParameters

            $localBacklogData[0].Id | Should -Be 1
            $localBacklogData[1].Id | Should -Be 2
        }

        It "Detect item by relation string" {

            $localBacklogData = @(
                [PSCustomObject]@{
                    GEN_relationString = 'Epic=Test 1 - DummyTitle 1'
                },
                [PSCustomObject]@{
                    GEN_relationString = 'Feature=Test 1 - DummyTitle 2'
                }
            )
            $remoteBacklogData = @(
                [PSCustomObject]@{
                    id                 = 1
                    GEN_relationString = 'Epic=Test 1 - DummyTitle 1'
                },
                [PSCustomObject]@{
                    id                 = 2
                    GEN_relationString = 'Feature=Test 1 - DummyTitle 2'
                }
            )

            ##############
            # EXECUTION #
            ##############
            $inputParameters = @{
                localBacklogData  = $localBacklogData
                remoteBacklogData = $remoteBacklogData
            }
            Resolve-BacklogLocalItemId @inputParameters

            $localBacklogData[0].Id | Should -Be 1
            $localBacklogData[1].Id | Should -Be 2
        }
    }
}