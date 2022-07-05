# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] Set-DevOpsProcessBacklogLevelRange" -Tag Build {

        It "Should update backlog level as expected" {

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*contoso*123*someref*" -and
                (ConvertFrom-Json $body).Name -eq 'BacklogLevel1' -and
                (ConvertFrom-Json $body).Color -eq 'eeeeee'
            } -MockWith { return @{ name = 'BacklogLevel1' } } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*contoso*123*someref2*" -and
                (ConvertFrom-Json $body).Name -eq 'BacklogLevel2' -and
                (ConvertFrom-Json $body).Color -eq '000000'
            } -MockWith { return @{ name = 'BacklogLevel2' } } -Verifiable

            $inputObject = @{
                organization          = "contoso"
                process               = @{
                    id   = '123'
                    name = 'MyProcess'
                }
                backlogLevelsToUpdate = @(
                    @{
                        Name          = 'BacklogLevel1'
                        Color         = 'eeeeee'
                        referenceName = 'someref'
                    },
                    @{
                        Name          = 'BacklogLevel2'
                        Color         = '000000'
                        referenceName = 'someref2'
                    }
                )
            }
            { Set-DevOpsProcessBacklogLevelRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}