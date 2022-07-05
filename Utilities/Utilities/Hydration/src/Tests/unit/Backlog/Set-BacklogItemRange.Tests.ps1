# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

Describe "[Backlog] Test correct create/update path detection" -Tag Build {

    InModuleScope $ModuleName {

        It "Should update item if updates are indicated" {

            $localBacklogData = @(
                [PSCustomObject]@{
                    id                 = 1
                    title              = 'Test 3 - DummyTitle 1'
                    'Work Item Type'   = 'Epic'
                    GEN_relationString = 'Epic=Test 3 - DummyTitle 1'
                    GEN_PropertiesToUpdate = @('Title')
                },
                [PSCustomObject]@{
                    id                 = 2
                    title              = 'Test 3 - DummyTitle 2'
                    'Work Item Type'   = 'Feature'
                    GEN_relationString = 'Feature=Test 3 - DummyTitle 2'  
                    GEN_PropertiesToUpdate = @('Title')
                }
            )

            $commandBatchFilter = {
                $boardCommandList.count -eq 2 -and
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/1?api-version=6.0' -and $_.title -eq 'Test 3 - DummyTitle 1' }) -and # Update
                ($boardCommandList | Where-Object { $_.request.uri -eq '/_apis/wit/workitems/2?api-version=6.0' -and $_.title -eq 'Test 3 - DummyTitle 2' }) # Update
            }
            Mock Clear-BacklogItemCommandBatch -ParameterFilter $commandBatchFilter -Verifiable

            ##############
            # EXECUTION #
            ##############
            $inputParameters = @{
                workItemsToUpdate = $localBacklogData
                Organization      = 'contoso'
                DryRun            = $false
            }
            Set-BacklogItemRange @inputParameters

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}