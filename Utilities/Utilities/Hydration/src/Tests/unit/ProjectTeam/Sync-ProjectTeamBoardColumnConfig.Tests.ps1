# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] Sync-ProjectTeamBoardColumnConfig" -Tag Build {

        It "Should set additional columns as expected (excluding first & last)" {

            $localColumnConfig = @(
                @{
                    name                 = "customColumn1"
                    itemsInProgressLimit = 5
                    isSplit              = $false
                    stateMappings        = @{
                        Component      = "Active"
                        Epic           = "Active"
                        'Landing Zone' = "Active"
                    }
                    definitionOfDone     = "I'm super done"
                },
                @{
                    name                 = 'customColumn2'
                    itemsInProgressLimit = 3
                    isSplit              = $true
                    stateMappings        = @{
                        'User Story' = "Active"
                    }
                    definitionOfDone     = "I'm super done 2"
                },
                @{
                    name                 = 'Resolved'
                    itemsInProgressLimit = 2
                    stateMappings        = @{
                        Component = 'New'
                        Epic      = 'Resolved'
                    }
                    isSplit              = $true
                    definitionOfDone     = 'New description'
                }
            )

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            $remoteBoardSettings = @{
                columns = @(
                    @{
                        id            = '5eb42944-dd1d-4afe-a31f-fe97df7be39f'
                        name          = 'New'
                        itemLimit     = 0
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'New'
                            'Landing Zone' = 'New'
                        }
                        columnType    = 'incoming'
                    },
                    @{
                        id            = 'fb7cbf4f-45cb-4100-a8bc-278d86c59994'
                        name          = 'Active'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'Active'
                            Epic           = 'Active'
                            'Landing Zone' = 'Active'
                        }
                        isSplit       = $false
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = '6ff4d5b4-5dc1-4668-a46e-58b261f13e4f'
                        name          = 'Resolved'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'Resolved'
                            'Landing Zone' = 'New'
                        }
                        isSplit       = $false
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = 'f58b8f69-d527-4366-a7f7-e2242db8123e'
                        name          = 'Closed'
                        itemLimit     = 0
                        stateMappings = @{
                            Component      = 'Closed'
                            Epic           = 'Closed'
                            'Landing Zone' = 'Closed'
                        }
                        columnType    = 'outgoing'
                    }
                )
            }

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PUT' -and
                $uri -like "*/columns*" -and
                (ConvertFrom-Json $body).count -eq 6
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'New' }).Count -eq 1 -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'Closed' }).Count -eq 1 -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'customColumn1' }).Count -eq 1 -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'customColumn2' }).Count -eq 1 -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'Active' }).Count -eq 1 -and
                ((ConvertFrom-Json $body) | Where-Object {
                        $_.Name -eq 'Resolved' -and
                        $_.itemLimit -eq 2 -and
                        $_.isSplit -eq $true -and
                        $_.stateMappings.count -eq 2
                        $_.description -eq 'New description'
                    }).Count -eq 1
            } -MockWith { return @{ value = 'dummyResponse' } } -Verifiable


            $inputObject = @{
                localColumnConfig   = $localColumnConfig
                team                = $remoteTeam.Name
                backlogLevel        = 'Stories'
                remoteBoardSettings = $remoteBoardSettings
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $false
                DryRun              = $false
            }
            { Sync-ProjectTeamBoardColumnConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should set additional columns as expected (including first & last)" {

            $localColumnConfig = @(
                @{
                    name          = "customIn"
                    stateMappings = @{
                        Component      = "New"
                        Epic           = "New"
                        'Landing Zone' = "New"
                    }
                    columnType    = "incoming"
                },
                @{
                    name          = 'customProgress'
                    stateMappings = @{
                        'User Story' = "Active"
                    }
                    columnType    = "inProgress"
                },
                @{
                    name          = 'customOut'
                    stateMappings = @{
                        Component = 'Closed'
                        Epic      = 'Closed'
                    }
                    columnType    = "outgoing"
                }
            )

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            $remoteBoardSettings = @{
                columns = @(
                    @{
                        id            = '5eb42944-dd1d-4afe-a31f-fe97df7be39f'
                        name          = 'New'
                        itemLimit     = 0
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'New'
                            'Landing Zone' = 'New'
                        }
                        columnType    = 'incoming'
                    },
                    @{
                        id            = 'fb7cbf4f-45cb-4100-a8bc-278d86c59994'
                        name          = 'Active'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'Active'
                            Epic           = 'Active'
                            'Landing Zone' = 'Active'
                        }
                        isSplit       = $false
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = '6ff4d5b4-5dc1-4668-a46e-58b261f13e4f'
                        name          = 'Resolved'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'Resolved'
                            'Landing Zone' = 'New'
                        }
                        isSplit       = $false
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = 'f58b8f69-d527-4366-a7f7-e2242db8123e'
                        name          = 'Closed'
                        itemLimit     = 0
                        stateMappings = @{
                            Component      = 'Closed'
                            Epic           = 'Closed'
                            'Landing Zone' = 'Closed'
                        }
                        columnType    = 'outgoing'
                    }
                )
            }

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PUT' -and
                $uri -like "*/columns*" -and
                (ConvertFrom-Json $body).count -eq 3 -and
                ((ConvertFrom-Json $body) | Where-Object {
                        $_.Name -eq 'customIn' -and
                        $_.id -eq '5eb42944-dd1d-4afe-a31f-fe97df7be39f' -and
                        $_.columnType -eq 'incoming'
                    }).Count -eq 1 # -and
                ((ConvertFrom-Json $body) | Where-Object {
                        $_.Name -eq 'customProgress'
                    }).Count -eq 1 -and
                ((ConvertFrom-Json $body) | Where-Object {
                        $_.Name -eq 'customOut' -and
                        $_.id -eq 'f58b8f69-d527-4366-a7f7-e2242db8123e' -and
                        $_.columnType -eq 'outgoing'
                    }).Count -eq 1
            } -MockWith { return @{ value = 'dummyResponse' } } -Verifiable


            $inputObject = @{
                localColumnConfig   = $localColumnConfig
                team                = $remoteTeam.Name
                backlogLevel        = 'Stories'
                remoteBoardSettings = $remoteBoardSettings
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $true
                DryRun              = $false
            }
            { Sync-ProjectTeamBoardColumnConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should set desired columns state (DSC) as expected" {

            $localColumnConfig = @(
                @{
                    name                 = "customColumn1"
                    itemsInProgressLimit = 5
                    isSplit              = $false
                    stateMappings        = @{
                        Component      = "Active"
                        Epic           = "Active"
                        'Landing Zone' = "Active"
                    }
                    definitionOfDone     = "I'm super done"
                },
                @{
                    name                 = 'customColumn2'
                    itemsInProgressLimit = 3
                    isSplit              = $true
                    stateMappings        = @{
                        'User Story' = "Active"
                    }
                    definitionOfDone     = "I'm super done 2"
                },
                @{
                    name                 = 'Resolved'
                    itemsInProgressLimit = 2
                    stateMappings        = @{
                        Component = 'New'
                        Epic      = 'Resolved'
                    }
                    isSplit              = $true
                    definitionOfDone     = 'New description'
                }
            )

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            $remoteBoardSettings = @{
                columns = @(
                    @{
                        id            = '5eb42944-dd1d-4afe-a31f-fe97df7be39f'
                        name          = 'New'
                        itemLimit     = 0
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'New'
                            'Landing Zone' = 'New'
                        }
                        columnType    = 'incoming'
                    },
                    @{
                        id            = 'fb7cbf4f-45cb-4100-a8bc-278d86c59994'
                        name          = 'Active'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'Active'
                            Epic           = 'Active'
                            'Landing Zone' = 'Active'
                        }
                        isSplit       = $false
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = '6ff4d5b4-5dc1-4668-a46e-58b261f13e4f'
                        name          = 'Resolved'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'Resolved'
                            'Landing Zone' = 'New'
                        }
                        isSplit       = $false
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = 'f58b8f69-d527-4366-a7f7-e2242db8123e'
                        name          = 'Closed'
                        itemLimit     = 0
                        stateMappings = @{
                            Component      = 'Closed'
                            Epic           = 'Closed'
                            'Landing Zone' = 'Closed'
                        }
                        columnType    = 'outgoing'
                    }
                )
            }

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PUT' -and
                $uri -like "*/columns*" -and
                (ConvertFrom-Json $body).count -eq 5
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'New' }).Count -eq 1 -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'Closed' }).Count -eq 1 -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'customColumn1' }).Count -eq 1 -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'customColumn2' }).Count -eq 1 -and
                ((ConvertFrom-Json $body) | Where-Object {
                        $_.Name -eq 'Resolved' -and
                        $_.itemLimit -eq 2 -and
                        $_.isSplit -eq $true -and
                        $_.stateMappings.count -eq 2
                        $_.description -eq 'New description'
                    }).Count -eq 1
            } -MockWith { return @{ value = 'dummyResponse' } } -Verifiable


            $inputObject = @{
                localColumnConfig   = $localColumnConfig
                team                = $remoteTeam.Name
                backlogLevel        = 'Stories'
                remoteBoardSettings = $remoteBoardSettings
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $true
                DryRun              = $false
            }
            { Sync-ProjectTeamBoardColumnConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should remove all but required as expected" {

            $localColumnConfig = @()

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            $remoteBoardSettings = @{
                columns = @(
                    @{
                        id            = '5eb42944-dd1d-4afe-a31f-fe97df7be39f'
                        name          = 'New'
                        itemLimit     = 0
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'New'
                            'Landing Zone' = 'New'
                        }
                        columnType    = 'incoming'
                    },
                    @{
                        id            = 'fb7cbf4f-45cb-4100-a8bc-278d86c59994'
                        name          = 'Active'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'Active'
                            Epic           = 'Active'
                            'Landing Zone' = 'Active'
                        }
                        isSplit       = $false
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = '6ff4d5b4-5dc1-4668-a46e-58b261f13e4f'
                        name          = 'Resolved'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'Resolved'
                            'Landing Zone' = 'New'
                        }
                        isSplit       = $false
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = 'f58b8f69-d527-4366-a7f7-e2242db8123e'
                        name          = 'Closed'
                        itemLimit     = 0
                        stateMappings = @{
                            Component      = 'Closed'
                            Epic           = 'Closed'
                            'Landing Zone' = 'Closed'
                        }
                        columnType    = 'outgoing'
                    }
                )
            }

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PUT' -and
                $uri -like "*/columns*" -and
                (ConvertFrom-Json $body).count -eq 2
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'New' }).Count -eq 1 -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'Closed' }).Count -eq 1
            } -MockWith { return @{ value = 'dummyResponse' } } -Verifiable


            $inputObject = @{
                localColumnConfig   = $localColumnConfig
                team                = $remoteTeam.Name
                backlogLevel        = 'Stories'
                remoteBoardSettings = $remoteBoardSettings
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $true
                DryRun              = $false
            }
            { Sync-ProjectTeamBoardColumnConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should not fail during dry run" {

            $localColumnConfig = @(
                @{
                    name                 = "customColumn1"
                    itemsInProgressLimit = 5
                    isSplit              = $false
                    stateMappings        = @{
                        Component      = "Active"
                        Epic           = "Active"
                        'Landing Zone' = "Active"
                    }
                    definitionOfDone     = "I'm super done"
                },
                @{
                    name                 = 'customColumn2'
                    itemsInProgressLimit = 3
                    isSplit              = $true
                    stateMappings        = @{
                        'User Story' = "Active"
                    }
                    definitionOfDone     = "I'm super done 2"
                },
                @{
                    name                 = 'Resolved'
                    itemsInProgressLimit = 2
                    stateMappings        = @{
                        Component = 'New'
                        Epic      = 'Resolved'
                    }
                    isSplit              = $true
                    definitionOfDone     = 'New description'
                }
            )

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            $remoteBoardSettings = @{
                columns = @(
                    @{
                        id            = '5eb42944-dd1d-4afe-a31f-fe97df7be39f'
                        name          = 'New'
                        itemLimit     = 0
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'New'
                            'Landing Zone' = 'New'
                        }
                        columnType    = 'incoming'
                    },
                    @{
                        id            = 'fb7cbf4f-45cb-4100-a8bc-278d86c59994'
                        name          = 'Active'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'Active'
                            Epic           = 'Active'
                            'Landing Zone' = 'Active'
                        }
                        isSplit       = $false
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = '6ff4d5b4-5dc1-4668-a46e-58b261f13e4f'
                        name          = 'Resolved'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'Resolved'
                            'Landing Zone' = 'New'
                        }
                        isSplit       = $false
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = 'f58b8f69-d527-4366-a7f7-e2242db8123e'
                        name          = 'Closed'
                        itemLimit     = 0
                        stateMappings = @{
                            Component      = 'Closed'
                            Epic           = 'Closed'
                            'Landing Zone' = 'Closed'
                        }
                        columnType    = 'outgoing'
                    }
                )
            }

            Mock Invoke-RESTCommand -MockWith { throw 'This Mock should not be invoked as this is a dry run' } -Verifiable

            $inputObject = @{
                localColumnConfig   = $localColumnConfig
                team                = $remoteTeam.Name
                backlogLevel        = 'Stories'
                remoteBoardSettings = $remoteBoardSettings
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $true
                DryRun              = $true
            }
            { Sync-ProjectTeamBoardColumnConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It "Should not attempt any change if matching" {

            $localColumnConfig = @(
                @{
                    name                 = 'Active'
                    itemsInProgressLimit = 5
                    stateMappings        = @{
                        Component      = 'Active'
                        Epic           = 'Active'
                        'Landing Zone' = 'Active'
                    }
                    isSplit              = $true
                    definitionOfDone     = ''
                },
                @{
                    name                 = 'Resolved'
                    itemsInProgressLimit = 5
                    stateMappings        = @{
                        Component      = 'New'
                        Epic           = 'Resolved'
                        'Landing Zone' = 'New'
                    }
                    isSplit              = $false
                    definitionOfDone     = ''
                },
                @{
                    name                 = 'Blocked'
                    itemsInProgressLimit = 5
                    stateMappings        = @{
                        Component      = 'New'
                        Epic           = 'Resolved'
                        'Landing Zone' = 'New'
                    }
                    definitionOfDone     = ''
                }
            )

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            $remoteBoardSettings = @{
                columns = @(
                    @{
                        id            = '5eb42944-dd1d-4afe-a31f-fe97df7be39f'
                        name          = 'New'
                        itemLimit     = 0
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'New'
                            'Landing Zone' = 'New'
                        }
                        columnType    = 'incoming'
                    },
                    @{
                        id            = 'fb7cbf4f-45cb-4100-a8bc-278d86c59994'
                        name          = 'Active'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'Active'
                            Epic           = 'Active'
                            'Landing Zone' = 'Active'
                        }
                        isSplit       = $true
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = '6ff4d5b4-5dc1-4668-a46e-58b261f13e5f'
                        name          = 'Blocked'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'Resolved'
                            'Landing Zone' = 'New'
                        }
                        isSplit       = $true
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = '6ff4d5b4-5dc1-4668-a46e-58b261f13e4f'
                        name          = 'Resolved'
                        itemLimit     = 5
                        stateMappings = @{
                            Component      = 'New'
                            Epic           = 'Resolved'
                            'Landing Zone' = 'New'
                        }
                        isSplit       = $false
                        description   = ''
                        columnType    = 'inProgress'
                    },
                    @{
                        id            = 'f58b8f69-d527-4366-a7f7-e2242db8123e'
                        name          = 'Closed'
                        itemLimit     = 0
                        stateMappings = @{
                            Component      = 'Closed'
                            Epic           = 'Closed'
                            'Landing Zone' = 'Closed'
                        }
                        columnType    = 'outgoing'
                    }
                )
            }

            Mock Invoke-RESTCommand -MockWith { throw 'This Mock should not be invoked as no changes are necessary' } -Verifiable

            $inputObject = @{
                localColumnConfig   = $localColumnConfig
                team                = $remoteTeam.Name
                backlogLevel        = 'Stories'
                remoteBoardSettings = $remoteBoardSettings
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $true
                DryRun              = $false
            }
            { Sync-ProjectTeamBoardColumnConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It "Should support dry run without project" {

            $localColumnConfig = @(
                @{
                    name                 = "customColumn1"
                    itemsInProgressLimit = 5
                    isSplit              = $false
                    stateMappings        = @{
                        Component      = "Active"
                        Epic           = "Active"
                        'Landing Zone' = "Active"
                    }
                    definitionOfDone     = "I'm super done"
                },
                @{
                    name                 = 'customColumn2'
                    itemsInProgressLimit = 3
                    isSplit              = $true
                    stateMappings        = @{
                        'User Story' = "Active"
                    }
                    definitionOfDone     = "I'm super done 2"
                },
                @{
                    name                 = 'Resolved'
                    itemsInProgressLimit = 2
                    stateMappings        = @{
                        Component = 'New'
                        Epic      = 'Resolved'
                    }
                    isSplit              = $true
                    definitionOfDone     = 'New description'
                }
            )

            Mock Invoke-RESTCommand -MockWith { return 'This Mock should not be invoked as this is a dry run' } -Verifiable

            $inputObject = @{
                localColumnConfig   = $localColumnConfig
                team                = 'Module Playground Team'
                backlogLevel        = 'Stories'
                remoteBoardSettings = @{}
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $true
                DryRun              = $true
            }
            { Sync-ProjectTeamBoardColumnConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw
        }
    }
}