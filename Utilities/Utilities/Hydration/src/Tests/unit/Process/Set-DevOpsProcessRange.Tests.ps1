# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] Set-DevOpsProcessRange" -Tag Build {

        It "Should update process range as expected" {

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*contoso*" -and
                (ConvertFrom-Json $body).Description -eq 'Some Description'
            } -Verifiable

            $inputObject = @{
                Organization      = 'contoso'
                processesToUpdate = @{
                    Id            = 1
                    Name          = 'Process 2'
                    parentProcess = 'Agile'
                    Description   = 'Some Description'
                }
            }
            { Set-DevOpsProcessRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}