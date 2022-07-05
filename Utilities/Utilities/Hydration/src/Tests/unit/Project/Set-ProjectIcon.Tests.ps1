# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Project] Set-ProjectIcon tests" -Tag Build {

        It "Should update project icon" {

            Mock Invoke-RESTCommand -ParameterFilter { $body -like "*image*" } -Verifiable

            $testInputObject = @{
                Organization = "contoso"
                project      = @{
                    Id   = "11111111-9999-9999-9999-999999999999"
                    Name = "Test Module"
                }
                iconPath     = Join-Path $PSScriptRoot 'resources\mslogo.jpeg'
            }
            { Set-ProjectIcon @testInputObject } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should throw if path not existing" {

            $testInputObject = @{
                Organization = "contoso"
                project      = @{
                    Id   = "11111111-9999-9999-9999-999999999999"
                    Name = "Test Module"
                }
                iconPath     = 'Non-existend.png'
            }
            { Set-ProjectIcon @testInputObject -ErrorAction 'Stop' } | Should -Throw
        }
    }
}
