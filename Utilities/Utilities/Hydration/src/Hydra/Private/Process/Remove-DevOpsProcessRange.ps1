<#
.SYNOPSIS
Remove the given processes from the target organization

.DESCRIPTION
Remove the given processes from the target organization

.PARAMETER Organization
Mandatory. The organization to remove the processes from

.PARAMETER processesToRemove
Mandatory. The processes to remove from the target organization

.PARAMETER DryRun
Optional. Simulate an end-to-end execution

.EXAMPLE
Remove-DevOpsProcessRange -organization 'contoso' -processesToRemove @(@{ name = 'Process 1'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' };@{ name = 'Process 2'; id = '4b6f88ad-f1d2-468c-97ff-99daa4ed8a5a' } )

Remove the processes 'Process 1' & 'Process 2' from organization 'contoso'
#>
function Remove-DevOpsProcessRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $processesToRemove,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($processToRemove in $processesToRemove) {

        if ($DryRun) {
            $dryAction = @{
                Op = '-'
                ID = $processToRemove.Id
            }
            if (-not [String]::IsNullOrEmpty($processToRemove.name)) { $dryAction['Name'] = $processToRemove.name }
            $null = $dryRunActions.Add($dryAction)
        }
        else {

            $restInfo = Get-RelativeConfigData -configToken 'RESTProcessRemove'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($processToRemove.Id))
            }

            if ($PSCmdlet.ShouldProcess(('REST command to remove process [{0}]' -f $processToRemove.name), "Invoke")) {
                $removeCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($removeCommandResponse.errorCode)) {
                    Write-Error ('Failed to remove process [{0}] because of [{1} - {2}].' -f $processToRemove.name, $removeCommandResponse.typeKey, $removeCommandResponse.message)
                    return
                }
            }
            Write-Verbose ("[-] Successfully removed process [{0}]" -f $processToRemove.name) -Verbose
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould remove process:"
        $dryRunString += "`n====================="

        $columns = @('#', 'Op', 'Id') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Id') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}