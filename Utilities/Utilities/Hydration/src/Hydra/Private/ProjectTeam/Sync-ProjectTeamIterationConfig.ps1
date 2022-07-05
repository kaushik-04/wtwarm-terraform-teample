<#
.SYNOPSIS
Sync the project settings with regards to its iteration configuration for the given team

.DESCRIPTION
Sync the project settings with regards to its iteration configuration for the given team

.PARAMETER localTeamIterationConfig
Mandatory. The local iteration configuration to set

.PARAMETER remoteTeam
Mandatory. The team to set the settings for

.PARAMETER Organization
Mandatory. The organization hosting the project to configure. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project hosting the team to configure. E.g. 'Module Playground'

.PARAMETER RemoteTeamSettings
Mandatory. The current team settings

.PARAMETER removeExcessItems
Optional. Control whether or not to remove iterations from those available that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-ProjectTeamIterationConfig -organization 'contoso' -project 'Module Playground' -remoteTeam @{ id = 1; name = 'teamToUpdate' } -localTeamIterationConfig @{ defaultValue = 'iteration1'; backlog = 'iteration2'; values = @('iteration1','iteration2') } -RemoteTeamSettings @{...}

Sync the iteration configuration for team [contoso|Module Playground|teamToUpdate]. Sets 'iteration1' as default iteration, 'iteration2' as backlog iteration & both as available iterations to pick from.
#>
function Sync-ProjectTeamIterationConfig {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $localTeamIterationConfig,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteTeam,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteTeamSettings,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($remoteIterationList = Get-ProjectIterationList -Organization $Organization -Project $project) {
        $flatRemoteIterations = Resolve-ClassificationNodesFormatted -Nodes $remoteIterationList
    }
    else {
        $flatRemoteIterations = @()
    }

    # Format Local Settings
    # ---------------------

    # Default Iteration
    if ($localTeamIterationConfig.defaultValue -match (Get-RelativeConfigData -configToken 'RegexGUID')) {
        $matchingRemoteDefault = $flatRemoteIterations | Where-Object { $_.Id -eq $localTeamIterationConfig.defaultValue }
        if (-not $matchingRemoteDefault) {
            if ($dryRun -and -not $flatRemoteIterations) {
                $matchingRemoteDefault = @{
                    id   = 0
                    name = $localTeamIterationConfig.defaultValue
                }
            }
            else {
                Write-Error ("Configured default iteration [{0}] for team [{1}|{2}] does not exist" -f $localTeamIterationConfig.defaultValue, $project, $remoteTeam.Name )
            }
        }
    }
    else {
        $matchingRemoteDefault = $flatRemoteIterations | Where-Object { $_.Name -eq $localTeamIterationConfig.defaultValue }
        if (-not $matchingRemoteDefault) {
            if ($dryRun -and -not $flatRemoteIterations) {
                $matchingRemoteDefault = @{
                    id   = 0
                    name = $localTeamIterationConfig.defaultValue
                }
            }
            else {
                Write-Error ("Configured default iteration [{0}] for team [{1}|{2}] does not exist" -f $localTeamIterationConfig.defaultValue, $project, $remoteTeam.Name )
            }
        }
    }
    $localTeamIterationConfig | Add-Member -NotePropertyName 'defaultValueId' -NotePropertyValue $matchingRemoteDefault.identifier
    $localTeamIterationConfig | Add-Member -NotePropertyName 'defaultValueName' -NotePropertyValue $matchingRemoteDefault.Name

    # Backlog Iteration
    if ($localTeamIterationConfig.backlog -match (Get-RelativeConfigData -configToken 'RegexGUID')) {
        $matchingRemoteBacklog = $flatRemoteIterations | Where-Object { $_.id -eq $localTeamIterationConfig.backlog }
        if (-not $matchingRemoteBacklog) {
            if ($dryRun -and -not $flatRemoteIterations) {
                $matchingRemoteBacklog = @{
                    id   = 0
                    name = $localTeamIterationConfig.backlog
                }
            }
            else {
                Write-Error ("Configured backlog iteration [{0}] for team [{1}|{2}] does not exist" -f $localTeamIterationConfig.backlog, $project, $remoteTeam.Name )
            }
        }
    }
    else {
        $matchingRemoteBacklog = $flatRemoteIterations | Where-Object { $_.Name -eq $localTeamIterationConfig.backlog }
        if (-not $matchingRemoteBacklog) {
            if ($dryRun -and -not $flatRemoteIterations) {
                $matchingRemoteBacklog = @{
                    id   = 0
                    name = $localTeamIterationConfig.backlog
                }
            }
            else {
                Write-Error ("Configured backlog iteration [{0}] for team [{1}|{2}] does not exist" -f $localTeamIterationConfig.backlog, $project, $remoteTeam.Name )
            }
        }
    }
    $localTeamIterationConfig | Add-Member -NotePropertyName 'backlogId' -NotePropertyValue $matchingRemoteBacklog.identifier
    $localTeamIterationConfig | Add-Member -NotePropertyName 'backlogName' -NotePropertyValue $matchingRemoteBacklog.Name


    # Process Default Settings
    # ------------------------
    $triggerProjectSettingsOverwrite = $false

    $defaultBody = @{
        defaultIteration = $remoteTeamSettings.defaultIteration.id
        backlogIteration = $remoteTeamSettings.backlogIteration.id
    }

    $dryRunUpdateActions = [System.Collections.ArrayList]@()

    # Default iteration
    if ((-not $remoteTeamSettings.defaultIteration.id) -or ($remoteTeamSettings.defaultIteration.id -ne $localTeamIterationConfig.defaultValueId)) {
        if ($dryRun) {
            $null = $dryRunUpdateActions += @{
                Op                  = '^'
                Team                = $remoteTeam.Name
                'Default Iteration' = "[{0} => {1}]" -f (($remoteTeamSettings.defaultIteration.Name) ? $remoteTeamSettings.defaultIteration.Name : '()'), $localTeamIterationConfig.defaultValueName
            }
        }
        else {
            $defaultBody.defaultIteration = $localTeamIterationConfig.defaultValueId
            $triggerProjectSettingsOverwrite = $true
        }
    }
    # Backlog iteration
    if ((-not $remoteTeamSettings.backlogIteration.id) -or ($remoteTeamSettings.backlogIteration.id -ne $localTeamIterationConfig.backlogId)) {
        if ($dryRun) {
            $null = $dryRunUpdateActions += @{
                Op                  = '^'
                Team                = $remoteTeam.Name
                'Backlog Iteration' = "[{0} => {1}]" -f (($remoteTeamSettings.backlogIteration.Name) ? $remoteTeamSettings.backlogIteration.Name : '()'), $localTeamIterationConfig.backlogName
            }
        }
        else {
            $defaultBody.backlogIteration = $localTeamIterationConfig.backlogId
            $triggerProjectSettingsOverwrite = $true
        }
    }

    if ($dryRunUpdateActions.count -gt 0) {
        $dryRunString = "`n`nWould update team iteration settings:"
        $dryRunString += "`n====================================="

        $columns = @('#', 'Op', 'Team') + ($dryRunUpdateActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Team') })
        $dryRunUpdateActionsCount = 1
        $dryRunString += ($dryRunUpdateActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunUpdateActionsCount } }, *
                $dryRunUpdateActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }

    if ($triggerProjectSettingsOverwrite) {

        $restInfo = Get-RelativeConfigData -configToken 'RESTTeamSettingsSet'
        $restInputObject = @{
            method = $restInfo.method
            uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), $remoteTeam.id)
            body   = ConvertTo-Json $defaultBody -Depth 10 -Compress
        }

        if ($PSCmdlet.ShouldProcess(('REST command to update settings of team [{0}]' -f $team.Name), "Invoke")) {
            $updateCommandResponse = Invoke-RESTCommand @restInputObject
            if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                Write-Error ('Failed to update settings for team [{0}] because of [{1} - {2}]. Make sure the team does exist.' -f $team.Name, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                continue
            }
            else {
                Write-Verbose ("[^] Successfully updated settings for team [{0}]" -f $remoteTeam.name) -Verbose
            }
        }
    }

    # Process available iterations
    # ============================
    $remoteAvailableTeamIterationsList = Get-ProjectTeamSettingIterationList -Organization $Organization -Project $Project -Team $remoteTeam.Name

    # Add Iterations
    # --------------
    if ($iterationsToAdd = $localTeamIterationConfig.values | Where-Object { $_ -notin $remoteAvailableTeamIterationsList.name } ) {

        # find matching iteration objects
        $matchingRemoteIterationsToAdd = $flatRemoteIterations | Where-Object { $_.Name -in $iterationsToAdd }
        if ($missingIterations = $iterationsToAdd | Where-Object { $flatRemoteIterations.Name -notcontains $_ }) {
            if ($dryRun) {
                $matchingRemoteIterationsToAdd = $iterationsToAdd | ForEach-Object { @{ name = $_; identifier = '-1'} }
            }
            else {
                Write-Error ("Configured team setting iterations [{0}] for team [{1}|{2}] do not exist" -f ($missingIterations -join (', ')), $project, $remoteTeam.Name )
            }
        }

        $newIterationInputObject = @{
            iterationsToAdd = $matchingRemoteIterationsToAdd
            remoteTeam      = $remoteTeam
            Organization    = $Organization
            Project         = $project
            DryRun          = $dryRun
        }
        New-ProjectTeamSettingIterationRange @newIterationInputObject
        start-sleep 10 # Wait for propagation
    }
    else {
        Write-Verbose ("No iterations to add to project settings of team [{0}]" -f $project, $remoteTeam.Name)
    }

    if ($removeExcessItems) {
        # Remove Iterations
        # -----------------
        if ($iterationsRemove = $remoteAvailableTeamIterationsList | Where-Object { $_.Name -notin $localTeamIterationConfig.values } ) {
            $newIterationInputObject = @{
                iterationsRemove = $iterationsRemove
                remoteTeam       = $remoteTeam
                Organization     = $Organization
                Project          = $project
                DryRun           = $dryRun
            }
            Remove-ProjectTeamSettingIterationRange @newIterationInputObject
        }
        else {
            Write-Verbose ("No iterations to remove from project settings of team [{0}]" -f $project, $remoteTeam.Name)
        }
    }
}