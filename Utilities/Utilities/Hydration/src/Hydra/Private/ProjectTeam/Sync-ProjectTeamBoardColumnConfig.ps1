<#
.SYNOPSIS
Sync the local column configuration(s) for a given team

.DESCRIPTION
Sync the local column configuration(s) for a given team

.PARAMETER localColumnConfig
Mandatory. The local column configuration to be synced

.PARAMETER team
Mandatory. The team to sync the settings for

.PARAMETER backlogLevel
Mandatory. The backlog level to apply the column settings for. E.g. Epics

.PARAMETER remoteBoardSettings
Mandatory. The current board settings deployed for the given team

.PARAMETER Organization
Mandatory. The organization hosting the project to configure. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project hosting the team to configure. E.g. 'Module Playground'

.PARAMETER removeExcessItems
Optional. Control whether or not to remove items from those available that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-ProjectTeamBoardColumnConfig -organization 'contoso' -project 'Module Playground' -team 'Module Playground team' -backlogLevel 'Epics' -localColumnConfig @(@{...}) -remoteBoardSettings @{...}

Sync the columns for the team 'Module Playground team' & level 'Epics'
#>
function Sync-ProjectTeamBoardColumnConfig {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $localColumnConfig,

        [Parameter(Mandatory = $true)]
        [string] $team,

        [Parameter(Mandatory = $true)]
        [string] $backlogLevel,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteBoardSettings,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if (Test-ProjectTeamBoardColumnConfigEqualsState -localColumnConfig $localColumnConfig -remoteBoardSettings $remoteBoardSettings) {
        # No changes, skip
        Write-Verbose "No columns to change"
        return
    }

    $targetColumns = [System.Collections.ArrayList]@()

    if ($providedLocal = ($localColumnConfig | Where-Object { $_.columnType -eq 'incoming' })) {

        $item = $remoteBoardSettings.columns | Where-Object { $_.columnType -eq 'incoming' } | ConvertTo-Json -Depth 5 | ConvertFrom-Json -Depth 5 -AsHashtable
        $item.name = $providedLocal.name
        $item.stateMappings = $providedLocal.stateMappings

        if ($providedLocal.itemsInProgressLimit) { $item['itemLimit'] = $providedLocal.itemsInProgressLimit }
        if (([PSCustomObject]$providedLocal).Psobject.Properties.name -contains 'isSplit') { $item['isSplit'] = $providedLocal.isSplit }
        if ($providedLocal.definitionOfDone) { $item['description'] = $providedLocal.definitionOfDone }

        $item['columnType'] = $providedLocal.columnType

        $null = $targetColumns.Add($item)
    }
    else {
        # Add incoming as it cannot be modified and must always be provided
        $null = $targetColumns.Add(($remoteBoardSettings.columns | Where-Object { $_.columnType -eq 'incoming' }))
    }

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()

        # add create actions
        foreach ($column in ($localColumnConfig | Where-Object { $_.Name -notin $targetColumns.Name -and $_.Name -notin $remoteBoardSettings.columns.name })) {
            $dryRunAction = @{
                Op               = '+'
                Team             = $team
                'Backlog Level'  = $backlogLevel
                Column           = $column.Name
                'State Mappings' = $column.stateMappings | ConvertTo-Json -Compress
            }
            if ($column.itemsInProgressLimit) { $dryRunAction['In Progress limit'] = $column.itemsInProgressLimit }
            if (([PSCustomObject]$column).Psobject.Properties.name -contains 'isSplit') { $dryRunAction['Is split'] = $column.isSplit }
            if ($column.definitionOfDone) { $dryRunAction['Definition Of done'] = $column.definitionOfDone }
            $null = $dryRunActions.Add($dryRunAction)
        }

        # add update actions
        foreach ($column in ($localColumnConfig | Where-Object { $_.Name -in $remoteBoardSettings.columns.name })) {
            $matchingRemote = $remoteBoardSettings.columns | Where-Object { $_.Name -eq $column.Name }

            $dryRunAction = @{
                Op              = '^'
                Team            = $team
                'Backlog Level' = $backlogLevel
                Column          = $column.Name
            }
            if ($column.itemsInProgressLimit -and $column.itemsInProgressLimit -ne $matchingRemote.itemLimit) {
                $dryRunAction['In Progress limit'] = "[{0} => {1}]" -f $matchingRemote.itemLimit, $column.itemsInProgressLimit
            }
            if ((([PSCustomObject]$column).Psobject.Properties.name -contains 'isSplit') -and $column.isSplit -ne $matchingRemote.isSplit) {
                $dryRunAction['Is split'] = "[{0} => {1}]" -f $matchingRemote.isSplit, $column.isSplit
            }
            # if ((Compare-Object ($matchingRemote.stateMappings).PSObject.Properties ([PSCustomObject]$column.stateMappings).PSObject.Properties)) {
            if ([String]::Compare(($column.stateMappings | ConvertTo-Json), ($matchingRemote.stateMappings | ConvertTo-Json), $true) -ne 0) {
                $dryRunAction['State Mappings'] = "[{0} => {1}]" -f (ConvertTo-Json $matchingRemote.stateMappings -Compress), (ConvertTo-Json $column.stateMappings -Compress)
            }
            if ($column.definitionOfDone -and $column.definitionOfDone -ne $matchingRemote.description) {
                $dryRunAction['Definition Of done'] = "[{0} => {1}]" -f ([String]::IsNullOrEmpty($matchingRemote.description) ? '()' : $matchingRemote.description), $column.definitionOfDone
            }

            # An update is only performed if properties are greater than the inital number
            if ($dryRunAction.Keys.count -gt 4) {
                $null = $dryRunActions.Add($dryRunAction)
            }
        }

        if ($removeExcessItems) {
            # add removal actions
            foreach ($column in ($remoteBoardSettings.columns | Where-Object { $_.name -notin $targetColumns.Name -and $_.name -notin $localColumnConfig.Name })) {
                $null = $dryRunActions.Add(
                    @{
                        Op              = '-'
                        Team            = $team
                        'Backlog Level' = $backlogLevel
                        Column          = $column.Name
                    }
                )
            }
        }
    }
    else {

        # Add locally configured
        foreach ($column in ($localColumnConfig | Where-Object { $_.Name -notin $targetColumns.name -and $_.columnType -notin @('incoming', 'outgoing') })) {
            $item = @{
                name          = $column.name
                stateMappings = $column.stateMappings
            }

            # in case there is an existing remote ...
            if ($matchingRemote = $remoteBoardSettings.columns | Where-Object { $_.name -eq $column.name }) {
                $item = (ConvertTo-Json $matchingRemote -Depth 5) | ConvertFrom-Json -Depth 5 -AsHashtable
            }

            if ($column.itemsInProgressLimit) { $item['itemLimit'] = $column.itemsInProgressLimit }
            if (([PSCustomObject]$column).Psobject.Properties.name -contains 'isSplit') { $item['isSplit'] = $column.isSplit }
            if ($column.definitionOfDone) { $item['description'] = $column.definitionOfDone }

            $null = $targetColumns.Add($item)
        }

        # If no items shall be removed, we need to also add the current items to the set
        if (-not $removeExcessItems) {
            foreach ($column in $remoteBoardSettings.columns | Where-Object { $_.columnType -ne 'outgoing' -and $_.name -notin $targetColumns.name }) {
                # outgoing must be added at the end
                $null = $targetColumns.Add($column)
            }
        }


        if ($providedLocal = ($localColumnConfig | Where-Object { $_.columnType -eq 'outgoing' })) {

            $item = $remoteBoardSettings.columns | Where-Object { $_.columnType -eq 'outgoing' } | ConvertTo-Json -Depth 5 | ConvertFrom-Json -Depth 5 -AsHashtable
            $item.name = $providedLocal.name
            $item.stateMappings = $providedLocal.stateMappings

            if ($providedLocal.itemsInProgressLimit) { $item['itemLimit'] = $providedLocal.itemsInProgressLimit }
            if (([PSCustomObject]$providedLocal).Psobject.Properties.name -contains 'isSplit') { $item['isSplit'] = $providedLocal.isSplit }
            if ($providedLocal.definitionOfDone) { $item['description'] = $providedLocal.definitionOfDone }

            $item['columnType'] = $providedLocal.columnType

            $null = $targetColumns.Add($item)
        }
        else {
            # Add outgoing as it cannot be modified and must always be provided
            $null = $targetColumns.Add(($remoteBoardSettings.columns | Where-Object { $_.columnType -eq 'outgoing' }))
        }

        #format body
        $body = $targetColumns

        # build request
        $restInfo = Get-RelativeConfigData -configToken 'RESTeamBoardColumnsSet'
        $restInputObject = @{
            method = $restInfo.method
            uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($organization), [uri]::EscapeDataString($project), [uri]::EscapeDataString($team), [uri]::EscapeDataString($backlogLevel))
            body   = ConvertTo-Json $body -Depth 10 -Compress
        }

        if ($PSCmdlet.ShouldProcess(('REST command to update team [{0}|{1}] backlog level [{2}] columns' -f $project, $team, $backlogLevel), "Invoke")) {
            $updateCommandResponse = Invoke-RESTCommand @restInputObject
            if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                Write-Error ('Failed to update backlog [{0}] columns configuration for team [{1}|{2}] because of [{3} - {4}].' -f $backlogLevel, $project, $team, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                continue
            }
            elseif (-not $updateCommandResponse.value) {
                Write-Error ('Failed to update backlog [{0}] columns configuration for team [{1}|{2}] because of [{3}].' -f $backlogLevel, $project, $team, $updateCommandResponse)
                continue
            }
            else {
                Write-Verbose ("[^] Successfully updated backlog [{0}] columns configuration for team [{1}|{2}]" -f $backlogLevel, $project, $team) -Verbose
            }
        }
    }

    if ($dryRunActions.count -gt 0) {

        $dryRunString = "`n`nWould update board columns to:"
        $dryRunString += "`n=============================="

        $columns = @('#', 'Op', 'Team', 'Backlog Level', 'Column') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Team', 'Backlog Level', 'Column') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}