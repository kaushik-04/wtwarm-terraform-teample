# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] Remove-DevOpsProcessRange" -Tag Build {

        It "Should remove process as expected" {

            $organization = 'contoso'

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*$organization*1*" } -Verifiable

            $inputObject = @{
                Organization      = $organization
                processesToRemove = @(
                    @{
                        id            = 1
                        name          = "myBacklogLevel"
                        referenceName = 'MyProcess.myBacklogLevel'
                    }
                )
            }
            { Remove-DevOpsProcessRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}