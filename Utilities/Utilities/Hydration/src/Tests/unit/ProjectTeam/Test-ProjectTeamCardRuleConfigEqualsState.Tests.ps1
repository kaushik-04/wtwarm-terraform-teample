

# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] Test-ProjectTeamCardRuleConfigEqualsState" -Tag Build {

        It "Should find match" {

            $localConfig = @{
                cardStyles = @(
                    @{
                        name            = "Blocked"
                        isEnabled       = $false
                        filter          = "[Tags] contains 'Blocked' and [System.CreatedDate] = '2021-01-01'"
                        foregroundColor = "#111111"
                    },
                    @{
                        name            = "Custom"
                        isEnabled       = $true
                        filter          = "[Tags] contains 'Blocked' and [StoryPoints] = '8'"
                        backgroundColor = "#de5e5e"
                        foregroundColor = "#222222"
                        isItalic        = $true
                        isBold          = $true
                        isUnderlined    = $true
                    }
                    @{
                        name   = "Other"
                        filter = "[Tags] contains 'Blocked'"
                    }
                )
                tagStyles  = @(
                    @{
                        name      = "Blocked"
                        isEnabled = $false
                        color     = "#111111"
                    },
                    @{
                        name  = "CustomAddedColor"
                        color = "#00564b"
                    }
                )
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteSettings = @{
                rules = @{
                    fill     = @(
                        @{
                            name      = "Blocked"
                            isEnabled = "False"
                            filter    = "[Tags] contains 'Blocked' and [System.CreatedDate] = '2021-01-01'"
                            settings  = @{
                                'background-color' = "#de5e5e"
                                'title-color'      = "#111111"
                            }
                        },
                        @{
                            name      = "Custom"
                            isEnabled = "True"
                            filter    = "[Tags] contains 'Blocked' and [StoryPoints] = '8'"
                            settings  = @{
                                'background-color'      = "#de5e5e"
                                'title-color'           = "#222222"
                                'title-font-style'      = "italic"
                                'title-font-weight'     = "bold"
                                'title-text-decoration' = "underline"
                            }
                        },
                        @{
                            name      = "Other"
                            isEnabled = "True"
                            filter    = "[Tags] contains 'Blocked'"
                            settings  = @{
                                'background-color' = "#de5e5e"
                                'title-color'      = "#000000"
                            }
                        }
                    )
                    tagStyle = @(
                        @{
                            name      = "Blocked"
                            isEnabled = "False"
                            settings  = @{
                                'background-color' = '#111111'
                                color              = '#000000'
                            }
                        },
                        @{
                            name      = "CustomAddedColor"
                            isEnabled = "True"
                            settings  = @{
                                'background-color' = '#00564b'
                                color              = '#000000'
                            }
                        }
                    )
                }
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10


            $inputObject = @{
                localCardConfig         = $localConfig
                remoteCardStyleSettings = $remoteSettings
            }
            $res = Test-ProjectTeamCardRuleConfigEqualsState @inputObject -ErrorAction 'Stop'
            $res | Should -Be $true
        }

        It "Should find divergence" {

            $localConfig = @{
                cardStyles = @(
                    @{
                        name            = "Blocked"
                        isEnabled       = $false
                        filter          = "[Tags] contains 'Blocked' and [System.CreatedDate] = '2021-01-01'"
                        foregroundColor = "#111111"
                    },
                    @{
                        name            = "Custom"
                        isEnabled       = $true
                        filter          = "[Tags] contains 'Blocked' and [StoryPoints] = '8'"
                        backgroundColor = "#de5e5e"
                        foregroundColor = "#222222"
                        isItalic        = $true
                        isBold          = $true
                        isUnderlined    = $true
                    }
                )
                tagStyles  = @(
                    @{
                        name      = "Blocked"
                        isEnabled = $false
                        color     = "#111111"
                    }
                )
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteSettings = @{
                rules = @{
                    fill     = @(
                        @{
                            name      = "Blocked"
                            isEnabled = "False"
                            filter    = "[Tags] contains 'Blocked' and [System.CreatedDate] = '2021-01-01'"
                            settings  = @{
                                'background-color' = "#de5e5e"
                                'title-color'      = "#111111"
                            }
                        },
                        @{
                            name      = "Custom"
                            isEnabled = "True"
                            filter    = "[Tags] contains 'Blocked' and [StoryPoints] = '8'"
                            settings  = @{
                                'background-color'      = "#de5e5e"
                                'title-color'           = "#222222"
                                'title-font-style'      = "italic"
                                'title-font-weight'     = "bold"
                                'title-text-decoration' = "underline"
                            }
                        },
                        @{
                            name      = "Other"
                            isEnabled = "True"
                            filter    = "[Tags] contains 'Blocked'"
                            settings  = @{
                                'background-color' = "#de5e5e"
                                'title-color'      = "#000000"
                            }
                        }
                    )
                    tagStyle = @(
                        @{
                            name      = "Blocked"
                            isEnabled = "False"
                            settings  = @{
                                'background-color' = '#111111'
                                color              = '#000000'
                            }
                        },
                        @{
                            name      = "CustomAddedColor"
                            isEnabled = "True"
                            settings  = @{
                                'background-color' = '#00564b'
                                color              = '#000000'
                            }
                        }
                    )
                }
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10


            $inputObject = @{
                localCardConfig         = $localConfig
                remoteCardStyleSettings = $remoteSettings
            }
            $res = Test-ProjectTeamCardRuleConfigEqualsState @inputObject -ErrorAction 'Stop'
            $res | Should -Be $false
        }
    }
}