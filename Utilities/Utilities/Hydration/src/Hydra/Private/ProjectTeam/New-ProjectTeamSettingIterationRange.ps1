<#
.SYNOPSIS
Add a given iteration to the set of availble iterations for a given team

.DESCRIPTION
Add a given iteration to the set of availble iterations for a given team

.PARAMETER iterationsToAdd
Mandatory. The iterations to add to the available ones for the given team. E.g. @(@{ Name = 'iteration 1'; identifier = '181055a7-0e08-4c00-ba0c-238a8fe411ee' })

.PARAMETER remoteTeam
Mandatory. The team to set the settings for

.PARAMETER Organization
Mandatory. The organization hosting the project to process

.PARAMETER Project
Mandatory. The project hosting the team to process

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
New-ProjectTeamSettingIterationRange -organization 'contoso' -project 'Module Playground' -remoteTeam @{ id = 1; name = 'teamToUpdate' } -iterationsToAdd @(@{ Name = 'iteration 1'; identifier = '181055a7-0e08-4c00-ba0c-238a8fe411ee' })

Add iteration 'iteration 1' to the available iterations for team [contoso|Module Playground|teamToUpdate]
#>
function New-ProjectTeamSettingIterationRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $iterationsToAdd,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteTeam,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    $dryRunAddActions = [System.Collections.ArrayList]@()

    foreach ($iterationToAdd in $iterationsToAdd) {
        if ($dryRun) {
            $null = $dryRunAddActions += @{
                Op                    = '+'
                Team                  = $remoteTeam.Name
                'Available Iteration' = $iterationToAdd.Name
            }
        }
        else {
            $body = @{ id = $iterationToAdd.identifier }

            $restInfo = Get-RelativeConfigData -configToken 'RESTRestSettingsIterationsAdd'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), [uri]::EscapeDataString($remoteTeam.Name))
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to add iteration to settings for team [{0}]' -f $remoteTeam.Name), "Invoke")) {
                $createCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($createCommandResponse.errorCode)) {
                    Write-Error ('Failed to add iteration [{0}] to team [{1}] because of [{2} - {3}]' -f $iterationToAdd.Name, $remoteTeam.Name, $createCommandResponse.typeKey, $createCommandResponse.message)
                    continue
                }
                else {
                    Write-Verbose ("[+] Successfully added iteration [{0}] to settings of team [{1}]" -f $iterationToAdd.Name, $remoteTeam.name) -Verbose
                }
            }
        }
    }

    if ($dryRunAddActions.count -gt 0) {
        $dryRunString = "`n`nWould add iterations to team settings:"
        $dryRunString += "`n======================================"

        $columns = @('#', 'Op') + ($dryRunAddActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op') })
        $dryRunAddActionsCount = 1
        $dryRunString += ($dryRunAddActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunAddActionsCount } }, *
                $dryRunAddActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}