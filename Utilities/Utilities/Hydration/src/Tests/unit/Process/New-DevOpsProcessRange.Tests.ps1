# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] New-DevOpsProcessRange" -Tag Build {

        It "Should create process backlog level with process name & all properties" {

            Mock Get-DevOpsProcessList -MockWith { return @{ Name = 'Agile'; id = '1111' } } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*contoso*" -and
                (ConvertFrom-Json $body).name -eq 'Process 2' -and
                (ConvertFrom-Json $body).parentProcessTypeId -eq '1111' -and
                (ConvertFrom-Json $body).Description -eq 'Some description'
            } -Verifiable

            $inputObject = @{
                Organization      = 'contoso'
                processesToCreate = @{
                    Name          = 'Process 2'
                    parentProcess = 'Agile'
                    Description   = 'Some Description'
                }
            }
            { New-DevOpsProcessRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should create process backlog level with custom process id" {

            param(
                [string] $organization,
                [PSCustomObject[]] $processesToCreate
            )

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*contoso*" -and
                (ConvertFrom-Json $body).name -eq 'Process 1' -and
                (ConvertFrom-Json $body).parentProcessTypeId -eq '6115283a-d3ef-4143-b40f-cac143f99af2'
            } -Verifiable

            $inputObject = @{
                Organization      = 'contoso'
                processesToCreate = @{
                    Name          = 'Process 1'
                    parentProcess = '6115283a-d3ef-4143-b40f-cac143f99af2'
                }
            }
            { New-DevOpsProcessRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}