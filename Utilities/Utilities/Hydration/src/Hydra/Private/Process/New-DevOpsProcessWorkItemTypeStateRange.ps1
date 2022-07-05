<#
.SYNOPSIS
Create the provided set of states for the given work item type

.DESCRIPTION
Create the provided set of states for the given work item type

.PARAMETER Organization
Mandatory. The organization to create the items in

.PARAMETER workItemTypeStatesToCreate
Mandatory. The work item type states to create for the given work item type

.PARAMETER processId
Mandatory. The id of the process that contains the work item type to create the states for

.PARAMETER workItemTypeReferenceName
Mandatory. The internal work item type reference to create the states for. E.g.
- CustomAgileProcess.CustomChangeRequest (<processname>.<typename> without whitespaces)
- CustomAgileProcess.de81222d-b7be-4a27-9498-53d1b55d08dd (<processname>.<guid> without whitespaces)

.PARAMETER DryRun
Optional. Simulate an end-to-end execution

.EXAMPLE
New-DevOpsProcessWorkItemTypeStateRange -organization 'contoso' -processId '9e2f26f6-192d-4942-b53f-05569010181d' -workItemTypeReferenceName 'Custom.de81222d-b7be-4a27-9498-53d1b55d08dd' -workItemTypeStatesToCreate @( @{ name = "State 1"; Color = b2b2b2"; StateCategory = "Proposed" }, @{ name = State 2"; Color = "0366fc"; StateCategory = "InProgress" } )

Create the states 'State 1' & 'State 2' for the work item type with reference 'Custom.de81222d-b7be-4a27-9498-53d1b55d08dd' in process [contoso|9e2f26f6-192d-4942-b53f-05569010181d]
#>
function New-DevOpsProcessWorkItemTypeStateRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $workItemTypeStatesToCreate,

        [Parameter(Mandatory = $true)]
        [string] $processId,

        [Parameter(Mandatory = $true)]
        # e.g. CustomAgileProcess.CustomChangeRequest (<processname>.<typename> without whitespaces)
        [string] $workItemTypeReferenceName,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($workItemTypeStateToCreate in $workItemTypeStatesToCreate) {

        if ($DryRun) {
            $dryAction = @{
                Op       = '+'
                Name     = $workItemTypeStateToCreate.Name
                Color    = $workItemTypeStateToCreate.Color
                Category = $workItemTypeStateToCreate.stateCategory
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $body = @{
                name          = $workItemTypeStateToCreate.Name
                Color         = $workItemTypeStateToCreate.Color
                stateCategory = $workItemTypeStateToCreate.stateCategory
            }

            $restInfo = Get-RelativeConfigData -configToken 'RESTProcessWorkItemTypeStateCreate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $processId, $workItemTypeReferenceName)
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to create work item type state [{0}] for parent [{1}]' -f $workItemTypeStateToCreate.Name, $workItemTypeReferenceName), "Invoke")) {
                $createCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($createCommandResponse.errorCode)) {
                    Write-Error ('Failed to create work item type state [{0}] for parent [{1}] because of [{2}]' -f $workItemTypeStateToCreate.Name, $workItemTypeReferenceName, $createCommandResponse.typeKey)
                    continue
                }
                else {
                    Write-Verbose ("[+] Successfully created work item type state [{0}] for parent [{1}]" -f $workItemTypeStateToCreate.name, $workItemTypeReferenceName) -Verbose
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould create work item type states:"
        $dryRunString += "`n==================================="

        $columns = @('#', 'Op') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }


}