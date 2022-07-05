# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] Set-DevOpsProcessWorkItemTypeRange" -Tag Build {

        It "Should update work item types as expected" {

            $organization = "contoso"
            $processid = 0

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*$organization*$processId*" -and
                (ConvertFrom-Json $body).Color -eq 'eeeeee' -and
                (ConvertFrom-Json $body).Icon -eq 'custom_icon' -and
                (ConvertFrom-Json $body).Description -eq 'Some description'
            } -MockWith { return @{ referenceName = 'MyProcess.someWorkItemType' } } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*$organization*$processId*MyProcess.someWorkItemType*" -and
                (ConvertFrom-Json $body).behavior.id -eq 'MyProcess.SomeLevel' -and
                (ConvertFrom-Json $body).isDefault -eq $true
            } -MockWith { return @{ referenceName = 'MyProcess.someWorkItemType' } } -Verifiable

            $inputObject = @{
                organization          = $organization
                process               = @{
                    id   = $processid
                    name = 'MyProcess'
                }
                workItemTypesToUpdate = @(
                    @{
                        name                       = 'someWorkItemType'
                        Color                      = 'eeeeee'
                        Icon                       = 'custom_icon'
                        Description                = 'Some description'
                        assignedBacklogLevel       = 'SomeLevel'
                        'AssignedBacklogLevel Ref' = 'MyProcess.SomeLevel'
                        isDefault                  = $true
                    }
                )
            }
            { Set-DevOpsProcessWorkItemTypeRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}