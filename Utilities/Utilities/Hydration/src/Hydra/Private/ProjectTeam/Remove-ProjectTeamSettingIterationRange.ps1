<#
.SYNOPSIS
Remove a given iteration from the set of availble iterations for a given team

.DESCRIPTION
Remove a given iteration from the set of availble iterations for a given team

.PARAMETER iterationsRemove
Mandatory. The iterations to remove from the available ones for the given team. E.g. @(@{ Name = 'iteration 1'; id = '181055a7-0e08-4c00-ba0c-238a8fe411ee' })

.PARAMETER remoteTeam
Mandatory. The team to set the settings for

.PARAMETER Organization
Mandatory. The organization hosting the project to process

.PARAMETER Project
Mandatory. The project hosting the team to process

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Remove-ProjectTeamSettingIterationRange -organization 'contoso' -project 'Module Playground' -remoteTeam @{ id = 1; name = 'teamToUpdate' } -iterationsRemove @(@{ Name = 'iteration 1'; id = '181055a7-0e08-4c00-ba0c-238a8fe411ee' })

Remove iteration 'iteration 1' to the available iterations for team [contoso|Module Playground|teamToUpdate]
#>
function Remove-ProjectTeamSettingIterationRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $iterationsRemove,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteTeam,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    $dryRunRemoveActions = [System.Collections.ArrayList]@()

    foreach ($iterationRemove in $iterationsRemove) {

        if ($dryRun) {
            $null = $dryRunRemoveActions += @{
                Op                    = '-'
                Team                  = $remoteTeam.Name
                'Available Iteration' = $iterationRemove.Name
            }
        }
        else {
            $restInfo = Get-RelativeConfigData -configToken 'RESTRestSettingsIterationsRemove'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), [uri]::EscapeDataString($remoteTeam.Name), $iterationRemove.id)
            }

            if ($PSCmdlet.ShouldProcess(('REST command to remove iteration to settings from team [{0}]' -f $remoteTeam.Name), "Invoke")) {
                $createCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($createCommandResponse.errorCode)) {
                    Write-Error ('Failed to removed iteration [{0}] from team [{1}] because of [{2} - {3}]' -f $iterationRemove.Name, $remoteTeam.Name, $createCommandResponse.typeKey, $createCommandResponse.message)
                    continue
                }
                else {
                    Write-Verbose ("[-] Successfully removed iteration [{0}] from settings of team [{1}]" -f $iterationRemove.Name, $remoteTeam.name) -Verbose
                }
            }
        }
    }

    if ($dryRunRemoveActions.count -gt 0) {
        $dryRunString = "`n`nWould remove iterations from team settings:"
        $dryRunString += "`n==========================================="

        $columns = @('#', 'Op') + ($dryRunRemoveActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op') })
        $dryRunRemoveActionsCount = 1
        $dryRunString += ($dryRunRemoveActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunRemoveActionsCount } }, *
                $dryRunRemoveActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}