<#
.SYNOPSIS
Deletes an existng Team from a given Azure DevOps Project

.DESCRIPTION
Deletes an existng Team from a given Azure DevOps Project

.PARAMETER Organization
Organization Name

.PARAMETER Project
Project Name

.PARAMETER teamsToRemove
Mandatory. The teams to remove. The id can either be the name or id of the team.

.PARAMETER DryRun
Simulate an end2end execution

.EXAMPLE
Remove-ProjectTeamRange -Organization Contoso -Project ADO-project -teamsToRemove @(@{id = '99999999-9999-9999-9999-999999999999', name = 'TeamA'})

Remove team with Id '99999999-9999-9999-9999-999999999999' from DevOps project 'ADO-project'
#>
function Remove-ProjectTeamRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $teamsToRemove,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($team in $teamsToRemove) {

        if ($DryRun) {
            $dryAction = @{
                Op   = '-'
                ID   = $team.id
                Name = $team.name
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {

            $restInfo = Get-RelativeConfigData -configToken 'RESTTeamRemove'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), [uri]::EscapeDataString($team.id))
            }

            if ($PSCmdlet.ShouldProcess(('REST command to remove team [{0}|{1}]' -f $project, $team.Name), "Invoke")) {
                $removeCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($removeCommandResponse.errorCode)) {
                    Write-Error ('Failed to remove team [{0}|{1}] because of [{2} - {3}]. Make sure the team does exist.' -f $project, $team.Name, $removeCommandResponse.typeKey, $removeCommandResponse.message)
                    continue
                }
                else {
                    Write-Verbose ("[-] Successfully removed team [{0}|{1}]" -f $project, $team.name) -Verbose
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould remove teams:"
        $dryRunString += "`n==================="

        $columns = @('#', 'Op', 'Id') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op','Id')})
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}