# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] New-DevOpsProcessWorkItemTypeRange" -Tag Build {

        It "Should create work item types with all properties" {

            $organization = "contoso"
            $processid = 0

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*$organization*$processId*" -and
                (ConvertFrom-Json $body).name -eq 'someWorkItemType' -and
                (ConvertFrom-Json $body).Color -eq 'eeeeee' -and
                (ConvertFrom-Json $body).Description -eq 'Some description' -and
                (ConvertFrom-Json $body).Icon -eq 'custom_icon'
            } -MockWith { return @{ referenceName = 'MyProcess.someWorkItemType' } } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*$organization*$processId*MyProcess.someWorkItemType*" -and
                (ConvertFrom-Json $body).behavior.id -eq 'MyProcess.SomeLevel' -and
                (ConvertFrom-Json $body).isDefault -eq $true
            } -Verifiable

            $inputObject = @{
                organization          = $organization
                process               = @{
                    id   = $processid
                    name = 'MyProcess'
                }
                workitemtypesToCreate = @(
                    @{
                        name        = 'someWorkItemType'
                        Color       = 'eeeeee'
                        Icon        = 'custom_icon'
                        Description = 'Some description'
                        behavior    = [PSCustomObject](@{
                                assignedBacklogLevel = 'SomeLevel'
                                isDefault            = $true
                            })
                    }
                )
                remoteBacklogLevels   = @(
                    @{
                        Name          = 'SomeLevel'
                        referenceName = 'MyProcess.SomeLevel'
                    }
                )
            }
            { New-DevOpsProcessWorkItemTypeRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}