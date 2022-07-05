# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Team] Set-ProjectTeamSetting" -Tag Build {

        It "Should update correct settings" {

            # Test case
            $remoteTeam = @{
                Id   = '1234-5678-9101-1231'
                Name = 'teamToUpdate'
            }
            $settingsToUpdate = @{
                workingDays         = @{
                    workingdays = @("saturday", "sunday")
                    original    = @( "monday", "tuesday", "wednesday", "thursday", "friday" )
                }
                backlogVisibilities = @(
                    @{
                        "Microsoft.FeatureCategory" = $true
                        ref                         = 'Microsoft.FeatureCategory'
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
            $Organization = "Contoso"
            $Project = "ADO-project"
            $DryRun = $false

            # Test setup
            Mock Invoke-RESTCommand -ParameterFilter {
                (ConvertFrom-Json $body).bugsBehavior -eq $settingsToUpdate['bugsBehavior'].bugsBehavior -and
                (-not (Compare-Object -ReferenceObject (ConvertFrom-Json $body).workingDays -DifferenceObject $settingsToUpdate['workingDays'].workingDays)) -and
                (ConvertFrom-Json $body).backlogVisibilities.'Microsoft.FeatureCategory' -eq $true -and
                (ConvertFrom-Json $body).backlogVisibilities.'Custom.4fce2d2f-6498-46ac-8ae5-337ff3d1534e' -eq $false -and
                $uri -like ("*teamsettings*")
            } -Verifiable

            # Test initialization
            $updateInputObject = @{
                Organization     = $Organization
                Project          = $Project
                remoteTeam       = $remoteTeam
                settingsToUpdate = $settingsToUpdate
                DryRun           = $DryRun
            }
            { Set-ProjectTeamSetting @updateInputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }

        It "Should update correct settings - Dry run" {

            # Test case
            $remoteTeam = [PSCustomObject]@{
                Id   = '1234-5678-9101-1231'
                Name = 'teamToUpdate'
            }
            $settingsToUpdate = @{
                workingDays         = @{
                    workingdays = @("saturday", "sunday")
                    original    = @( "monday", "tuesday", "wednesday", "thursday", "friday" )
                }
                backlogVisibilities = @(
                    @{
                        "Microsoft.FeatureCategory" = $true
                        ref                         = 'Microsoft.FeatureCategory'
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
            $Organization = "Contoso"
            $Project = "ADO-project"
            $DryRun = $true

            # Test setup
            Mock Invoke-RESTCommand -MockWith { throw "This function should not be invoked" }

            # Test initialization
            $updateInputObject = @{
                Organization     = $Organization
                Project          = $Project
                remoteTeam       = $remoteTeam
                settingsToUpdate = $settingsToUpdate
                DryRun           = $DryRun
            }
            { Set-ProjectTeamSetting @updateInputObject -ErrorAction 'Stop' } | Should -Not -Throw
        }
    }
}