# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

Describe "[Backlog] Test Backlog Batch Item creation" -Tag Unit {

    InModuleScope $ModuleName {

        It "Create WorkItem should flush at 200" {

            # Work Item Create/Update Flush
            # -----------------------------
            Mock Clear-BacklogItemCommandBatch -ParameterFilter { $boardCommandList.count -eq 200 } -Verifiable

            $boardCommandList = [System.Collections.ArrayList]@()
            foreach ($index in @(1..201)) {
                $addItemInputObject = @{
                    boardCommandList = $boardCommandList
                    itemToProcess    = [PSCustomObject]@{
                        Title            = "Test 1 - Task $index"
                        'Work Item Type' = 'Task'
                    }
                    Organization     = 'contoso'
                    project          = 'Module Playground'
                    localBacklogData = @{}
                    total            = -1
                }
                Add-BacklogBatchCreateWorkItemRequest @addItemInputObject
            }

            ##############
            # EXECUTION #
            ##############
            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Create WorkItem should flush at duplicate item name if provided without id" {

            # Work Item Create/Update Flush
            # -----------------------------
            Mock Clear-BacklogItemCommandBatch -ParameterFilter { $boardCommandList.count -eq 1 } -Verifiable

            $boardCommandList = [System.Collections.ArrayList]@()

            $addItemInputObject = @{
                boardCommandList = $boardCommandList
                itemToProcess    = [PSCustomObject]@{
                    Title            = "Test 2 - Task 1"
                    'Work Item Type' = 'Task'
                }
                Organization     = 'contoso'
                project          = 'Module Playground'
                localBacklogData = @{}
                total            = -1
            }
            Add-BacklogBatchCreateWorkItemRequest @addItemInputObject

            Add-BacklogBatchCreateWorkItemRequest @addItemInputObject

            ##############
            # EXECUTION #
            ##############
            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Create WorkItem should not flush at duplicate item name if provided with id" {

            # Work Item Create/Update Flush
            # -----------------------------
            Mock Clear-BacklogItemCommandBatch -ParameterFilter { $boardCommandList.count -eq 6 } -Verifiable

            $boardCommandList = [System.Collections.ArrayList]@()

            $addItemInputObject = @{
                boardCommandList = $boardCommandList
                itemToProcess    = [PSCustomObject]@{
                    Title            = "Test 3 - Task 1"
                    'Work Item Type' = 'Task'
                }
                Organization     = 'contoso'
                project          = 'Module Playground'
                localBacklogData = @{}
                total            = -1
            }
            Add-BacklogBatchCreateWorkItemRequest @addItemInputObject

            foreach ($index in @(1..5)) {
                $addItemInputObject = @{
                    boardCommandList = $boardCommandList
                    itemToProcess    = [PSCustomObject]@{
                        Id               = $index
                        Title            = "Test 3 - Task $index"
                        'Work Item Type' = 'Task'

                    }
                    Organization     = 'contoso'
                    total            = -1
                }
                Add-BacklogBatchUpdateWorkItemRequest @addItemInputObject
            }
            Clear-BacklogItemCommandBatch -boardCommandList $boardCommandList -localBacklogData @{} -Organization 'contoso'


            ##############
            # EXECUTION #
            ##############
            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}