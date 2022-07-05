# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] Remove-DevOpsProcessBacklogLevelRange" -Tag Build {

        It "Should remove backlog level as expected" {

            $organization = 'contoso'

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*$organization*1*MyProcess.myBacklogLevel*" } -Verifiable

            $inputObject = @{
                Organization          = $organization
                process               = @{
                    id   = 1
                    name = 'MyProcess'
                }
                backlogLevelsToRemove = @{
                    name          = "myBacklogLevel"
                    referenceName = 'MyProcess.myBacklogLevel'
                }
            }
            { Remove-DevOpsProcessBacklogLevelRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}