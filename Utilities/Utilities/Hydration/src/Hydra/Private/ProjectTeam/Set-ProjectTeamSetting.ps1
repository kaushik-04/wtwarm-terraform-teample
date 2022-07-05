<#
.SYNOPSIS
Update the settings for a given team

.DESCRIPTION
Update the settings for a given team - excluding the area path & iteration path settings

.PARAMETER remoteTeam
Mandatory. The remote team to set the settings for

.PARAMETER settingsToUpdate
Mandatory. The settings object describing the necessary changes

.PARAMETER Organization
Mandatory. The organization hosting the project with the remote team

.PARAMETER Project
Mandatory. The project hosting the remote team

.PARAMETER DryRun
Optional. Simulate an end2end execution

.EXAMPLE
Set-ProjectTeamSetting -remoteTeam @{ id = 1; name = 'remTeam' } -Organization Contoso -Project ADO-project -settingsToUpdate @{ workingDays = @{ workingdays = @("saturday", "sunday") }}

Update the team settings for team 'remTeam'. In this example the working days would be updated to 'saturday' & 'sunday'
#>
function Set-ProjectTeamSetting {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteTeam,

        [Parameter(Mandatory = $true)]
        [Hashtable] $settingsToUpdate,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
        $dryRunAction = @{
            Op      = '^'
            Project = $Project
            Name    = $remoteTeam.Name
        }

        if ($settingsToUpdate.ContainsKey('workingDays')) {
            $dryRunAction['Working days'] = "[({0}) => ({1})]" -f ($settingsToUpdate.workingDays.'original' -join ', '), ($settingsToUpdate.workingDays.workingDays -join ', ')
        }

        if ($settingsToUpdate.ContainsKey('backlogVisibilities')) {
            $visibilityActions = [System.Collections.ArrayList]@()
            foreach ($backlogVisibility in $settingsToUpdate.backlogVisibilities) {
                $itemKey = $backlogVisibility.Keys | Where-Object { $_ -notin @('original', 'ref') }
                $itemVisString = "[{0}: {1} => {2}]" -f $itemKey, $backlogVisibility.'original', $backlogVisibility.$itemKey
                $null = $visibilityActions.Add($itemVisString)
            }
            $dryRunAction['Visibility'] = $visibilityActions -join ', '
        }

        if ($settingsToUpdate.ContainsKey('bugsBehavior')) {
            $dryRunAction['Bug item handling'] = "[{0} => {1}]" -f $settingsToUpdate.bugsBehavior.'original', $settingsToUpdate.bugsBehavior.bugsBehavior
        }

        $null = $dryRunActions.Add($dryRunAction)
    }
    else {
        $body = @{}
        if ($settingsToUpdate.ContainsKey('workingDays')) {
            $body['workingDays'] = $settingsToUpdate.workingDays.workingDays
        }
        if ($settingsToUpdate.ContainsKey('backlogVisibilities')) {
            $visibilitiesToSet = @{}
            foreach ($visibility in $settingsToUpdate.backlogVisibilities) {
                $itemKey = $visibility.Keys | Where-Object { $_ -notin @('original', 'ref') }
                $visibilitiesToSet[$visibility.ref] = $visibility.$itemKey
            }
            $body['backlogVisibilities'] = $visibilitiesToSet
        }
        if ($settingsToUpdate.ContainsKey('bugsBehavior')) {
            $body['bugsBehavior'] = $settingsToUpdate.bugsBehavior.bugsBehavior
        }

        $restInfo = Get-RelativeConfigData -configToken 'RESTTeamSettingsSet'
        $restInputObject = @{
            method = $restInfo.method
            uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), $remoteTeam.id)
            body   = ConvertTo-Json $body -Depth 10 -Compress
        }

        if ($PSCmdlet.ShouldProcess(('REST command to update settings of team [{0}]' -f $team.Name), "Invoke")) {
            $updateCommandResponse = Invoke-RESTCommand @restInputObject
            if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                Write-Error ('Failed to update settings for team [{0}] because of [{1} - {2}]. Make sure the team does exist.' -f $team.Name, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                continue
            } elseif($updateCommandResponse -is [string]) {
                Write-Error ('Failed to update settings for team [{0}] because of [{1}]. Make sure the team does exist.' -f $team.Name, $updateCommandResponse)
                continue
            }
            else {
                Write-Verbose ("[^] Successfully updated settings for team [{0}]" -f $remoteTeam.name) -Verbose
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould set team settings:"
        $dryRunString += "`n========================"

        $columns = @('#', 'Op', 'Project', 'Name') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Project', 'Name') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}