# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

Describe "[Backlog] Test correct removal logic" -Tag Unit {

    InModuleScope $ModuleName {

        It "Should remove provided items" {

            $localBacklogData = @(
                [PSCustomObject]@{
                    id                 = 1
                    title              = 'Test 2 - DummyTitle 1'
                    'Work Item Type'   = 'Epic'
                    GEN_relationString = 'Epic=Test 2 - DummyTitle 1'
                },
                [PSCustomObject]@{
                    id                 = 3
                    title              = 'Test 2 - DummyTitle 1'
                    'Work Item Type'   = 'Feature'
                    GEN_relationString = 'Feature=Test 2 - DummyTitle 1'
                }
            )
            $remoteBacklogData = @(
                [PSCustomObject]@{
                    id                 = 1
                    fields             = @{
                        'System.Title'        = 'Test 2 - OtherTitle 1'
                        'System.WorkItemType' = 'Epic'
                    }
                    GEN_relationString = 'Epic=Test 2 - OtherTitle 1'
                },
                [PSCustomObject]@{
                    id                 = 2
                    fields             = @{
                        'System.Title'        = 'Test 2 - OtherTitle 2'
                        'System.WorkItemType' = 'Feature'
                    }
                    GEN_relationString = 'Feature=Test 2 - OtherTitle 2'
                }
            )

            $excessItems = $remoteBacklogData | Where-Object { $localBacklogData.Id -notcontains $_.Id }

            Mock Clear-BacklogItemCommandBatch -Verifiable

            ##############
            # EXECUTION #
            ##############
            $inputParameters = @{
                excessItems      = $excessItems
                Organization     = 'contoso'
                DryRun           = $false
            }
            Remove-BacklogItemExcess @inputParameters

            # No flush should be invoked
            Assert-MockCalled Clear-BacklogItemCommandBatch -Times 1
        }
    }
}