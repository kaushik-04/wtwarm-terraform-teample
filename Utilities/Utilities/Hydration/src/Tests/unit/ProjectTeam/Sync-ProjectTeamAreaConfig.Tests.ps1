# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] Sync-ProjectTeamAreaConfig" -Tag Build {

        It "Should set area config for teams as expected (single)" {

            $Organization = 'contoso'
            $project = 'Module Playground'
            $localTeamAreaConfig = @{
                defaultValue = "Area 1"
                values       = @(
                    @{
                        value           = "Area 1"
                        includeChildren = $false
                    }
                )
            }
            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }


            Mock Invoke-RESTCommand -ParameterFilter { $method -eq 'GET' -and $uri -like ("*{0}*teamsettings/teamfieldvalues*" -f [uri]::EscapeDataString($remoteTeam.name)) } -MockWith {
                return @{
                    defaultValue = "Module Playground\Area 2"
                    values       = @(
                        @{
                            value           = "Module Playground\Area 1"
                            includeChildren = $true
                        },
                        @{
                            value           = "Module Playground\Area 3"
                            includeChildren = $false
                        }
                    )
                }
            } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PATCH' -and
                $uri -like ("*{0}*teamsettings/teamfieldvalues*" -f $remoteTeam.id) -and
                (ConvertFrom-Json $body).defaultValue -eq 'Module Playground\Area 1' -and
                (ConvertFrom-Json $body).values[0].value -eq 'Module Playground\Area 1' -and
                (ConvertFrom-Json $body).values[0].includeChildren -eq $false
            } -Verifiable


            $syncAreaConfigInputObject = @{
                localTeamAreaConfig = $localTeamAreaConfig
                remoteTeam          = $remoteTeam
                Organization        = $Organization
                Project             = $project
                removeExcessItems   = $true
                DryRun              = $false
            }
            { Sync-ProjectTeamAreaConfig @syncAreaConfigInputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should set area config for teams as expected (multiple)" {

            $Organization = 'contoso'
            $project = 'Module Playground'
            $localTeamAreaConfig = @{
                defaultValue = "Area 1"
                values       = @(
                    @{
                        value           = "Area 1"
                        includeChildren = $false
                    },
                    @{
                        value           = "Area 2"
                        includeChildren = $true
                    }
                )
            }
            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }


            Mock Invoke-RESTCommand -ParameterFilter { $method -eq 'GET' -and $uri -like ("*{0}*teamsettings/teamfieldvalues*" -f [uri]::EscapeDataString($remoteTeam.name)) } -MockWith {
                return @{
                    defaultValue = "Module Playground\Area 2"
                    values       = @(
                        @{
                            value           = "Module Playground\Area 1"
                            includeChildren = $true
                        },
                        @{
                            value           = "Module Playground\Area 3"
                            includeChildren = $false
                        }
                    )
                }
            } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PATCH' -and
                $uri -like ("*{0}*teamsettings/teamfieldvalues*" -f $remoteTeam.id) -and
                (ConvertFrom-Json $body).defaultValue -eq 'Module Playground\Area 1' -and
                (ConvertFrom-Json $body).values[0].value -eq 'Module Playground\Area 1' -and
                (ConvertFrom-Json $body).values[0].includeChildren -eq $false -and
                (ConvertFrom-Json $body).values[1].value -eq 'Module Playground\Area 2' -and
                (ConvertFrom-Json $body).values[1].includeChildren -eq $true
            } -Verifiable


            $syncAreaConfigInputObject = @{
                localTeamAreaConfig = $localTeamAreaConfig
                remoteTeam          = $remoteTeam
                Organization        = $Organization
                Project             = $project
                removeExcessItems   = $true
                DryRun              = $false
            }
            { Sync-ProjectTeamAreaConfig @syncAreaConfigInputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should not fail during dry run" {

            $Organization = 'contoso'
            $project = 'Module Playground'
            $localTeamAreaConfig = @{
                defaultValue = "Area 1"
                values       = @(
                    @{
                        value           = "Area 1"
                        includeChildren = $false
                    },
                    @{
                        value           = "Area 2"
                        includeChildren = $true
                    }
                )
            }
            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            Mock Invoke-RESTCommand -ParameterFilter { $method -eq 'GET' -and $uri -like ("*{0}*teamsettings/teamfieldvalues*" -f [uri]::EscapeDataString($remoteTeam.name)) } -MockWith {
                return @{
                    defaultValue = "Module Playground\Area 2"
                    values       = @(
                        @{
                            value           = "Module Playground\Area 1"
                            includeChildren = $true
                        },
                        @{
                            value           = "Module Playground\Area 3"
                            includeChildren = $false
                        }
                    )
                }
            } -Verifiable

            $syncAreaConfigInputObject = @{
                localTeamAreaConfig = $localTeamAreaConfig
                remoteTeam          = $remoteTeam
                Organization        = $Organization
                Project             = $project
                removeExcessItems   = $true
                DryRun              = $true
            }
            { Sync-ProjectTeamAreaConfig @syncAreaConfigInputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should not attempt any change if matching" {

            $Organization = 'contoso'
            $project = 'Module Playground'
            $localTeamAreaConfig = @{
                defaultValue = "Area 1"
                values       = @(
                    @{
                        value           = "Area 1"
                        includeChildren = $true
                    },
                    @{
                        value           = "Area 2"
                        includeChildren = $false
                    }
                )
            }
            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            Mock Invoke-RESTCommand -ParameterFilter { $method -eq 'GET' -and $uri -like ("*{0}*teamsettings/teamfieldvalues*" -f [uri]::EscapeDataString($remoteTeam.name)) } -MockWith {
                return @{
                    defaultValue = "Module Playground\Area 1"
                    values       = @(
                        @{
                            value           = "Module Playground\Area 1"
                            includeChildren = $true
                        },
                        @{
                            value           = "Module Playground\Area 2"
                            includeChildren = $false
                        }
                    )
                }
            } -Verifiable


            $syncAreaConfigInputObject = @{
                localTeamAreaConfig = $localTeamAreaConfig
                remoteTeam          = $remoteTeam
                Organization        = $Organization
                Project             = $project
                removeExcessItems   = $true
                DryRun              = $false
            }
            { Sync-ProjectTeamAreaConfig @syncAreaConfigInputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should support dry run without project" {

            $Organization = 'contoso'
            $project = 'Module Playground'
            $localTeamAreaConfig = @{
                defaultValue = "Area 1"
                values       = @(
                    @{
                        value           = "Area 1"
                        includeChildren = $true
                    },
                    @{
                        value           = "Area 2"
                        includeChildren = $false
                    }
                )
            }
            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            $syncAreaConfigInputObject = @{
                localTeamAreaConfig = $localTeamAreaConfig
                remoteTeam          = $remoteTeam
                Organization        = $Organization
                Project             = $project
                removeExcessItems   = $true
                DryRun              = $true
            }
            { Sync-ProjectTeamAreaConfig @syncAreaConfigInputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}