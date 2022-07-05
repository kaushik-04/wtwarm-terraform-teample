# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] Confirm-TeamIsEqual" -Tag Build {

        $remoteTeamSettings = [PSCustomObject]@{
            backlogVisibilities = @{
                "Custom.4fce2d2f-6498-46ac-8ae5-337ff3d1534e" = $true
                "Microsoft.EpicCategory"                      = $false
                "Microsoft.FeatureCategory"                   = $false
                "Microsoft.RequirementCategory"               = $false
            }
            bugsBehavior        = "off"
            workingDays         = @(
                "monday",
                "tuesday",
                "wednesday",
                "thursday",
                "friday"
            )
        }

        $testcases = @(
            @{
                project            = 'Module Playground'
                organization       = 'contoso'
                localTeamConfig    = @{
                    Id            = '1234'
                    Name          = 'titleA'
                    boardSettings = @{
                        workingDays         = @(
                            "saturday",
                            "sunday"
                        )
                        backlogVisibilities = @{
                            "Microsoft.EpicCategory"    = $false
                            "Microsoft.FeatureCategory" = $true
                            "agile-product-management"  = $false
                        }
                        bugsBehavior        = "asTasks"
                    }
                }
                remoteTeam         = @{
                    Id   = '1234'
                    Name = 'titleA'
                }
                remoteTeamSettings = $remoteTeamSettings
                remoteWitBehaviors = @( @{
                        name          = 'agile-product-management'
                        referenceName = 'Custom.4fce2d2f-6498-46ac-8ae5-337ff3d1534e'
                    } )
                expected           = @{
                    workingDays         = @{
                        workingdays = @("saturday", "sunday")
                        original    = @( "monday", "tuesday", "wednesday", "thursday", "friday" )
                    }
                    backlogVisibilities = @(
                        @{
                            "Microsoft.FeatureCategory" = $true
                            ref                         = "Microsoft.FeatureCategory"
                            original                    = $false
                        },
                        @{
                            "agile-product-management" = $false
                            ref                        = 'Custom.4fce2d2f-6498-46ac-8ae5-337ff3d1534e'
                            original                   = $true
                        }
                    )
                    bugsBehavior        = @{
                        bugsBehavior = 'asTasks'
                        original     = 'off'
                    }
                }
            },
            @{
                project            = 'Module Playground'
                organization       = 'contoso'
                localTeamConfig    = @{
                    Id            = '1234'
                    Name          = 'titleA'
                    boardSettings = @{
                        backlogVisibilities = @{
                            "agile-product-management"  = $true
                        }
                    }
                }
                remoteTeam         = @{
                    Id   = '1234'
                    Name = 'titleA'
                }
                remoteTeamSettings = $remoteTeamSettings
                remoteWitBehaviors = @( @{
                        name          = 'agile-product-management'
                        referenceName = 'Custom.4fce2d2f-6498-46ac-8ae5-337ff3d1534e'
                    } )
                expected           = @{
                }
            }
        )
        It "Should find team settings to update" -TestCases $testcases {

            param (
                [PSCustomObject] $localTeamConfig,
                [PSCustomObject] $remoteTeam,
                [PSCustomObject] $remoteTeamSettings,
                [PSCustomObject[]] $remoteWitBehaviors,
                [hashtable] $expected
            )

            $localTeamConfig = ConvertTo-Json $localTeamConfig | ConvertFrom-Json
            $remoteTeam = ConvertTo-Json $remoteTeam | ConvertFrom-Json
            $remoteTeamSettings = ConvertTo-Json $remoteTeamSettings | ConvertFrom-Json
            $remoteWitBehaviors = ConvertTo-Json $remoteWitBehaviors | ConvertFrom-Json

            $settingsToUpdate = Get-ProjectTeamSettingsToUpdate -localTeam $localTeamConfig -remoteTeam $remoteTeam -remoteTeamSettings $remoteTeamSettings -remoteWitBehaviors $remoteWitBehaviors

            if ($expected.Keys.count -gt 0) {
                $settingsToUpdate | Should -Not -BeNullOrEmpty
            }

            # Test work days
            if ($expected.ContainsKey('workingDays')) {
                $settingsToUpdate.Keys | Should -Contain 'workingDays'

                foreach ($expectedWorkday in $expected['workingDays'].workingdays) {
                    ($settingsToUpdate['workingDays'].workingDays) | Should -Contain $expectedWorkday
                }
            }else {
                $settingsToUpdate.Keys | Should -not -Contain 'workingDays'
            }

            # Test backlog visibility
            if ($expected.ContainsKey('backlogVisibilities')) {
                $settingsToUpdate.Keys | Should -Contain 'backlogVisibilities'
                foreach ($visiblityItem in $settingsToUpdate.backlogVisibilities) {
                    $itemKey = $visiblityItem.Keys | Where-Object { $_ -notin @('original', 'ref') }
                    $matchingExpected = $expected.backlogVisibilities | Where-Object { $null -ne $_.$itemKey }
                    $matchingExpected | Should -Not -BeNullOrEmpty
                    $matchingExpected.ref | Should -Not -BeNullOrEmpty
                    $visiblityItem[$itemKey] | Should -Be $matchingExpected[$itemKey]
                }
            } else {
                $settingsToUpdate.Keys | Should -not -Contain 'backlogVisibilities'
            }

            # Test Bug Behavior
            if ($expected.ContainsKey('bugsBehavior')) {
                $settingsToUpdate.Keys | Should -Contain 'bugsBehavior'
                $settingsToUpdate['bugsBehavior'].bugsBehavior | Should -Be $expected['bugsBehavior'].bugsBehavior
            }
            else {
                $settingsToUpdate.Keys | Should -not -Contain 'bugsBehavior'
            }
        }
    }
}
