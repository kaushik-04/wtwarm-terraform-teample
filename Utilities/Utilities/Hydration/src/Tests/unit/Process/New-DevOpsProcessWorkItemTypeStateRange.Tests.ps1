# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] New-DevOpsProcessWorkItemTypeStateRange" -Tag Build {

        It "Should create work item types with all properties" {

            $workItemTypeReferenceName = 'MyProgress.MyWorkItemType'
            $processId = 1
            $organization = "contoso"

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*$organization*$processId*$workItemTypeReferenceName*" -and
                (ConvertFrom-Json $body).name -eq 'myState' -and
                (ConvertFrom-Json $body).Color -eq 'eeeeee' -and
                (ConvertFrom-Json $body).stateCategory -eq 'Proposed'
            } -Verifiable

            $inputObject = @{
                organization               = $organization
                processId                  = $processId
                workItemTypeStatesToCreate = @(
                    @{
                        name          = 'myState'
                        Color         = 'eeeeee'
                        stateCategory = 'Proposed'
                    }
                )
                workItemTypeReferenceName  = $workItemTypeReferenceName
            }
            { New-DevOpsProcessWorkItemTypeStateRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}