<#
.SYNOPSIS
Sync the local card & tag style configuration(s) for a given team & backlog level

.DESCRIPTION
Sync the local card & tag style configuration(s) for a given team & backlog level

.PARAMETER localCardConfig
Mandatory. The local card & tag configuration

.PARAMETER remoteCardStyleSettings
Mandatory. The current remote card & tag configuration in Azure DevOps

.PARAMETER team
Mandatory. The team to set the configuration for

.PARAMETER backlogLevel
Mandatory. The backlog level of the team to set the configuration for

.PARAMETER Organization
Mandatory. The organization hosting the project to configure. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project hosting the team to configure. E.g. 'Module Playground'

.PARAMETER removeExcessItems
Optional. Control whether or not to remove tag & card rules from those available that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-ProjectTeamCardRuleConfig -organization 'contoso' -project 'Module Playground' -team 'Module Playground team' -backlogLevel 'Epics' -localCardConfig @{ cardStyles = @(...); tagStyles = @(...) } -remoteCardStyleSettings @{ rules = @{ fill = @(...); tagStyle = @(...) } }

Sync the card & tag style config for the team 'Module Playground team' & level 'Epics'
#>
function Sync-ProjectTeamCardRuleConfig {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [PSCustomObject] $localCardConfig,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteCardStyleSettings,

        [Parameter(Mandatory = $true)]
        [string] $team,

        [Parameter(Mandatory = $true)]
        [string] $backlogLevel,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if (Test-ProjectTeamCardRuleConfigEqualsState -localCardConfig $localCardConfig -remoteCardStyleSettings $remoteCardStyleSettings) {
        # No changes, skip
        Write-Verbose "No card rules to change"
        return
    }

    if ($DryRun) {

        # Cards
        # -----
        if ($localCardConfig.PSObject.Properties.name -contains 'cardStyles') {
            $cardDryRunActions = [System.Collections.ArrayList]@()

            # add create actions
            foreach ($cardStyle in $localCardConfig.cardStyles | Where-Object { $_.Name -notin $remoteCardStyleSettings.rules.fill.name }) {
                $dryRunAction = @{
                    Op              = '+'
                    Team            = $team
                    'Backlog Level' = $backlogLevel
                    Card            = $cardStyle.Name
                    Filter          = $cardStyle.filter
                }

                $dryRunAction['Enabled'] = (([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isEnabled') ? [System.Convert]::ToBoolean($cardStyle.isEnabled) : $true

                $dryRunAction['Background color'] = ($cardStyle.backgroundColor) ? $cardStyle.backgroundColor : (Get-RelativeConfigData -configToken 'cardRuleSettingsFillBackgroundColorDefault')
                $dryRunAction['Foreground color'] = ($cardStyle.foregroundColor) ? $cardStyle.foregroundColor : (Get-RelativeConfigData -configToken 'cardRuleSettingsFillForegroundColorDefault')

                $dryRunAction['Italic'] = (([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isItalic' -and $cardStyle.isItalic -eq $true) ? $true : $false
                $dryRunAction['Bold'] = (([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isBold' -and $cardStyle.isBold -eq $true) ? $true : $false
                $dryRunAction['Underlined'] = (([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isUnderlined' -and $cardStyle.isUnderlined -eq $true) ? $true : $false

                $null = $cardDryRunActions.Add($dryRunAction)
            }

            # add update actions
            foreach ($cardStyle in $localCardConfig.cardStyles | Where-Object { $_.Name -in $remoteCardStyleSettings.rules.fill.name }) {

                $matchingRemote = $remoteCardStyleSettings.rules.fill | Where-Object { $_.Name -eq $cardStyle.Name }

                $dryRunAction = @{
                    Op              = '^'
                    Team            = $team
                    'Backlog Level' = $backlogLevel
                    Card            = $cardStyle.Name
                }

                if ((([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isEnabled') -and $cardStyle.isEnabled -ne $matchingRemote.isEnabled) {
                    $dryRunAction['Enabled'] = "[{0} => {1}]" -f $matchingRemote.isEnabled, $cardStyle.isEnabled
                }
                if ($cardStyle.backgroundColor -and $cardStyle.backgroundColor -ne $matchingRemote.settings.'background-color') {
                    $dryRunAction['Background color'] = "[{0} => {1}]" -f $matchingRemote.settings.'background-color', $cardStyle.backgroundColor
                }
                if ($cardStyle.foregroundColor -and $cardStyle.foregroundColor -ne $matchingRemote.settings.'title-color') {
                    $dryRunAction['Foreground color'] = "[{0} => {1}]" -f $matchingRemote.settings.'title-color', $cardStyle.foregroundColor
                }
                if ((([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isItalic') -and $cardStyle.isItalic -ne $matchingRemote.setting.'title-font-style') {
                    $dryRunAction['Italic'] = "[{0} => {1}]" -f $matchingRemote.setting.'title-font-style', $cardStyle.isItalic
                }
                if ((([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isBold') -and $cardStyle.isBold -ne $matchingRemote.setting.'title-font-weight') {
                    $dryRunAction['Bold'] = "[{0} => {1}]" -f $matchingRemote.setting.'title-font-weight', $cardStyle.isBold
                }
                if ((([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isUnderlined') -and $cardStyle.isUnderlined -ne $matchingRemote.setting.'title-text-decoration') {
                    $dryRunAction['Underlined'] = "[{0} => {1}]" -f $matchingRemote.setting.'title-text-decoration', $cardStyle.isUnderlined
                }

                $localAsRemoteFormatted = Format-ProjectTeamCardRuleCardStyleFilter -localFilter $cardStyle.filter
                if ($localAsRemoteFormatted -ne $matchingRemote.filter) {
                    $remoteAsLocalFormatted = Format-ProjectTeamCardRuleCardStyleFilter -remoteFilter $matchingRemote.filter
                    $dryRunAction['Filter'] = "[{0} => {1}]" -f $remoteAsLocalFormatted, $cardStyle.filter
                }

                $null = $cardDryRunActions.Add($dryRunAction)
            }

            # add remove actions
            foreach ($cardStyle in $remoteCardStyleSettings.rules.fill | Where-Object { $_ -and $_.Name -notin $localCardConfig.cardStyles.name }) {
                $null = $cardDryRunActions.Add(
                    @{
                        Op              = '-'
                        Team            = $team
                        'Backlog Level' = $backlogLevel
                        Card            = $cardStyle.Name
                    }
                )
            }

            if ($cardDryRunActions.count -gt 0) {

                $dryRunString = "`n`nWould update card styles to:"
                $dryRunString += "`n============================"

                $columns = @('#', 'Op', 'Team', 'Backlog Level', 'Card') + ($cardDryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Team', 'Backlog Level', 'Card') })
                $cardDryRunActionsCount = 1
                $dryRunString += ($cardDryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                        $_ | Select-Object @{Name = '#'; Expression = { $cardDryRunActionsCount } }, *
                        $cardDryRunActionsCount++
                    } | Format-Table $columns -AutoSize | Out-String)
                Write-Verbose $dryRunString -Verbose
            }
        }

        # Tags
        # ----
        if ($localCardConfig.PSObject.Properties.name -contains 'tagStyles') {
            $tagDryRunActions = [System.Collections.ArrayList]@()

            # add create actions
            foreach ($tagStyle in $localCardConfig.tagStyles | Where-Object { $_.Name -notin $remoteCardStyleSettings.rules.tagStyle.name }) {

                $dryRunAction = @{
                    Op              = '+'
                    Team            = $team
                    'Backlog Level' = $backlogLevel
                    Tag             = $tagStyle.Name
                    Color           = $tagStyle.color
                }

                $dryRunAction['Enabled'] = (([PSCustomObject]$tagStyle).Psobject.Properties.name -contains 'isEnabled') ? [System.Convert]::ToBoolean($tagStyle.isEnabled) : $true

                $null = $tagDryRunActions.Add($dryRunAction)
            }

            # add update actions
            foreach ($tagStyle in $localCardConfig.tagStyles | Where-Object { $_.Name -in $remoteCardStyleSettings.rules.tagStyle.name }) {
                $matchingRemote = $remoteCardStyleSettings.rules.tagStyle | Where-Object { $_.Name -eq $tagStyle.Name }

                $dryRunAction = @{
                    Op              = '^'
                    Team            = $team
                    'Backlog Level' = $backlogLevel
                    Tag             = $tagStyle.Name
                }

                if ((([PSCustomObject]$tagStyle).Psobject.Properties.name -contains 'isEnabled') -and $tagStyle.isEnabled -ne $matchingRemote.isEnabled) {
                    $dryRunAction['Enabled'] = "[{0} => {1}]" -f $matchingRemote.isEnabled, $tagStyle.isEnabled
                }
                if ($tagStyle.color -and $tagStyle.color -ne $matchingRemote.settings.'background-color') {
                    $dryRunAction['Color'] = "[{0} => {1}]" -f $matchingRemote.settings.'background-color', $tagStyle.color
                }

                # An update is only performed if properties are greater than the inital number
                if ($dryRunAction.Keys.count -gt 4) {
                    $null = $tagDryRunActions.Add($dryRunAction)
                }
            }

            # add remove actions
            foreach ($tagStyle in $remoteCardStyleSettings.rules.tagStyle | Where-Object { $_ -and $_.Name -notin $localCardConfig.tagStyles.name }) {
                $null = $tagDryRunActions.Add(
                    @{
                        Op              = '-'
                        Team            = $team
                        'Backlog Level' = $backlogLevel
                        Tag             = $tagStyle.Name
                    }
                )
            }

            if ($tagDryRunActions.count -gt 0) {

                $dryRunString = "`n`nWould update tag styles to:"
                $dryRunString += "`n==========================="

                $columns = @('#', 'Op', 'Team', 'Backlog Level', 'Tag') + ($tagDryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Team', 'Backlog Level', 'Tag') })
                $tagDryRunActionsCount = 1
                $dryRunString += ($tagDryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                        $_ | Select-Object @{Name = '#'; Expression = { $tagDryRunActionsCount } }, *
                        $tagDryRunActionsCount++
                    } | Format-Table $columns -AutoSize | Out-String)
                Write-Verbose $dryRunString -Verbose
            }
        }
    }
    else {
        $targetObject = @{
            rules = @{}
        }


        if ($localCardConfig.PSObject.Properties.name -contains 'cardStyles') {

            $targetObject.rules['fill'] = [System.Collections.ArrayList]@{}


            # Add locally configured
            foreach ($cardStyle in ($localCardConfig.cardStyles | Where-Object { $_.Name -notin $targetObject.rules.fill.name })) {

                $item = @{
                    name     = $cardStyle.name
                    settings = @{}
                }

                # in case there is an existing remote ...
                if ($matchingRemote = $remoteCardStyleSettings.rules.fill | Where-Object { $_.name -eq $cardStyle.name }) {
                    $item = (ConvertTo-Json $matchingRemote -Depth 5) | ConvertFrom-Json -Depth 5 -AsHashtable
                }

                $item['isEnabled'] = (([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isEnabled') ? [System.Convert]::ToBoolean($cardStyle.isEnabled) : $true
                $item['filter'] = Format-ProjectTeamCardRuleCardStyleFilter -localFilter $cardStyle.filter


                # These settings require special care as we have to actively add/remove properties based on their presense and value
                if ($cardStyle.backgroundColor) {
                    $item.settings['background-color'] = $cardStyle.backgroundColor
                }
                elseif ([String]::IsNullOrEmpty($item.settings.'background-color')) {
                    $item.settings['background-color'] = Get-RelativeConfigData -configToken 'cardRuleSettingsFillBackgroundColorDefault'
                }

                if ($cardStyle.foregroundColor) {
                    $item.settings['title-color'] = $cardStyle.foregroundColor
                }
                elseif ([String]::IsNullOrEmpty($item.settings.'title-color')) {
                    $item.settings['title-color'] = Get-RelativeConfigData -configToken 'cardRuleSettingsFillForegroundColorDefault'
                }

                if (([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isItalic') {
                    if ($cardStyle.isItalic) {
                        $item.settings['title-font-style'] = 'italic'
                    }
                    elseif (-not ([String]::IsNullOrEmpty($item.settings.'title-font-style'))) {
                        # In case the value is negative, we have to remove the property
                        if ($item -is [hashtable]) { $item.settings.remove('title-font-style') }
                        else { $item.settings.PSObject.Properties.Remove('title-font-style') }
                    }
                }

                if (([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isBold') {
                    if ($cardStyle.isBold) {
                        $item.settings['title-font-weight'] = 'bold'
                    }
                    elseif (-not ([String]::IsNullOrEmpty($item.settings.'title-font-weight'))) {
                        # In case the value is negative, we have to remove the property
                        if ($item -is [hashtable]) { $item.settings.remove('title-font-weight') }
                        else { $item.settings.PSObject.Properties.Remove('title-font-weight') }
                    }
                }

                if (([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isUnderlined') {
                    if ($cardStyle.isUnderlined) {
                        $item.settings['title-text-decoration'] = 'underline'
                    }
                    elseif (-not ([String]::IsNullOrEmpty($item.settings.'title-text-decoration'))) {
                        # In case the value is negative, we have to remove the property
                        if ($item -is [hashtable]) { $item.settings.remove('title-text-decoration') }
                        else { $item.settings.PSObject.Properties.Remove('title-text-decoration') }
                    }
                }

                $null = $targetObject.rules.fill.Add($item)
            }

            # If no items shall be removed, we need to also add the current items to the set
            if (-not $removeExcessItems) {
                foreach ($remoteCard in $remoteCardStyleSettings.rules.fill | Where-Object { $_.name -notin $targetObject.rules.fill.name }) {
                    # outgoing must be added at the end
                    $null = $targetObject.rules.fill.Add($remoteCard)
                }
            }
        }

        # style = fill property
        if ($localCardConfig.PSObject.Properties.name -contains 'tagStyles') {

            $targetObject.rules['tagStyle'] = [System.Collections.ArrayList]@{}

            # Add locally configured
            foreach ($tagConfig in ($localCardConfig.tagStyles | Where-Object { $_.Name -notin $targetObject.rules.tagStyle.name })) {

                $item = @{
                    name     = $tagConfig.name
                    settings = @{
                        'background-color' = $tagConfig.color
                        color              = Get-RelativeConfigData -configToken 'cardRuleSettingsTagStyleColorDefault'
                    }
                }
                $item['isEnabled'] = (([PSCustomObject]$tagConfig).Psobject.Properties.name -contains 'isEnabled') ? [System.Convert]::ToBoolean($tagConfig.isEnabled) : $true

                $null = $targetObject.rules.tagStyle.Add($item)
            }

            # If no items shall be removed, we need to also add the current items to the set
            if (-not $removeExcessItems) {
                foreach ($remoteTag in $remoteCardStyleSettings.rules.tagStyle | Where-Object { $_.name -notin $targetObject.rules.tagStyle.name }) {
                    # outgoing must be added at the end
                    $null = $targetObject.rules.tagStyle.Add($remoteTag)
                }
            }
        }

        #format body
        $body = $targetObject

        # build request
        $restInfo = Get-RelativeConfigData -configToken 'RESTeamCardRuleSettingsSet'
        $restInputObject = @{
            method = $restInfo.method
            uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($organization), [uri]::EscapeDataString($project), [uri]::EscapeDataString($team), [uri]::EscapeDataString($backlogLevel))
            body   = ConvertTo-Json $body -Depth 10 -Compress
        }

        if ($PSCmdlet.ShouldProcess(('REST command to update team [{0}|{1}] backlog level [{2}] card rules' -f $project, $team, $backlogLevel), "Invoke")) {
            $updateCommandResponse = Invoke-RESTCommand @restInputObject
            if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                Write-Error ('Failed to update backlog [{0}] card rule configuration for team [{1}|{2}] because of [{3} - {4}].' -f $backlogLevel, $project, $team, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                continue
            }
            elseif (-not $updateCommandResponse.rules) {
                Write-Error ('Failed to update backlog [{0}] card rule configuration for team [{1}|{2}] because of [{3}].' -f $backlogLevel, $project, $team, $updateCommandResponse)
                continue
            }
            else {
                Write-Verbose ("[^] Successfully updated backlog [{0}] card rule configuration for team [{1}|{2}]" -f $backlogLevel, $project, $team) -Verbose
            }
        }
    }
}