# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] Remove-DevOpsProcessWorkItemTypeStateRange" -Tag Build {

        It "Should remove work item type state as expected" {

            $organization = 'contoso'

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*$organization*1*MyProcess.myBacklogLevel*99*" } -Verifiable

            $inputObject = @{
                Organization               = $organization
                workItemTypeStatesToRemove = @(
                    @{
                        name = "myState"
                        id   = 99
                    }
                )
                workItemTypeReferenceName  = 'MyProcess.myBacklogLevel'
                process                    = @{
                    id   = 1
                    name = 'myProcess'
                }
            }
            { Remove-DevOpsProcessWorkItemTypeStateRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}