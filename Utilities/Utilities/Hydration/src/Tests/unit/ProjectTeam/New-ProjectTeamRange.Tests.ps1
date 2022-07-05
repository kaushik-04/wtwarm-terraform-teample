# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] New-ProjectTeamRange" -Tag Build {

        $testcases = @(
            @{
                organization  = "ADO-Hydration"
                project       = "Module Playground"
                teamsToCreate = @{
                    Name        = "Database Team"
                    Description = "Database Team description."
                }
            }
        )
        It "Should create new Team with description" -TestCases $testcases {

            Mock Invoke-RESTCommand -ParameterFilter { (ConvertFrom-Json $body).Name -eq $teamsToCreate[0].Name -and (ConvertFrom-Json $body).Description -eq $teamsToCreate[0].Description } -Verifiable

            $Team = @{
                Organization  = $Organization
                Project       = $Project
                teamsToCreate = $teamsToCreate
            }
            { New-ProjectTeamRange @Team -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        $testcases = @(
            @{
                Organization  = "Contoso"
                Project       = "ADO-project"
                teamsToCreate = @{
                    Name = "Database Team"
                }
            }
        )
        It "Should create new Team without description" -TestCases $testcases {

            Mock Invoke-RESTCommand -ParameterFilter { (ConvertFrom-Json $body).Name -eq $teamsToCreate[0].Name } -Verifiable

            $Team = @{
                Organization  = $Organization
                Project       = $Project
                teamsToCreate = $teamsToCreate
            }
            { New-ProjectTeamRange @Team -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}