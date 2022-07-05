<#
.SYNOPSIS
Creates a new Team for a given Azure DevOps Project

.DESCRIPTION
Creates a new Team for a given Azure DevOps Project

.PARAMETER Organization
Azure DevOps Organization Name

.PARAMETER Project
Azure DevOps Project Name

.PARAMETER teamToSet
Mandatory. The team to set as the default project team

.EXAMPLE
Set-ProjectTeamProjectDefault -Organization Contoso -Project ADO-project -teamToSet @{ id = 'team1'; name = 'newName'; description = 'desc' }

Set 'team1' as the default team for project [contoso|ADO-project]
#>
function Set-ProjectTeamProjectDefault {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $teamToSet,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = @(
            @{
                Op                   = '^'
                Project              = $Project
                Name                 = $teamToSet.Name
                'Is project default' = $true
            }
        )
    }
    else {
        $body = @{
            contributionIds     = @(
                "ms.vss-admin-web.admin-teams-data-provider"
            )
            dataProviderContext = @{
                properties = @{
                    setDefaultTeam = $true
                    teamId         = $teamToSet.id
                    sourcePage     = @{
                        routeValues = @{
                            project = $Project
                        }
                    }
                }
            }
        }

        $restInfo = Get-RelativeConfigData -configToken 'RESTTeamProjectDefaultUpdate'
        $restInputObject = @{
            method = $restInfo.method
            uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization))
            body   = ConvertTo-Json $body -Depth 10 -Compress
        }

        if ($PSCmdlet.ShouldProcess(('REST command to set team [{0}|{1}]' -f $teamToSet.Name, $Project), "Invoke")) {
            $updateCommandResponse = Invoke-RESTCommand @restInputObject
            if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                Write-Error ('Failed to set default team [{0}|{1}] because of [{2} - {3}]. Make sure the team does exist.' -f $teamToSet.Name, $Project, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                continue
            }
            else {
                Write-Verbose ("[^] Successfully set team default [{0}|{1}]" -f $teamToSet.name, $Project) -Verbose
            }
        }

    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould set team as default:"
        $dryRunString += "`n=========================="

        $columns = @('#', 'Op', 'Project', 'Name') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Project', 'Name') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}