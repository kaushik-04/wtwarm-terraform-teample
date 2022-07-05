# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Process] New-DevOpsProcessBacklogLevelRange" -Tag Build {

        $testcases = @(
            @{
                organization          = "contoso"
                process               = @{
                    id   = 0
                    name = 'MyProcess'
                }
                backlogLevelsToCreate = @(
                    @{
                        Name  = 'BacklogLevel1'
                        Color = 'eeeeee'
                    }
                )
            }
        )
        It "Should create process backlog level with all properties" -TestCases $testcases {

            param(
                [string] $organization,
                [PSCustomObject] $process,
                [PSCustomObject[]] $backlogLevelsToCreate
            )

            foreach ($backlogLevelToCreate in $backlogLevelsToCreate) {
                Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*$organization*{0}*" -f $process.id) -and
                    (ConvertFrom-Json $body).name -eq $backlogLevelToCreate.Name -and
                    (ConvertFrom-Json $body).Color -eq $backlogLevelToCreate.Color -and
                    (ConvertFrom-Json $body).inherits -eq 'System.PortfolioBacklogBehavior' # always required
                } -Verifiable
            }

            $inputObject = @{
                Organization          = $Organization
                process               = $process
                backlogLevelsToCreate = $backlogLevelsToCreate
            }
            { New-DevOpsProcessBacklogLevelRange @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}