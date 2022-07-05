<#
.SYNOPSIS
Format a filter string to match the counterpart (UI DevOps format vs. Internal DevOps format)

.DESCRIPTION
Format a filter string to match the counterpart (UI DevOps format vs. Internal DevOps format)
You can leverage properties such as 'Tags' (UI DevOps format) as well as 'System.Tags' (Internal DevOps format)

.PARAMETER localFilter
The UI filter to format. E.g. '[System.Tags] contains 'Blocked' and [Story Points] = '8'"'

.PARAMETER $remoteFilter
The internal filter to format. E.g. "[System.Tags] contains 'Blocked' and [Microsoft.VSTS.Scheduling.StoryPoints] = '8'"

.EXAMPLE
Format-ProjectTeamCardRuleCardStyleFilter -localFilter '[System.Tags] contains 'Blocked' and [Story Points] = '8'"'

Returns "[System.Tags] contains 'Blocked' and [Microsoft.VSTS.Scheduling.StoryPoints] = '8'"

.EXAMPLE
Format-ProjectTeamCardRuleCardStyleFilter -localFilter '[Tags] contains 'Blocked' and [Story Points] = '8'"'

Returns "[System.Tags] contains 'Blocked' and [Microsoft.VSTS.Scheduling.StoryPoints] = '8'"
#>
function Format-ProjectTeamCardRuleCardStyleFilter {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'local')]
        [string] $localFilter,

        [Parameter(Mandatory = $true, ParameterSetName = 'remote')]
        [string] $remoteFilter
    )

    $filterRegex = Get-RelativeConfigData -configToken 'RegexCardRuleSettingsFillFilter'

    if ($localFilter) {
        $regexMatches = Select-String $filterRegex -InputObject $localFilter -AllMatches | ForEach-Object { $_.matches }
        foreach ($regexMatch in $regexMatches) {
            $regexMatch = $regexMatch -replace '\[', '' -replace '\]', ''
            $counterpart = Get-BacklogPropertyCounterpart -localPropertyName $regexMatch
            $localFilter = $localFilter -replace $regexMatch, ("{0}" -f $counterpart)
        }
        return $localFilter
    }
    else {
        $regexMatches = Select-String $filterRegex -InputObject $remoteFilter -AllMatches | ForEach-Object { $_.matches }
        foreach ($regexMatch in $regexMatches) {
            $regexMatch = $regexMatch -replace '\[', '' -replace '\]', ''
            $counterpart = Get-BacklogPropertyCounterpart -remotePropertyName $regexMatch
            $remoteFilter = $remoteFilter -replace $regexMatch, ("{0}" -f $counterpart)
        }
        return $remoteFilter
    }
}