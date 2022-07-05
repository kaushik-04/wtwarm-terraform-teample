# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] Set-ProjectTeamRange" -Tag Build {

        $testcases1 = @(
            @{
                Organization  = "Contoso"
                Project       = "ADO-project"
                teamsToUpdate = @(
                    @{
                        Id   = 'Id1'
                        Name = 'ToUpdateName'
                    },
                    @{
                        Id   = '1234-5678-9101-1231'
                        Name = 'ToUpdateName2'
                    }
                )
            }
        )
        It "Should update Team name" -TestCases $testcases1 {

            param(
                [string] $Organization,
                [string] $Project,
                [PSCustomObject[]] $teamsToUpdate
            )

            Mock Invoke-RESTCommand -ParameterFilter { (ConvertFrom-Json $body).Name -eq $teamsToUpdate[0].Name -and $uri -like ("*{0}*" -f $teamsToUpdate[0].Id) } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { (ConvertFrom-Json $body).Name -eq $teamsToUpdate[1].Name -and $uri -like ("*{0}*" -f $teamsToUpdate[1].Id) } -Verifiable

            $Team = @{
                Organization  = $Organization
                Project       = $Project
                teamsToUpdate = $teamsToUpdate
            }
            { Set-ProjectTeamRange @Team -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        $testcases2 = @(
            @{
                Organization  = "Contoso"
                Project       = "ADO-project"
                teamsToUpdate = @(
                    @{
                        Id          = 'Id1'
                        Description = 'ToUpdateDescription'
                    },
                    @{
                        Id          = '1234-5678-9101-1231'
                        Description = 'ToUpdateDescription2'
                    }
                )
            }
        )
        It "Should update team description" -TestCases $testcases2 {

            param(
                [string] $Organization,
                [string] $Project,
                [PSCustomObject[]] $teamsToUpdate
            )

            Mock Invoke-RESTCommand -ParameterFilter { (ConvertFrom-Json $body).Description -eq $teamsToUpdate[0].Description -and $uri -like ("*{0}*" -f $teamsToUpdate[0].Id) } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { (ConvertFrom-Json $body).Description -eq $teamsToUpdate[1].Description -and $uri -like ("*{0}*" -f $teamsToUpdate[1].Id) } -Verifiable

            $Team = @{
                Organization  = $Organization
                Project       = $Project
                teamsToUpdate = $teamsToUpdate
            }
            { Set-ProjectTeamRange @Team -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }


        $testcases3 = @(
            @{
                Organization  = "Contoso"
                Project       = "ADO-project"
                teamsToUpdate = @(
                    @{
                        Id          = 'Id1'
                        Name        = 'ToUpdateName'
                        Description = 'ToUpdateDescription'
                    },
                    @{
                        Id          = '1234-5678-9101-1231'
                        Name        = 'ToUpdateName2'
                        Description = 'ToUpdateDescription2'
                    }
                )
            }
        )
        It "Should update team & description" -TestCases $testcases3 {

            param(
                [string] $Organization,
                [string] $Project,
                [PSCustomObject[]] $teamsToUpdate
            )

            Mock Invoke-RESTCommand -ParameterFilter { (ConvertFrom-Json $body).Name -eq $teamsToUpdate[0].Name -and (ConvertFrom-Json $body).Description -eq $teamsToUpdate[0].Description -and $uri -like ("*{0}*" -f $teamsToUpdate[0].Id) } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { (ConvertFrom-Json $body).Name -eq $teamsToUpdate[1].Name -and (ConvertFrom-Json $body).Description -eq $teamsToUpdate[1].Description -and $uri -like ("*{0}*" -f $teamsToUpdate[1].Id) } -Verifiable


            $Team = @{
                Organization  = $Organization
                Project       = $Project
                teamsToUpdate = $teamsToUpdate
            }
            { Set-ProjectTeamRange @Team -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}