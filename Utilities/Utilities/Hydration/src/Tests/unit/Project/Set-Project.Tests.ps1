# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Project] Set-Project tests" -Tag Build {

        $testcases = @(
            @{
                Organization     = "contoso"
                projectsToUpdate = @{
                    Id  = "11111111-9999-9999-9999-999999999999"
                    Description = "Module Playground description"
                }
            }
        )

        It "Should update Project description" -TestCases $testcases {

            param(
                [string] $Organization,
                [PSCustomObject[]] $projectsToUpdate
            )

            Mock Invoke-RESTCommand -ParameterFilter {
                (ConvertFrom-Json $body).Id -eq $projectsToUpdate[0].Id -and
                (ConvertFrom-Json $body).description -eq $projectsToUpdate[0].Description
            } -Verifiable

            $Project = @{
                Organization     = $Organization
                projectsToUpdate = $projectsToUpdate
            }
            { Set-Project @Project -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}
