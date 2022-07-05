# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Repository] Remove-Repository" -Tag Build {

        $testcases = @(
            @{
                Organization  = "Contoso"
                Project       = "ADO-project"
                ReposToRemove = @(
                    @{
                        id = "9999-99999-99999-9999"
                    }
                )
            }
        )
        It "Should remove Repo" -TestCases $testcases {

            Mock Invoke-RESTCommand -ParameterFilter { $method -eq 'DELETE' -and $uri -like ("*{0}*" -f [uri]::EscapeDataString($ReposToRemove[0].identifier)) } -Verifiable

            $Repository = @{
                Organization  = $Organization
                Project       = $Project
                reposToRemove = $ReposToRemove
            }
            { Remove-Repo @Repository -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}
