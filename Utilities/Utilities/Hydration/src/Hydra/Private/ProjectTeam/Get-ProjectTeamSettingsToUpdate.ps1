<#
.SYNOPSIS
Get the team setting properties to update

.DESCRIPTION
Get an object with the team setting properties to update - excluding area & iteration properties

.PARAMETER localTeam
Mandatory. The local team configuration

.PARAMETER remoteTeam
Mandatory. A second team to compare with

.PARAMETER remoteTeamSettings
Mandatory. The team settings of the second team

.PARAMETER remoteWitBehaviors
Optional. The work item type behaviors for the teams project type. Required if the backlog visibility is configured for the team

.EXAMPLE
Get-ProjectTeamSettingsToUpdate -localTeam @{ name = 'primTeam'; settings = @{ workingdays = @( 'Monday', 'Tuesday') } } -remoteTeam @{ id = 1; name = 'remTeam' } -remoteTeamSettings @{ workingDays = @( 'Monday' ) }

Evaluate the local team settings configuration against the provided remote team settings. The given example would return an object indicating the update of the 'working days'
#>
function Get-ProjectTeamSettingsToUpdate {

    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $localTeam,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteTeam,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteTeamSettings,

        [Parameter(Mandatory = $false)]
        [PSCustomObject[]] $remoteWitBehaviors
    )

    $propertiesToUpdate = @{}

    # Work days
    if ($localTeam.boardSettings.workingDays) {
        if (-not $remoteTeamSettings.workingDays) {
            $propertiesToUpdate['workingDays'] = @{
                workingDays = $localTeam.boardSettings.workingDays
                original    = '()'
            }
        }
        elseif ((Compare-Object -ReferenceObject $localTeam.boardSettings.workingDays -DifferenceObject $remoteTeamSettings.workingDays)) {
            $propertiesToUpdate['workingDays'] = @{
                workingDays = $localTeam.boardSettings.workingDays
                original    = $remoteTeamSettings.workingDays
            }
        }
    }

    # Backlog visibilities
    if ($localTeam.boardSettings.backlogVisibilities) {

        $backlogVisibilities = [System.Collections.ArrayList] @()
        foreach ($backlogVisiblityKey in ($localTeam.boardSettings.backlogVisibilities | Get-Member -MemberType 'NoteProperty').Name) {
            $localVisibility = $localTeam.boardSettings.backlogVisibilities.$backlogVisiblityKey
            if ($backlogVisiblityKey -notlike "Microsoft.*") {
                $witBehavior = $remoteWitBehaviors | Where-Object { $_.name -eq $backlogVisiblityKey }
                if (-not $witBehavior) {
                    Write-Warning ("Unable to find backlog level [{0}] when processing team [{1}|{2}]" -f $backlogVisiblityKey, $Project, $remoteTeam.Name)
                    continue
                }

                $remoteVisbility = $remoteTeamSettings.backlogVisibilities.($witBehavior.referenceName)
                if ($localVisibility -ne $remoteVisbility) {
                    $null = $backlogVisibilities.Add(@{
                            $backlogVisiblityKey = $localVisibility
                            ref                  = $witBehavior.referenceName
                            original             = $remoteVisbility
                        })
                }
            }
            else {
                if ($localVisibility -ne $remoteTeamSettings.backlogVisibilities.$backlogVisiblityKey) {
                    $null = $backlogVisibilities.Add(@{
                            $backlogVisiblityKey = $localVisibility
                            ref                  = $backlogVisiblityKey
                            original             = $remoteTeamSettings.backlogVisibilities.$backlogVisiblityKey
                        })
                }
            }
        }

        if ($backlogVisibilities.Count -gt 0) {
            $propertiesToUpdate['backlogVisibilities'] = $backlogVisibilities
        }
    }

    # Bugs Behavior
    if ((([PSCustomObject]$localTeam.boardSettings).Psobject.Properties.name -contains 'bugsBehavior') -and $localTeam.boardSettings.bugsBehavior -ne $remoteTeamSettings.bugsBehavior) {
        $propertiesToUpdate['bugsBehavior'] = @{
            bugsBehavior = $localTeam.boardSettings.bugsBehavior
            original     = $remoteTeamSettings.bugsBehavior
        }
    }

    return $propertiesToUpdate
}