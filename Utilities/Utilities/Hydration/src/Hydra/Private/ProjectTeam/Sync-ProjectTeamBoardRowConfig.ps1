<#
.SYNOPSIS
Sync the local row configuration(s) for a given team

.DESCRIPTION
Sync the local row configuration(s) for a given team

.PARAMETER localRowConfig
Mandatory. The local row configuration to be synced

.PARAMETER team
Mandatory. The team to sync the settings for

.PARAMETER backlogLevel
Mandatory. The backlog level to apply the row settings for. E.g. Epics

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
Sync-ProjectTeamBoardrowConfig -organization 'contoso' -project 'Module Playground' -team 'Module Playground team' -backlogLevel 'Epics' -localRowConfig @('row1','row2') -remoteBoardSettings @{...}

Sync the rows 'row1' & 'row2' for the team 'Module Playground team' & level 'Epics'
#>
function Sync-ProjectTeamBoardRowConfig {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $localRowConfig,

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


    $targetRows = [System.Collections.ArrayList]@(
        # required default
        @{
            id   = '00000000-0000-0000-0000-000000000000'
            name = $null
        }
    )

    foreach ($row in $localRowConfig) {
        if ($targetRows.name -notcontains $row) {
            $item = @{
                name = $row
            }
            # in case there is an existing remote (with an id) ...
            if ($matchingRemote = $remoteBoardSettings.rows | Where-Object { $_.name -eq $row }) {
                $item['id'] = $matchingRemote.id
            }
            $null = $targetRows.Add($item)
        }
    }

    if (($remoteBoardSettings.rows.name | Where-Object { $_ }) -and # relevant remote items
        $localRowConfig -and # relevant local items
        (-not (Compare-Object -ReferenceObject ($remoteBoardSettings.rows.name | Where-Object { $_ }) -DifferenceObject $localRowConfig))) {

        # No changes, skip
        Write-Verbose "No rows to change"
        return
    }

    # If not items shall be removed, we need to also add the current items to the set
    if (-not $removeExcessItems) {
        foreach ($row in $remoteBoardSettings.rows) {
            if ($targetRows.name -notcontains $row.Name) {
                $null = $targetRows.Add($row)
            }
        }
    }

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@(
            @{
                Op              = '^'
                Team            = $team
                'Backlog Level' = $backlogLevel
                Rows            = "[({0}) => ({1})]" -f (($remoteBoardSettings.rows.count -gt 0) ? ($remoteBoardSettings.rows.name -join ',') : ''), (($targetRows.count -gt 0) ? ($targetRows.name -join ',') : '')
            }
        )

        $dryRunString = "`n`nWould update board rows to:"
        $dryRunString += "`n==========================="

        $columns = @('#', 'Op', 'Team', 'Backlog Level') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Team', 'Backlog Level') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
    else {
        #format body
        $body = $targetRows

        # build request
        $restInfo = Get-RelativeConfigData -configToken 'RESTeamBoardRowsSet'
        $restInputObject = @{
            method = $restInfo.method
            uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($organization), [uri]::EscapeDataString($project), [uri]::EscapeDataString($team), [uri]::EscapeDataString($backlogLevel))
            body   = ConvertTo-Json $body -Depth 10 -Compress
        }

        if ($PSCmdlet.ShouldProcess(('REST command to update team [{0}|{1}] backlog level [{2}] rows' -f $project, $team, $backlogLevel), "Invoke")) {
            $updateCommandResponse = Invoke-RESTCommand @restInputObject
            if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                Write-Error ('Failed to update backlog [{0}] rows configuration for team [{1}|{2}] because of [{3} - {4}].' -f $backlogLevel, $project, $team, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                continue
            }
            elseif (-not $updateCommandResponse.value) {
                Write-Error ('Failed to update backlog [{0}] rows configuration for team [{1}|{2}] because of [{3}].' -f $backlogLevel, $project, $team, $updateCommandResponse)
                continue
            }
            else {
                Write-Verbose ("[^] Successfully updated backlog [{0}] rows configuration for team [{1}|{2}]" -f $backlogLevel, $project, $team) -Verbose
            }
        }
    }
}