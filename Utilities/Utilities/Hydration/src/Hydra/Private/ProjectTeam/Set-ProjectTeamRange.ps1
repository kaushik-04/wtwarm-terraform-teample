<#
.SYNOPSIS
Creates a new Team for a given Azure DevOps Project

.DESCRIPTION
Creates a new Team for a given Azure DevOps Project

.PARAMETER Organization
Azure DevOps Organization Name

.PARAMETER Project
Azure DevOps Project Name

.PARAMETER teamsToUpdate
Mandatory. The teams to update. The id can either be the name or id of the team.

.EXAMPLE
Set-ProjectTeamRange -Organization Contoso -Project ADO-project -teamsToUpdate @( @{ id = 'team1'; name = 'newName'; description = 'desc' })

Update the name of the given team with id 'team1' to 'newName' and the description to 'desc'
#>
function Set-ProjectTeamRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $teamsToUpdate,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($team in $teamsToUpdate) {

        if ($DryRun) {
            $dryAction = @{
                Op = '^'
                ID = $team.id
            }

            if(-not ([String]::IsNullOrEmpty($team.Name))) {
                $dryAction['Name'] = "[{0} => {1}]" -f (($team.'Old Name') ? $team.'Old Name' : '()'), $team.Name
            }
            if(-not ([String]::IsNullOrEmpty($team.Description))) {
                $dryAction['Description'] = "[{0} => {1}]" -f (($team.'Old Description') ? $team.'Old Description' : '()'), $team.Description
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $body = @{}
            if (-not [String]::IsNullOrEmpty($team.Name)) { $body['Name'] = $team.Name }
            if (-not [String]::IsNullOrEmpty($team.Description)) { $body['Description'] = $team.Description }

            $restInfo = Get-RelativeConfigData -configToken 'RESTTeamUpdate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), [uri]::EscapeDataString($team.id))
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to update team [{0}]' -f $team.Name), "Invoke")) {
                $updateCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                    Write-Error ('Failed to update team [{0}] because of [{1} - {2}]. Make sure the team does exist.' -f $team.Name, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                    continue
                }
                else {
                    Write-Verbose ("[^] Successfully updated team [{0}]" -f $updateCommandResponse.name) -Verbose
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould update teams to:"
        $dryRunString += "`n======================"

        $columns = @('#', 'Op', 'Id') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op','Id')})
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}