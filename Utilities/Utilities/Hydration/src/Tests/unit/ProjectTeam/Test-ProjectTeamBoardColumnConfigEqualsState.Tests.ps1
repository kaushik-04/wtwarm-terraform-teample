# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] Test-ProjectTeamBoardColumnConfigEqualsState" -Tag Build {

        It "Should find match" {

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

            $inputObject = @{
                localColumnConfig   = $localColumnConfig
                remoteBoardSettings = $remoteBoardSettings
            }
            $res = Test-ProjectTeamBoardColumnConfigEqualsState @inputObject -ErrorAction 'Stop'
            $res | Should -Be $true
        }

        It "Should find divergence" {

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
                }
            )

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
                    }
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

            $inputObject = @{
                localColumnConfig   = $localColumnConfig
                remoteBoardSettings = $remoteBoardSettings
            }
            $res = Test-ProjectTeamBoardColumnConfigEqualsState @inputObject -ErrorAction 'Stop'
            $res | Should -Be $false
        }
    }
}