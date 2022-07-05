# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] Sync-ProjectTeamCardRuleConfig" -Tag Build {

        It "Should set additional card styles as expected" {

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
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteSettings = @{
                rules = @{
                    fill = @(
                        @{
                            name      = "Blocked"
                            isEnabled = "True"
                            filter    = "[System.Tags] contains 'Blocked'"
                            settings  = @{
                                'background-color' = "#eeeeee"
                                'title-color'      = "#000000"
                            }
                        },
                        @{
                            name      = "Other"
                            isEnabled = "True"
                            filter    = "[System.Tags] contains 'Other'"
                            settings  = @{
                                'background-color' = "#de5e5e"
                                'title-color'      = "#000000"
                            }
                        }
                    )
                }
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PATCH' -and
                $uri -like "*/cardrulesettings*" -and
                (ConvertFrom-Json $body).rules.fill.count -eq 3 -and
                ((ConvertFrom-Json $body).rules.fill | Where-Object {
                        $_.Name -eq 'Blocked' -and
                        $_.isEnabled -eq $false -and
                        $_.filter -eq "[System.Tags] contains 'Blocked' and [System.CreatedDate] = '2021-01-01'" -and
                        $_.settings.'background-color' -eq '#eeeeee' -and
                        $_.settings.'title-color' -eq '#111111'
                    }).Count -eq 1 -and
                ((ConvertFrom-Json $body).rules.fill | Where-Object {
                        $_.Name -eq 'Custom' -and
                        $_.isEnabled -eq $true -and
                        $_.filter -eq "[System.Tags] contains 'Blocked' and [Microsoft.VSTS.Scheduling.StoryPoints] = '8'" -and
                        $_.settings.'background-color' -eq '#de5e5e' -and
                        $_.settings.'title-color' -eq '#222222' -and
                        $_.settings.'title-text-decoration' -eq 'underline' -and
                        $_.settings.'title-font-weight' -eq 'bold' -and
                        $_.settings.'title-font-style' -eq 'italic'
                    }).Count -eq 1 -and
                ((ConvertFrom-Json $body).rules.fill | Where-Object {
                        $_.Name -eq 'Other' -and
                        $_.isEnabled -eq $true -and
                        $_.filter -eq "[System.Tags] contains 'Other'" -and
                        $_.settings.'background-color' -eq '#de5e5e' -and
                        $_.settings.'title-color' -eq '#000000'
                    }).Count -eq 1
            } -MockWith { return @{ rules = 'dummyResponse' }
            } -Verifiable

            $inputObject = @{
                localCardConfig         = $localConfig
                team                    = $remoteTeam.Name
                backlogLevel            = 'Stories'
                remoteCardStyleSettings = $remoteSettings
                Organization            = 'contoso'
                Project                 = 'Module Playground'
                removeExcessItems       = $false
                DryRun                  = $false
            }
            { Sync-ProjectTeamCardRuleConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should set additional tag styles as expected" {

            $localConfig = @{
                tagStyles = @(
                    @{
                        name      = "Blocked"
                        isEnabled = $true
                        color     = "#111111"
                    },
                    @{
                        name  = "CustomAddedColor"
                        color = "#00564b"
                    }
                )
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteSettings = @{
                rules = @{
                    tagStyle = @(
                        @{
                            name      = "Blocked"
                            isEnabled = "False"
                            settings  = @{
                                'background-color' = '#ec001d'
                                color              = '#ffffff'
                            }
                        },
                        @{
                            name      = "Enablement"
                            isEnabled = "True"
                            settings  = @{
                                'background-color' = '#525252'
                                color              = '#ffffff'
                            }
                        }
                    )
                }
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PATCH' -and
                $uri -like "*/cardrulesettings*" -and
                (ConvertFrom-Json $body).rules.tagStyle.count -eq 3 -and
                ((ConvertFrom-Json $body).rules.tagStyle | Where-Object {
                        $_.Name -eq 'Blocked' -and
                        $_.isEnabled -eq $true -and
                        $_.settings.'background-color' -eq '#111111' -and
                        $_.settings.'color' -eq '#000000'
                    }).Count -eq 1 -and
                ((ConvertFrom-Json $body).rules.tagStyle | Where-Object {
                        $_.Name -eq 'CustomAddedColor' -and
                        $_.isEnabled -eq $true -and
                        $_.settings.'background-color' -eq '#00564b' -and
                        $_.settings.'color' -eq '#000000'
                    }).Count -eq 1 -and
                ((ConvertFrom-Json $body).rules.tagStyle | Where-Object {
                        $_.Name -eq 'Enablement' -and
                        $_.isEnabled -eq $true -and
                        $_.settings.'background-color' -eq '#525252' -and
                        $_.settings.'color' -eq '#ffffff'
                    }).Count -eq 1
            } -MockWith { return @{ rules = 'dummyResponse' }
            } -Verifiable


            $inputObject = @{
                localCardConfig         = $localConfig
                team                    = $remoteTeam.Name
                backlogLevel            = 'Stories'
                remoteCardStyleSettings = $remoteSettings
                Organization            = 'contoso'
                Project                 = 'Module Playground'
                removeExcessItems       = $false
                DryRun                  = $false
            }
            { Sync-ProjectTeamCardRuleConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should set desired card style state (DSC) as expected" {

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
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteSettings = @{
                rules = @{
                    fill = @(
                        @{
                            name      = "Blocked"
                            isEnabled = "True"
                            filter    = "[System.Tags] contains 'Blocked'"
                            settings  = @{
                                'background-color' = "#eeeeee"
                                'title-color'      = "#000000"
                            }
                        },
                        @{
                            name      = "Other"
                            isEnabled = "True"
                            filter    = "[System.Tags] contains 'Other'"
                            settings  = @{
                                'background-color' = "#de5e5e"
                                'title-color'      = "#000000"
                            }
                        }
                    )
                }
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PATCH' -and
                $uri -like "*/cardrulesettings*" -and
                (ConvertFrom-Json $body).rules.fill.count -eq 2 -and
                ((ConvertFrom-Json $body).rules.fill | Where-Object {
                        $_.Name -eq 'Blocked' -and
                        $_.isEnabled -eq $false -and
                        $_.filter -eq "[System.Tags] contains 'Blocked' and [System.CreatedDate] = '2021-01-01'" -and
                        $_.settings.'background-color' -eq '#eeeeee' -and
                        $_.settings.'title-color' -eq '#111111'
                    }).Count -eq 1 -and
                ((ConvertFrom-Json $body).rules.fill | Where-Object {
                        $_.Name -eq 'Custom' -and
                        $_.isEnabled -eq $true -and
                        $_.filter -eq "[System.Tags] contains 'Blocked' and [Microsoft.VSTS.Scheduling.StoryPoints] = '8'" -and
                        $_.settings.'background-color' -eq '#de5e5e' -and
                        $_.settings.'title-color' -eq '#222222' -and
                        $_.settings.'title-text-decoration' -eq 'underline' -and
                        $_.settings.'title-font-weight' -eq 'bold' -and
                        $_.settings.'title-font-style' -eq 'italic'
                    }).Count -eq 1
            } -MockWith { return @{ rules = 'dummyResponse' }
            } -Verifiable

            $inputObject = @{
                localCardConfig         = $localConfig
                team                    = $remoteTeam.Name
                backlogLevel            = 'Stories'
                remoteCardStyleSettings = $remoteSettings
                Organization            = 'contoso'
                Project                 = 'Module Playground'
                removeExcessItems       = $true
                DryRun                  = $false
            }
            { Sync-ProjectTeamCardRuleConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should set desired tag style state (DSC) as expected" {


            $localConfig = @{
                tagStyles = @(
                    @{
                        name      = "Blocked"
                        isEnabled = $true
                        color     = "#111111"
                    },
                    @{
                        name  = "CustomAddedColor"
                        color = "#00564b"
                    }
                )
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteSettings = @{
                rules = @{
                    tagStyle = @(
                        @{
                            name      = "Blocked"
                            isEnabled = "False"
                            settings  = @{
                                'background-color' = '#ec001d'
                                color              = '#ffffff'
                            }
                        },
                        @{
                            name      = "Enablement"
                            isEnabled = "True"
                            settings  = @{
                                'background-color' = '#525252'
                                color              = '#ffffff'
                            }
                        }
                    )
                }
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PATCH' -and
                $uri -like "*/cardrulesettings*" -and
                (ConvertFrom-Json $body).rules.tagStyle.count -eq 2 -and
                ((ConvertFrom-Json $body).rules.tagStyle | Where-Object {
                        $_.Name -eq 'Blocked' -and
                        $_.isEnabled -eq $true -and
                        $_.settings.'background-color' -eq '#111111' -and
                        $_.settings.'color' -eq '#000000'
                    }).Count -eq 1 -and
                ((ConvertFrom-Json $body).rules.tagStyle | Where-Object {
                        $_.Name -eq 'CustomAddedColor' -and
                        $_.isEnabled -eq $true -and
                        $_.settings.'background-color' -eq '#00564b' -and
                        $_.settings.'color' -eq '#000000'
                    }).Count -eq 1
            } -MockWith { return @{ rules = 'dummyResponse' }
            } -Verifiable

            $inputObject = @{
                localCardConfig         = $localConfig
                team                    = $remoteTeam.Name
                backlogLevel            = 'Stories'
                remoteCardStyleSettings = $remoteSettings
                Organization            = 'contoso'
                Project                 = 'Module Playground'
                removeExcessItems       = $true
                DryRun                  = $false
            }
            { Sync-ProjectTeamCardRuleConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should remove all board designs as expected" {

            $localConfig = @{
                cardStyles = @()
                tagStyles  = @()
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteSettings = @{
                rules = @{
                    fill     = @(
                        @{
                            name      = "Blocked"
                            isEnabled = "True"
                            filter    = "[System.Tags] contains 'Blocked'"
                            settings  = @{
                                'background-color' = "#eeeeee"
                                'title-color'      = "#000000"
                            }
                        },
                        @{
                            name      = "Other"
                            isEnabled = "True"
                            filter    = "[System.Tags] contains 'Other'"
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
                                'background-color' = '#ec001d'
                                color              = '#ffffff'
                            }
                        },
                        @{
                            name      = "Enablement"
                            isEnabled = "True"
                            settings  = @{
                                'background-color' = '#525252'
                                color              = '#ffffff'
                            }
                        }
                    )
                }
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PATCH' -and
                $uri -like "*/cardrulesettings*" -and
                (ConvertFrom-Json $body).rules.fill.count -eq 0 -and
                (ConvertFrom-Json $body).rules.tagStyle.count -eq 0
            } -MockWith { return @{ rules = 'dummyResponse' }
            } -Verifiable

            $inputObject = @{
                localCardConfig         = $localConfig
                team                    = $remoteTeam.Name
                backlogLevel            = 'Stories'
                remoteCardStyleSettings = $remoteSettings
                Organization            = 'contoso'
                Project                 = 'Module Playground'
                removeExcessItems       = $true
                DryRun                  = $false
            }
            { Sync-ProjectTeamCardRuleConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should not fail during dry run" {
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
                        isEnabled = $true
                        color     = "#111111"
                    },
                    @{
                        name  = "CustomAddedColor"
                        color = "#00564b"
                    }
                )
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            $remoteSettings = @{
                rules = @{
                    fill     = @(
                        @{
                            name      = "Blocked"
                            isEnabled = "True"
                            filter    = "[System.Tags] contains 'Blocked'"
                            settings  = @{
                                'background-color' = "#eeeeee"
                                'title-color'      = "#000000"
                            }
                        },
                        @{
                            name      = "Other"
                            isEnabled = "True"
                            filter    = "[System.Tags] contains 'Other'"
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
                                'background-color' = '#ec001d'
                                color              = '#ffffff'
                            }
                        },
                        @{
                            name      = "Enablement"
                            isEnabled = "True"
                            settings  = @{
                                'background-color' = '#525252'
                                color              = '#ffffff'
                            }
                        }
                    )
                }
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            Mock Invoke-RESTCommand -MockWith { throw 'This Mock should not be invoked as this is a dryrun' } -Verifiable

            $inputObject = @{
                localCardConfig         = $localConfig
                team                    = $remoteTeam.Name
                backlogLevel            = 'Stories'
                remoteCardStyleSettings = $remoteSettings
                Organization            = 'contoso'
                Project                 = 'Module Playground'
                removeExcessItems       = $true
                DryRun                  = $true
            }
            { Sync-ProjectTeamCardRuleConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It "Should not attempt any change if matching" {

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
                    },
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

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
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

            Mock Invoke-RESTCommand -MockWith { throw 'This Mock should not be invoked as there are no changes' } -Verifiable

            $inputObject = @{
                localCardConfig         = $localConfig
                team                    = $remoteTeam.Name
                backlogLevel            = 'Stories'
                remoteCardStyleSettings = $remoteSettings
                Organization            = 'contoso'
                Project                 = 'Module Playground'
                removeExcessItems       = $true
                DryRun                  = $false
            }
            { Sync-ProjectTeamCardRuleConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It "Should support dry run without project" {

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
                        isEnabled = $true
                        color     = "#111111"
                    },
                    @{
                        name  = "CustomAddedColor"
                        color = "#00564b"
                    }
                )
            } | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10

            Mock Invoke-RESTCommand -MockWith { throw 'This Mock should not be invoked as this is a dryrun' } -Verifiable

            $inputObject = @{
                localCardConfig         = $localConfig
                team                    = 'Module Playground Team'
                backlogLevel            = 'Stories'
                remoteCardStyleSettings = @{}
                Organization            = 'contoso'
                Project                 = 'Module Playground'
                removeExcessItems       = $true
                DryRun                  = $true
            }
            { Sync-ProjectTeamCardRuleConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw
        }
    }
}