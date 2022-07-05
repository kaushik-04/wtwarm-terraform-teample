# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] Sync-ProjectTeamBoardRowConfig" -Tag Build {

        It "Should set additional rows as expected" {

            $localRowConfig = @('row1', 'row2')

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            $remoteBoardSettings = @{
                rows = @(
                    @{
                        id   = "00000000-0000-0000-0000-000000000000"
                        name = $null
                    },
                    @{
                        id   = "54ad742c-0986-4bff-8173-8e08b6f3d71d"
                        name = "remote1"
                    },
                    @{
                        id   = "6b53ba78-0064-4b56-8e1c-0543607d1c65"
                        name = "remote2"
                    }
                )
            }

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PUT' -and
                $uri -like "*/rows*" -and
                (ConvertFrom-Json $body).count -eq 5 -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq $null }) -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'row1' }) -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'row2' }) -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'remote1' }) -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'remote2' })
            } -MockWith { return @{ value = 'dummyResponse' } } -Verifiable


            $inputObject = @{
                localRowConfig      = $localRowConfig
                team                = $remoteTeam.Name
                backlogLevel        = 'Stories'
                remoteBoardSettings = $remoteBoardSettings
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $false
                DryRun              = $false
            }
            { Sync-ProjectTeamBoardRowConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw
            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should set desired rows state (DSC) as expected" {

            $localRowConfig = @('row1', 'row2')

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            $remoteBoardSettings = @{
                rows = @(
                    @{
                        id   = "00000000-0000-0000-0000-000000000000"
                        name = $null
                    },
                    @{
                        id   = "54ad742c-0986-4bff-8173-8e08b6f3d71d"
                        name = "remote1"
                    },
                    @{
                        id   = "6b53ba78-0064-4b56-8e1c-0543607d1c65"
                        name = "remote2"
                    }
                )
            }

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PUT' -and
                $uri -like "*/rows*" -and
                (ConvertFrom-Json $body).count -eq 3 -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq $null }) -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'row1' }) -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq 'row2' })
            } -MockWith { return @{ value = 'dummyResponse' } } -Verifiable

            $inputObject = @{
                localRowConfig      = $localRowConfig
                team                = $remoteTeam.Name
                backlogLevel        = 'Stories'
                remoteBoardSettings = $remoteBoardSettings
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $true
                DryRun              = $false
            }
            { Sync-ProjectTeamBoardRowConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw
            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should remove all but required as expected" {

            $localRowConfig = @()

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            $remoteBoardSettings = @{
                rows = @(
                    @{
                        id   = "00000000-0000-0000-0000-000000000000"
                        name = $null
                    },
                    @{
                        id   = "54ad742c-0986-4bff-8173-8e08b6f3d71d"
                        name = "remote1"
                    },
                    @{
                        id   = "6b53ba78-0064-4b56-8e1c-0543607d1c65"
                        name = "remote2"
                    }
                )
            }

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'PUT' -and
                $uri -like "*/rows*" -and
                (ConvertFrom-Json $body).count -eq 1 -and
                ((ConvertFrom-Json $body) | Where-Object { $_.Name -eq $null })
            } -MockWith { return @{ value = 'dummyResponse' } } -Verifiable

            $inputObject = @{
                localRowConfig      = $localRowConfig
                team                = $remoteTeam.Name
                backlogLevel        = 'Stories'
                remoteBoardSettings = $remoteBoardSettings
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $true
                DryRun              = $false
            }
            { Sync-ProjectTeamBoardRowConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw
            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should not fail during dry run" {

            $localRowConfig = @('row1', 'row2')

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            $remoteBoardSettings = @{
                rows = @(
                    @{
                        id   = "00000000-0000-0000-0000-000000000000"
                        name = $null
                    },
                    @{
                        id   = "54ad742c-0986-4bff-8173-8e08b6f3d71d"
                        name = "remote1"
                    },
                    @{
                        id   = "6b53ba78-0064-4b56-8e1c-0543607d1c65"
                        name = "remote2"
                    }
                )
            }

            Mock Invoke-RESTCommand -MockWith { throw 'This Mock should not be invoked as this is a dry run' } -Verifiable


            $inputObject = @{
                localRowConfig      = $localRowConfig
                team                = $remoteTeam.Name
                backlogLevel        = 'Stories'
                remoteBoardSettings = $remoteBoardSettings
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $true
                DryRun              = $true
            }
            { Sync-ProjectTeamBoardRowConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It "Should not attempt any change if matching" {

            $localRowConfig = @('remote1', 'remote2')

            $remoteTeam = @{
                id   = 99
                name = 'Module Playground Team'
            }

            $remoteBoardSettings = @{
                rows = @(
                    @{
                        id   = "00000000-0000-0000-0000-000000000000"
                        name = $null
                    },
                    @{
                        id   = "54ad742c-0986-4bff-8173-8e08b6f3d71d"
                        name = "remote1"
                    },
                    @{
                        id   = "6b53ba78-0064-4b56-8e1c-0543607d1c65"
                        name = "remote2"
                    }
                )
            }

            Mock Invoke-RESTCommand -MockWith { throw 'This Mock should not be invoked as no changes are necessary' } -Verifiable

            $inputObject = @{
                localRowConfig      = $localRowConfig
                team                = $remoteTeam.Name
                backlogLevel        = 'Stories'
                remoteBoardSettings = $remoteBoardSettings
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $false
                DryRun              = $false
            }
            { Sync-ProjectTeamBoardRowConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It "Should support dry run without project" {

            $localRowConfig = @('row1', 'row2')

            $remoteTeam = @{
                id   = 0
                name = 'Module Playground Team'
            }

            $remoteBoardSettings = @{}

            Mock Invoke-RESTCommand -MockWith { throw 'This Mock should not be invoked as no project exists' } -Verifiable

            $inputObject = @{
                localRowConfig      = $localRowConfig
                team                = $remoteTeam.Name
                backlogLevel        = 'Stories'
                remoteBoardSettings = $remoteBoardSettings
                Organization        = 'contoso'
                Project             = 'Module Playground'
                removeExcessItems   = $false
                DryRun              = $true
            }
            { Sync-ProjectTeamBoardRowConfig @inputObject -ErrorAction 'Stop' } | Should -Not -Throw
        }
    }
}