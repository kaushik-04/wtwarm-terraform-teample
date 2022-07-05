<#
.SYNOPSIS
Sync the area path settings for the given team

.DESCRIPTION
Sync the area path settings for the given team

.PARAMETER localTeamAreaConfig
Mandatory. The local area path configuration to set. E.g. @{ defaultValue = 'area1'; values = @(@{ value = 'Area 1', includeChildren = false }) }

.PARAMETER remoteTeam
Mandatory. The team to set the settings for

.PARAMETER Organization
Mandatory. The organization hosting the project to configure. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project hosting the team to configure. E.g. 'Module Playground'

.PARAMETER removeExcessItems
Optional. Control whether or not to remove areas from those available that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-ProjectTeamAreaConfig -organization 'contoso' -project 'Module Playground' -remoteTeam @{ id = 1; name = 'teamToUpdate' } -localTeamAreaConfig @{ defaultValue = 'area1'; values = @(@{ value = 'Area 1', includeChildren = false }) }

Sync the area configuration for team [contoso|Module Playground|teamToUpdate]. Sets 'Area 1' as default iteration and add it to the set of available areas to pick from.
#>
function Sync-ProjectTeamAreaConfig {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $localTeamAreaConfig,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteTeam,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    # Format local area config names (are root prefix)
    ## DefaultValue
    if ($localTeamAreaConfig.defaultValue -ne $project -and $localTeamAreaConfig.defaultValue -notlike "$project\*" -and $localTeamAreaConfig.defaultValue -notlike "$project/*") {
        $localTeamAreaConfig.defaultValue = "{0}\{1}" -f $project, $localTeamAreaConfig.defaultValue
    }
    ## Available items
    foreach ($valuesItem in $localTeamAreaConfig.values) {
        if ($valuesItem.value -ne $project -and $valuesItem.value -notlike "$project\*" -and $valuesItem.value -notlike "$project/*") {
            $valuesItem.value = "{0}\{1}" -f $project, $valuesItem.value
        }
    }

    ## Output object
    if ($remoteTeamAreasConfiguration = Get-ProjectTeamSettingFieldValue -Organization $Organization -Project $Project -Team $remoteTeam.Name -DryRun:$DryRun) {
        $remoteValues = $remoteTeamAreasConfiguration.values | ForEach-Object { @{ value = $_.value; includeChildren = $_.includeChildren } }
        $output = @{
            defaultValue = $remoteTeamAreasConfiguration.DefaultValue
            values       = ($remoteValues -is [array]) ? $remoteValues : @($remoteValues)
        }
    } else {
        $output = @{
            defaultValue = ''
            values       = @()
        }
    }

    # Trigger indicating we want to overwrite the current area state
    $triggerOverwrite = $false

    # Process Default Area
    # ====================
    if ($output.DefaultValue -ne $localTeamAreaConfig.defaultValue) {
        if ($dryRun) {
            $dryRunUpdateActions = [System.Collections.ArrayList]@(
                @{
                    Op             = '^'
                    Team           = $remoteTeam.Name
                    'Default Area' = "[{0} => {1}]" -f (($output.DefaultValue) ? $output.DefaultValue : '()'), $localTeamAreaConfig.defaultValue
                }

            )
            if ($dryRunUpdateActions.count -gt 0) {
                $dryRunString = "`n`nWould update defaultValue team area:"
                $dryRunString += "`n===================================="

                $columns = @('#', 'Op') + ($dryRunUpdateActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op') })
                $dryRunUpdateActionsCount = 1
                $dryRunString += ($dryRunUpdateActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                        $_ | Select-Object @{Name = '#'; Expression = { $dryRunUpdateActionsCount } }, *
                        $dryRunUpdateActionsCount++
                    } | Format-Table $columns -AutoSize | Out-String)
                Write-Verbose $dryRunString -Verbose
            }
        }
        else {
            $output.defaultValue = $localTeamAreaConfig.defaultValue
            $triggerOverwrite = $true
        }
    }

    # Add Areas
    # ---------
    if ($areasToAdd = $localTeamAreaConfig.values | Where-Object { $_.value -notin $output.values.value }) {
        if ($DryRun) { $dryRunAddAreaActions = [System.Collections.ArrayList]@() }
        foreach ($areaToAdd in $areasToAdd) {

            if ($dryRun) {
                $dryAction = @{
                    Op                 = '+'
                    Team               = $remoteTeam.Name
                    'Area'             = $areaToAdd.value
                    'Include Children' = $areaToAdd.includeChildren
                }
                $null = $dryRunAddAreaActions.Add($dryAction)
            }
            else {
                $output.values += @{
                    value           = $areaToAdd.value
                    includeChildren = $areaToAdd.includeChildren
                }
                $triggerOverwrite = $true
            }
        }

        if ($dryRunAddAreaActions.count -gt 0) {
            $dryRunString = "`n`nWould add team areas:"
            $dryRunString += "`n====================="

            $columns = @('#', 'Op') + ($dryRunAddAreaActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op') })
            $dryRunAddAreaActionsCount = 1
            $dryRunString += ($dryRunAddAreaActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                    $_ | Select-Object @{Name = '#'; Expression = { $dryRunAddAreaActionsCount } }, *
                    $dryRunAddAreaActionsCount++
                } | Format-Table $columns -AutoSize | Out-String)
            Write-Verbose $dryRunString -Verbose
        }
    }

    # Process Areas List
    # ==================
    # Remove Areas
    # ------------
    if ($removeExcessItems) {

        if ($areasToRemove = $output.values | Where-Object { $_.value -notin $localTeamAreaConfig.values.value }) {
            if ($DryRun) {
                $dryRunRemovalActions = [System.Collections.ArrayList]@()
                foreach ($areaToRemove in $areasToRemove) {
                    $dryAction = @{
                        Op   = '-'
                        Team = $remoteTeam.Name
                        Area = $areasToRemove.value
                    }
                    $null = $dryRunRemovalActions.Add($dryAction)
                }
                if ($dryRunRemovalActions.count -gt 0) {
                    $dryRunString = "`n`nWould remove team areas:"
                    $dryRunString += "`n========================"

                    $columns = @('#', 'Op') + ($dryRunRemovalActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op') })
                    $dryRunRemovalActionsCount = 1
                    $dryRunString += ($dryRunRemovalActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                            $_ | Select-Object @{Name = '#'; Expression = { $dryRunRemovalActionsCount } }, *
                            $dryRunRemovalActionsCount++
                        } | Format-Table $columns -AutoSize | Out-String)
                    Write-Verbose $dryRunString -Verbose
                }
            }

            # Overwrite output object
            $output.values = $output.values | Where-Object { $_.value -notin $areasToRemove.value }
            $triggerOverwrite = $true
        }
        else {
            Write-Verbose "No areas to remove"
        }
    }

    # Update Areas (include children)
    # -------------------------------
    if ($DryRun) { $dryRunUpdateAreaActions = [System.Collections.ArrayList]@() }
    foreach ($remoteConfiguration in $output.values) {
        $matchingLocal = $localTeamAreaConfig.values | Where-Object { $_.value -eq $remoteConfiguration.value }

        if ($matchingLocal -and ($matchingLocal.includeChildren -ne $remoteConfiguration.includeChildren)) {
            if ($dryRun) {
                $dryAction = @{
                    Op                 = '^'
                    Team               = $remoteTeam.Name
                    'Area Value'       = $matchingLocal.value
                    'Include Children' = "[{0} => {1}]" -f $remoteConfiguration.includeChildren , $matchingLocal.includeChildren
                }
                $null = $dryRunUpdateAreaActions.Add($dryAction)
            }
            else {
                $remoteConfiguration.includeChildren = $matchingLocal.includeChildren
                $triggerOverwrite = $true
            }
        }
    }
    if ($dryRunUpdateAreaActions.count -gt 0) {
        $dryRunString = "`n`nWould update team area values:"
        $dryRunString += "`n=============================="

        $columns = @('#', 'Op', 'Team', 'Area Value') + ($dryRunUpdateAreaActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Team', 'Area Value') })
        $dryRunUpdateAreaActionsCount = 1
        $dryRunString += ($dryRunUpdateAreaActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunUpdateAreaActionsCount } }, *
                $dryRunUpdateAreaActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }

    if ($triggerOverwrite -and -not $dryrun) {
        #format body
        $body = @{
            defaultValue = $output.defaultValue
            values       = (($output.values -is [array]) ? $output.values : @($output.values))
        }

        # build request
        $restInfo = Get-RelativeConfigData -configToken 'RESTTeamSettingsFieldValuesSet'
        $restInputObject = @{
            method = $restInfo.method
            uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), $remoteTeam.id)
            body   = ConvertTo-Json $body -Depth 10 -Compress
        }

        if ($PSCmdlet.ShouldProcess(('REST command to update team [{0}]' -f $team.Name), "Invoke")) {
            $updateCommandResponse = Invoke-RESTCommand @restInputObject
            if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                Write-Error ('Failed to update area configuration for team [{0}] because of [{1} - {2}].' -f $remoteTeam.Name, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                continue
            }
            else {
                Write-Verbose ("[^] Successfully updated area configuration for team [{0}]" -f $remoteTeam.name) -Verbose
            }
        }
    }
}