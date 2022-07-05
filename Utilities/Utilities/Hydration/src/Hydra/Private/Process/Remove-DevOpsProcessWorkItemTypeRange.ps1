<#
.SYNOPSIS
Remove the given work item types from a given process

.DESCRIPTION
Remove the given work item types from a given process

.PARAMETER Organization
Mandatory. The organization host the process to remove the work item types from

.PARAMETER process
Mandatory. The process to remove the work item types from

.PARAMETER workItemTypesToRemove
Mandatory. The work item types to remove.

.PARAMETER DryRun
Optional. Simulate an end-to-end execution

.EXAMPLE
Remove-DevOpsProcessWorkItemTypeRange -Organization 'contoso'  -process @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' } -workItemTypesToRemove @(@{ referenceName = Process1.WorkItemType1"; name = "Work Item Type 1" })

Remove the work item type 'Work Item Type 1' from process [contoso|myProcess]
#>
function Remove-DevOpsProcessWorkItemTypeRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $process,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $workItemTypesToRemove,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($workItemTypeToRemove in $workItemTypesToRemove) {

        if ($DryRun) {
            $dryAction = @{
                Op        = '-'
                Process = $process.Name
                Name = $workItemTypeToRemove.Name
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {

            $restInfo = Get-RelativeConfigData -configToken 'RESTProcessWorkItemTypeRemove'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $process.id, $workItemTypeToRemove.referenceName)
            }

            if ($PSCmdlet.ShouldProcess(('REST command to remove work item type [{0}|{1}]' -f $process.Name, $workItemTypeToRemove.Name), "Invoke")) {
                $removeCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($removeCommandResponse.errorCode)) {
                    Write-Error ('Failed to remove work item type [{0}|{1}] because of [{2} - {3}]' -f $process.Name, $workItemTypeToRemove.Name, $removeCommandResponse.typeKey, $removeCommandResponse.message)
                    return
                }
            }
            Write-Verbose ("[-] Successfully removed work item type [{0}|{1}]" -f $process.Name, $workItemTypeToRemove.Name) -Verbose
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould remove work item types:"
        $dryRunString += "`n============================="

        $columns = @('#', 'Op') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}