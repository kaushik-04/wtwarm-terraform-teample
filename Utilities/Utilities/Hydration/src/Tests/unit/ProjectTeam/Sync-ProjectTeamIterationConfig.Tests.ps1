# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] Sync-ProjectTeamIterationConfig" -Tag Build {

        It "Should set interation config for teams as expected" {

            $Organization = 'contoso'
            $project = 'ModulePlayground'
            $localTeamIterationConfig = @{
                defaultValue = "CustomIteration1"
                backlog      = "CustomIteration2"
                values       = @(
                    'CustomIteration21',
                    'CustomIteration22'
                )
            }
            $remoteTeam = @{
                id   = 99
                name = 'ModulePlaygroundTeam'
            }

            $iterIdModulePlayground = '028d7b85-0fc5-4d27-a0c9-4d3e102b1c44'
            $iterIdCustomIteration1 = '88eed924-e838-4ca9-9d0a-abda00713ad6'
            $iterIdCustomIteration2 = 'c9d449cb-6420-4361-a330-399c15c42b25'
            $iterIdCustomIteration21 = 'ecdd2220-49d6-48a9-a932-04a7a4f92bd9'
            $iterIdCustomIteration22 = '18ab17cd-a7c7-41f5-81a5-e0f038c65dbe'

            # Get-ProjectIterationList invocation
            Mock Get-ProjectIterationList -ParameterFilter { $Organization -eq $Organization -and $project -eq $project } -MockWith {
                return @{
                    id          = 0
                    identifier  = $iterIdModulePlayground
                    name        = $project
                    hasChildren = $true
                    children    = @(
                        @{
                            id          = 1
                            identifier  = $iterIdCustomIteration1
                            name        = "CustomIteration1"
                            path        = "\\$project\\Iteration\\CustomIteration1"
                            hasChildren = $false
                        },
                        @{
                            id          = 2
                            identifier  = $iterIdCustomIteration2
                            name        = "CustomIteration2"
                            path        = "\\$project\\Iteration\\CustomIteration2"
                            hasChildren = $true
                            children    = @(
                                @{
                                    id          = 21
                                    identifier  = $iterIdCustomIteration21
                                    name        = "CustomIteration21"
                                    path        = "\\$project\\Iteration\\Sprint 2\\CustomIteration21"
                                    hasChildren = $false
                                }
                                @{
                                    id          = 22
                                    identifier  = $iterIdCustomIteration22
                                    name        = "CustomIteration22"
                                    path        = "\\$project\\Iteration\\Sprint 2\\CustomIteration22"
                                    hasChildren = $false
                                }
                            )
                        }
                    )
                } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10
            } -Verifiable

            # Get-ProjectTeamSetting invocation
            $remoteTeamSettings = @{
                backlogIteration = @{
                    id   = $iterIdModulePlayground
                    name = $project
                }
                defaultIteration = @{
                    id   = $iterIdCustomIteration1
                    name = "CustomIteration1"
                }
            }

            # Defaults update
            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PATCH' -and
                $uri -like ("*{0}*teamsettings*" -f $remoteTeam.id) -and
                (ConvertFrom-Json $body).backlogIteration -eq $iterIdCustomIteration2 -and
                (ConvertFrom-Json $body).defaultIteration -eq $iterIdCustomIteration1
            } -Verifiable

            # Get-ProjectTeamSettingIterationList invocation (available iterations)
            Mock Invoke-RESTCommand -ParameterFilter { $method -eq 'GET' -and $uri -like ("*{0}*teamsettings/iterations*" -f [uri]::EscapeDataString($remoteTeam.name)) } -MockWith {
                return @{
                    count = 3
                    value = @(
                        @{
                            id   = $iterIdModulePlayground
                            name = "ModulePlayground"
                        }
                        @{
                            id   = $iterIdCustomIteration1
                            name = "CustomIteration2"
                        }
                        @{
                            id   = $iterIdCustomIteration21
                            name = "CustomIteration21"
                        }
                    )
                }
            } -Verifiable

            # Add available iterations
            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'POST' -and
                $uri -like ("*{0}*teamsettings/iterations*" -f $remoteTeam.name) -and
                (ConvertFrom-Json $body).id -eq $iterIdCustomIteration22
            } -Verifiable

            # Remove available iterations
            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'DELETE' -and
                $uri -like ("*{0}*teamsettings/iterations/{1}*" -f $remoteTeam.Name, $iterIdModulePlayground)
            } -Verifiable

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'DELETE' -and
                $uri -like ("*{0}*teamsettings/iterations/{1}*" -f $remoteTeam.Name, $iterIdCustomIteration1)
            } -Verifiable


            $syncInterationConfigInputObject = @{
                localTeamIterationConfig = $localTeamIterationConfig
                remoteTeam               = $remoteTeam
                Organization             = $Organization
                Project                  = $project
                removeExcessItems        = $true
                remoteTeamSettings       = $remoteTeamSettings
                DryRun                   = $false
            }
            { Sync-ProjectTeamIterationConfig @syncInterationConfigInputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should not throw during dry run" {

            $Organization = 'contoso'
            $project = 'ModulePlayground'
            $localTeamIterationConfig = @{
                defaultValue = "CustomIteration1"
                backlog      = "CustomIteration2"
                values       = @(
                    'CustomIteration21',
                    'CustomIteration22'
                )
            }
            $remoteTeam = @{
                id   = 99
                name = 'ModulePlaygroundTeam'
            }

            $iterIdModulePlayground = '028d7b85-0fc5-4d27-a0c9-4d3e102b1c44'
            $iterIdCustomIteration1 = '88eed924-e838-4ca9-9d0a-abda00713ad6'
            $iterIdCustomIteration2 = 'c9d449cb-6420-4361-a330-399c15c42b25'
            $iterIdCustomIteration21 = 'ecdd2220-49d6-48a9-a932-04a7a4f92bd9'
            $iterIdCustomIteration22 = '18ab17cd-a7c7-41f5-81a5-e0f038c65dbe'

            # Get-ProjectIterationList invocation
            Mock Get-ProjectIterationList -ParameterFilter { $Organization -eq $Organization -and $project -eq $project } -MockWith {
                return @{
                    id          = 0
                    identifier  = $iterIdModulePlayground
                    name        = $project
                    hasChildren = $true
                    children    = @(
                        @{
                            id          = 1
                            identifier  = $iterIdCustomIteration1
                            name        = "CustomIteration1"
                            path        = "\\$project\\Iteration\\CustomIteration1"
                            hasChildren = $false
                        },
                        @{
                            id          = 2
                            identifier  = $iterIdCustomIteration2
                            name        = "CustomIteration2"
                            path        = "\\$project\\Iteration\\CustomIteration2"
                            hasChildren = $true
                            children    = @(
                                @{
                                    id          = 21
                                    identifier  = $iterIdCustomIteration21
                                    name        = "CustomIteration21"
                                    path        = "\\$project\\Iteration\\Sprint 2\\CustomIteration21"
                                    hasChildren = $false
                                }
                                @{
                                    id          = 22
                                    identifier  = $iterIdCustomIteration22
                                    name        = "CustomIteration22"
                                    path        = "\\$project\\Iteration\\Sprint 2\\CustomIteration22"
                                    hasChildren = $false
                                }
                            )
                        }
                    )
                } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10
            } -Verifiable

            # Get-ProjectTeamSetting invocation
            $remoteTeamSettings = @{
                backlogIteration = @{
                    id   = $iterIdModulePlayground
                    name = $project
                }
                defaultIteration = @{
                    id   = $iterIdModulePlayground
                    name = $project
                }
            }

            # Get-ProjectTeamSettingIterationList invocation (available iterations)
            Mock Invoke-RESTCommand -ParameterFilter { $method -eq 'GET' -and $uri -like ("*{0}*teamsettings/iterations*" -f [uri]::EscapeDataString($remoteTeam.name)) } -MockWith {
                return @{
                    count = 3
                    value = @(
                        @{
                            id   = $iterIdModulePlayground
                            name = $project
                        }
                        @{
                            id   = $iterIdCustomIteration1
                            name = "CustomIteration2"
                        }
                        @{
                            id   = $iterIdCustomIteration21
                            name = "CustomIteration21"
                        }
                    )
                }
            } -Verifiable

            $syncInterationConfigInputObject = @{
                localTeamIterationConfig = $localTeamIterationConfig
                remoteTeam               = $remoteTeam
                Organization             = $Organization
                Project                  = $project
                remoteTeamSettings       = $remoteTeamSettings
                removeExcessItems        = $true
                DryRun                   = $true
            }
            { Sync-ProjectTeamIterationConfig @syncInterationConfigInputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should support dry run without project" {

            $Organization = 'contoso'
            $project = 'ModulePlayground'
            $localTeamIterationConfig = @{
                defaultValue = "CustomIteration1"
                backlog      = "CustomIteration2"
                values       = @(
                    'CustomIteration21',
                    'CustomIteration22'
                )
            }
            $remoteTeam = @{
                id   = 99
                name = 'ModulePlaygroundTeam'
            }
            $remoteTeamSettings = @{
                backlogIteration = @{
                    id   = '028d7b85-0fc5-4d27-a0c9-4d3e102b1c44'
                    name = $project
                }
                defaultIteration = @{
                    id   = '028d7b85-0fc5-4d27-a0c9-4d3e102b1c44'
                    name = $project
                }
            }

            $syncInterationConfigInputObject = @{
                localTeamIterationConfig = $localTeamIterationConfig
                remoteTeam               = $remoteTeam
                Organization             = $Organization
                Project                  = $project
                remoteTeamSettings       = $remoteTeamSettings
                removeExcessItems        = $true
                DryRun                   = $true
            }
            { Sync-ProjectTeamIterationConfig @syncInterationConfigInputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}