<#
.SYNOPSIS
Test if the given local configuration matches the remote data

.DESCRIPTION
Test if the given local configuration matches the remote data

.PARAMETER localColumnConfig
Mandatory. The local data to test with

.PARAMETER remoteBoardSettings
Mandatory. The remote data to test against

.EXAMPLE
Test-ProjectTeamCardRuleConfigEqualsState -localCardConfig @{} -remoteCardStyleSettings @{}

Returns 'true' if the local & remote config are the same
#>
function Test-ProjectTeamCardRuleConfigEqualsState {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [PSCustomObject] $localCardConfig,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteCardStyleSettings
    )

    $formattedLocal = @{
        rules = @{}
    }
    if (([PSCustomObject]$localCardConfig).Psobject.Properties.name -contains 'cardStyles') { $formattedLocal.rules['fill'] = @() }
    if (([PSCustomObject]$localCardConfig).Psobject.Properties.name -contains 'tagStyles') { $formattedLocal.rules['tagStyle'] = @() }

    # Format local object for comparison
    # ----------------------------------
    foreach ($cardStyle in ($localCardConfig.cardStyles | Sort-Object -Property 'Name')) {

        $item = @{
            name     = $cardStyle.name
            filter   = $cardStyle.filter
            settings = @{}
        }
        $item['isEnabled'] = (([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isEnabled') ? [System.Convert]::ToBoolean($cardStyle.isEnabled) : $true

        $item.settings['background-color'] = ($cardStyle.backgroundColor) ? $cardStyle.backgroundColor : (Get-RelativeConfigData -configToken 'cardRuleSettingsFillBackgroundColorDefault')
        $item.settings['title-color'] = ($cardStyle.foregroundColor) ? $cardStyle.foregroundColor : (Get-RelativeConfigData -configToken 'cardRuleSettingsFillForegroundColorDefault')

        if (([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isItalic' -and $cardStyle.isItalic -eq $true) { $item.settings['title-font-style'] = 'italic' }
        if (([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isBold' -and $cardStyle.isBold -eq $true) { $item.settings['title-font-weight'] = 'bold' }
        if (([PSCustomObject]$cardStyle).Psobject.Properties.name -contains 'isUnderlined' -and $cardStyle.isUnderlined -eq $true) { $item.settings['title-text-decoration'] = 'underline' }

        $formattedLocal.rules.fill += [PSCustomObject]$item
    }
    foreach ($tagStyle in ($localCardConfig.tagStyles | Sort-Object -Property 'Name')) {
        $item = @{
            name     = $tagStyle.name
            settings = @{
                'background-color' = $tagStyle.color
                color              = Get-RelativeConfigData -configToken 'cardRuleSettingsTagStyleColorDefault'
            }
        }
        $item['isEnabled'] = (([PSCustomObject]$tagStyle).Psobject.Properties.name -contains 'isEnabled') ? [System.Convert]::ToBoolean($tagStyle.isEnabled) : $true
        $formattedLocal.rules.tagStyle += [PSCustomObject]$item
    }

    # Format remote object for comparison
    # -----------------------------------

    $formattedRemote = @{
        rules = @{}
    }
    if (([PSCustomObject]$remoteCardStyleSettings).rules.Psobject.Properties.name -contains 'fill') { $formattedRemote.rules['fill'] = @() }
    if (([PSCustomObject]$remoteCardStyleSettings).rules.Psobject.Properties.name -contains 'tagStyle') { $formattedRemote.rules['tagStyle'] = @() }

    foreach ($cardStyle in ($remoteCardStyleSettings.rules.fill | Sort-Object -Property 'Name')) {

        # We may only consider properties that exist both in the local & remote item
        $localCounterpart = $localCardConfig.cardStyles | Where-Object { $_.Name -eq $cardStyle.Name }

        $item = @{
            name      = $cardStyle.name
            filter    = $cardStyle.filter
            isEnabled = [System.Convert]::ToBoolean($cardStyle.isEnabled)
            settings  = @{
                'background-color' = $cardStyle.settings.'background-color'
                'title-color'      = $cardStyle.settings.'title-color'
            }
        }

        if (([PSCustomObject]$localCounterpart).Psobject.Properties.name -contains 'isItalic' -and
            ([PSCustomObject]$cardStyle).settings.Psobject.Properties.name -contains 'title-font-style') {
            $item.settings['title-font-style'] = 'italic'
        }

        if (([PSCustomObject]$localCounterpart).Psobject.Properties.name -contains 'isBold' -and
            ([PSCustomObject]$cardStyle).settings.Psobject.Properties.name -contains 'title-font-weight') {
            $item.settings['title-font-weight'] = 'bold'
        }
        if (([PSCustomObject]$localCounterpart).Psobject.Properties.name -contains 'isUnderlined' -and
            ([PSCustomObject]$cardStyle).settings.Psobject.Properties.name -contains 'title-text-decoration') {
            $item.settings['title-text-decoration'] = 'underline'
        }

        $formattedRemote.rules.fill += [PSCustomObject]$item
    }
    foreach ($tagStyle in ($remoteCardStyleSettings.rules.tagStyle | Sort-Object -Property 'Name')) {

        # We may only consider properties that exist both in the local & remote item
        $localCounterpart = $localCardConfig.tagStyles | Where-Object { $_.Name -eq $tagStyle.Name }

        $item = @{
            name      = $tagStyle.name
            isEnabled = [System.Convert]::ToBoolean($tagStyle.isEnabled)
            settings  = @{
                'background-color' = $tagStyle.settings.'background-color'
                color              = Get-RelativeConfigData -configToken 'cardRuleSettingsTagStyleColorDefault'
            }
        }
        $formattedRemote.rules.tagStyle += [PSCustomObject]$item
    }

    return ($remoteCardStyleSettings -and $localCardConfig -and ([String]::Compare(($formattedLocal | ConvertTo-Json -Depth 10), ($formattedRemote | ConvertTo-Json -Depth 10), $true) -eq 0))
}