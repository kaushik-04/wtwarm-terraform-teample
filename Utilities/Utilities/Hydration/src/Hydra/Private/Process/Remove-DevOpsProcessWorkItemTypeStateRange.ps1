<#
.SYNOPSIS
Remove the given work item states from given work item type

.DESCRIPTION
Remove the given work item states from given work item type

.PARAMETER Organization
Mandatory. The organization host the process to remove the items from

.PARAMETER process
Mandatory. The process containing the work item type to remove the states from

.PARAMETER workItemTypeReferenceName
Mandatory. The internal work item type reference to remove the states from. E.g.
- CustomAgileProcess.CustomChangeRequest (<processname>.<typename> without whitespaces)
- CustomAgileProcess.de81222d-b7be-4a27-9498-53d1b55d08dd (<processname>.<guid> without whitespaces)

.PARAMETER workItemTypeStatesToRemove
Mandatory. The states to remove from the given work item type

.PARAMETER DryRun
Optional. Simulate an end-to-end execution

.EXAMPLE
Remove-DevOpsProcessWorkItemTypeStateRange -organization 'contoso' -process @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' } -workItemTypeReferenceName 'Custom.de81222d-b7be-4a27-9498-53d1b55d08dd' -workItemTypeStatesToRemove @( @{ id = "e9f14d31-b0a9-44e8-a66a-865756e6f680"; name = "New" })

Remove the state 'New' from the work item type with reference 'Custom.de81222d-b7be-4a27-9498-53d1b55d08dd' from process [contoso|myProcess]
#>
function Remove-DevOpsProcessWorkItemTypeStateRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $process,

        [Parameter(Mandatory = $true)]
        # e.g. CustomAgileProcess.CustomChangeRequest (<processname>.<typename> without whitespaces)
        [string] $workItemTypeReferenceName,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $workItemTypeStatesToRemove,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($workItemTypeStateToRemove in $workItemTypeStatesToRemove) {

        if ($DryRun) {
            $dryAction = @{
                Op      = '-'
                Process = $process.Name
                ID      = $workItemTypeStateToRemove.Name
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {

            $restInfo = Get-RelativeConfigData -configToken 'RESTProcessWorkItemTypeStateRemove'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $process.id, $workItemTypeReferenceName, $workItemTypeStateToRemove.Id)
            }

            if ($PSCmdlet.ShouldProcess(('REST command to remove state [{0}] from work item type [{1}|{2}]' -f $process.name,  $workItemTypeStateToRemove.Name, $workItemTypeReferenceName), "Invoke")) {
                $removeCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($removeCommandResponse.errorCode)) {
                    Write-Error ('Failed to remove state [{0}] from work item type [{1}|{2}] because of [{3} - {4}]' -f $workItemTypeStateToRemove.Name, $process.name, $workItemTypeReferenceName, $removeCommandResponse.typeKey, $removeCommandResponse.message, $removeCommandResponse.message)
                    return
                }
            }
            Write-Verbose ("[-] Successfully removed state [{0}] from work item type [{1}|{2}]" -f $workItemTypeStateToRemove.Name, $process.name, $workItemTypeReferenceName) -Verbose
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould remove work item type states:"
        $dryRunString += "`n==================================="

        $columns = @('#', 'Op', 'Id') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Id') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}