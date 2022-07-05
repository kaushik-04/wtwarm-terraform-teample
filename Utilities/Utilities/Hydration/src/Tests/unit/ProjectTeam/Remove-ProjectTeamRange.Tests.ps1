# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] Remove-ProjectTeamRange" -Tag Build {

        $testcases = @(
            @{
                Organization  = "ADO-Hydration"
                Project       = "Module Playground"
                teamsToRemove = @(
                    @{
                        Id   = "Database Team"
                        Name = 'Database Team'
                    }
                )
            }
        )
        It "Should remove team" -TestCases $testcases {

            Mock Invoke-RESTCommand -ParameterFilter { $method -eq 'DELETE' -and $uri -like ("*{0}*" -f [uri]::EscapeDataString($teamsToRemove[0].identifier)) } -Verifiable

            $BoardArea = @{
                Organization  = $Organization
                Project       = $Project
                teamsToRemove = $teamsToRemove
            }
            { Remove-ProjectTeamRange @BoardArea -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}
