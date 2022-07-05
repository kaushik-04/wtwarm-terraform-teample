<#
.SYNOPSIS
Creates a new Team for a given Azure DevOps Project

.DESCRIPTION
Creates a new Team for a given Azure DevOps Project

.PARAMETER Organization
Mandatory. Organization Name. E.g. 'contoso'

.PARAMETER Project
Mandatory. Project Name. E.g. 'Module Playground'

.PARAMETER teamsToCreate
Mandatory. The teams to create. Each object must at least contain a name.

.PARAMETER DryRun
Simulate an end2end execution

.EXAMPLE
New-ProjectTeamRange -Organization Contoso -Project ADO-project -teamsToCreate @(@{ Name = 'Database Team'; Descripton = 'Database Team Description' })

Create a new team for project 'ADO-project' using name 'Database Team' using description 'Database Team Description'
#>
function New-ProjectTeamRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $teamsToCreate,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($team in $teamsToCreate) {

        if ($DryRun) {
            $dryAction = @{
                Op   = '+'
                Name = $team.Name
            }
            if (-not [String]::IsNullOrEmpty($team.Description)) {
                $dryAction['Description'] = $team.Description
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $body = @{ name = $team.Name }
            if (-not [String]::IsNullOrEmpty($team.Description)) { $body['Description'] = $team.Description }

            $restInfo = Get-RelativeConfigData -configToken 'RESTTeamCreate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project))
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to create team [{0}]' -f $team.Name), "Invoke")) {
                $createCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($createCommandResponse.errorCode)) {
                    Write-Error ('Failed to create team [{0}] because of [{1} - {2}]' -f $team.Name, $createCommandResponse.typeKey, $createCommandResponse.message)
                    continue
                }
                else {
                    Write-Verbose ("[+] Successfully created team [{0}]" -f $team.name) -Verbose
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould create teams:"
        $dryRunString += "`n==================="

        $columns = @('#', 'Op') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}