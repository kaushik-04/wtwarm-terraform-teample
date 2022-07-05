# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] Set-DevOpsProcessWorkItemTypeStateRange" -Tag Build {

        It "Should update work item type states as expected" {

            $workItemTypeReferenceName = 'MyProgress.MyWorkItemType'
            $processId = 1
            $stateId = 9
            $organization = "contoso"

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*$organization*$processId*$workItemTypeReferenceName*$stateId*" -and
                (ConvertFrom-Json $body).name -eq 'myState' -and
                (ConvertFrom-Json $body).Color -eq 'eeeeee' -and
                (ConvertFrom-Json $body).stateCategory -eq 'Proposed'
            } -Verifiable

            $inputObject = @{
                organization              = $organization
                process                   = @{
                    name = 'myProgress'
                    id   = $processId
                }
                statesToUpdate            = @(
                    @{
                        id            = $stateId
                        name          = 'myState'
                        Color         = 'eeeeee'
                        stateCategory = 'Proposed'
                    }
                )
                workItemTypeReferenceName = $workItemTypeReferenceName
            }
            { Set-DevOpsProcessWorkItemTypeStateRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}