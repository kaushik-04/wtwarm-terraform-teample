# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Repository] New-Repository" -Tag Build {

        $testcases = @(
            @{
                Organization  = "Contoso"
                Project       = "ADO-project"
                ReposToCreate = @(
                    @{
                        Name = "Modules"
                    }
                )
            }
        )
        It "Should create new repository" -TestCases $testcases {

            Mock get-project -MockWith { ([pscustomobject]@{id = "5febef5a-833d-4e14-b9c0-14cb638f91e6" } ) } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { (ConvertFrom-Json $body).Name -eq $ReposToCreate[0].Name -and (ConvertFrom-Json $body).Project.id -eq '5febef5a-833d-4e14-b9c0-14cb638f91e6' } -Verifiable

            $Repository = @{
                Organization  = $Organization
                Project       = $Project
                ReposToCreate = $ReposToCreate
            }

            { New-Repository @Repository -ErrorAction 'Stop' } | Should -Not -Throw
            # All mocks should be invoked as defined
            Should -InvokeVerifiable

        }
    }
}
