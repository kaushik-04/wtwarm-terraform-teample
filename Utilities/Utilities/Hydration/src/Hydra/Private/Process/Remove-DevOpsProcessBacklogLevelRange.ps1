<#
.SYNOPSIS
Remove the given backlog levels from the target process

.DESCRIPTION
Remove the given backlog levels from the target process

.PARAMETER Organization
Mandatory. The organization to remove the items from

.PARAMETER process
Mandatory. The process to remove the backlog level from

.PARAMETER backlogLevelsToRemove
Mandatory. The backlog levels to remove

.PARAMETER DryRun
Optional. Simulate an end-to-end execution

.EXAMPLE
Remove-DevOpsProcessBacklogLevelRange -Organization 'contoso' -process @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' } -backlogLevelsToRemove  @( @{ name = "CustomLevel"; referenceName = "Custom.f9e9369e-2661-4eca-bc74-77c8a486f1ce" })

Remove the backlog level 'CustomLevel' from process [contoso|myProcess]
#>
function Remove-DevOpsProcessBacklogLevelRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $process,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $backlogLevelsToRemove,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($backlogLevelToRemove in $backlogLevelsToRemove) {

        if ($DryRun) {
            $dryAction = @{
                Op        = '-'
                Reference = $backlogLevelToRemove.Name
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {

            $restInfo = Get-RelativeConfigData -configToken 'RESTProcessBacklogLevelRemove'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $process.Id, $backlogLevelToRemove.referenceName)
            }

            if ($PSCmdlet.ShouldProcess(('REST command to remove backlog level [{0}|{1}]' -f $process.Name, $backlogLevelToRemove.Name), "Invoke")) {
                $removeCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($removeCommandResponse.errorCode)) {
                    Write-Error ('Failed to remove backlog level [{0}|{1}] because of [{2} - {3}]' -f $process.Name, $backlogLevelToRemove.Name, $removeCommandResponse.typeKey, $removeCommandResponse.message)
                    return
                }
            }
            Write-Verbose ("[-] Successfully removed backlog level [{0}|{1}]" -f $process.Name, $backlogLevelToRemove.Name) -Verbose
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould remove backlog levels:"
        $dryRunString += "`n============================"

        $columns = @('#', 'Op') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}