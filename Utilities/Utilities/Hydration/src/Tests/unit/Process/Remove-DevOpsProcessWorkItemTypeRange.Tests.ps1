# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] Remove-DevOpsProcessWorkItemTypeRange" -Tag Build {

        It "Should remove process as expected" {

            $organization = 'contoso'

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*$organization*1*MyProcess.myBacklogLevel*" } -Verifiable

            $inputObject = @{
                Organization      = $organization
                workItemTypesToRemove = @(
                    @{
                        name          = "myBacklogLevel"
                        referenceName = 'MyProcess.myBacklogLevel'
                    }
                )
                process = @{
                    id = 1
                    name = 'myProcess'
                }
            }
            { Remove-DevOpsProcessWorkItemTypeRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}