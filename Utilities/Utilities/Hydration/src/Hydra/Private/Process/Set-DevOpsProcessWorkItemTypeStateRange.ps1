<#
.SYNOPSIS
Update the given work item type states based on the provided latest version

.DESCRIPTION
Update the given work item type states based on the provided latest version

.PARAMETER Organization
Mandatory. The organization to update the items in

.PARAMETER statesToUpdate
Mandatory. The work item type states to update

.PARAMETER process
Mandatory. The process hosting the work item type states to update

.PARAMETER workItemTypeReferenceName
Mandatory. The internal work item type reference to update the states of. E.g.
- CustomAgileProcess.CustomChangeRequest (<processname>.<typename> without whitespaces)
- CustomAgileProcess.de81222d-b7be-4a27-9498-53d1b55d08dd (<processname>.<guid> without whitespaces)

.PARAMETER DryRun
Optional. Simulate an end-to-end execution

.EXAMPLE
Set-DevOpsProcessWorkItemTypeStateRange -Organization 'contoso' -process @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' } -statesToUpdate @( @{ id = "e9f14d31-b0a9-44e8-a66a-865756e6f680"; name = "New"; color = 'eeeeee' } ) -workItemTypeReferenceName 'Custom.de81222d-b7be-4a27-9498-53d1b55d08dd'

Update the color of state 'New' of the work item type with the internal reference 'Custom.de81222d-b7be-4a27-9498-53d1b55d08dd' of process [contoso|myProcess]
#>
function Set-DevOpsProcessWorkItemTypeStateRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $statesToUpdate,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $process,

        [Parameter(Mandatory = $true)]
        # e.g. CustomAgileProcess.CustomChangeRequest (<processname>.<typename> without whitespaces)
        [string] $workItemTypeReferenceName,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($state in $statesToUpdate) {

        if ($DryRun) {
            $dryAction = @{
                Op   = '^'
                Name = $state.name
            }

            if (-not ([String]::IsNullOrEmpty($state.Color))) {
                $dryAction['Color'] = "[{0} => {1}]" -f (($state.'Old Color') ? $state.'Old Color' : '()'), $state.Color
            }
            if (-not ([String]::IsNullOrEmpty($state.StateCategory))) {
                $dryAction['StateCategory'] = "[{0} => {1}]" -f (($state.'Old StateCategory') ? $state.'Old StateCategory' : '()'), $state.StateCategory
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $body = @{ name = $state.Name }
            if (-not [String]::IsNullOrEmpty($state.Color)) { $body['Color'] = $state.Color }
            if (-not [String]::IsNullOrEmpty($state.StateCategory)) { $body['StateCategory'] = $state.StateCategory }

            $restInfo = Get-RelativeConfigData -configToken 'RESTProcessWorkItemTypeStateUpdate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $process.Id, $workItemTypeReferenceName, $state.id)
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to update work item type state [{0}]' -f $state.Name), "Invoke")) {
                $updateCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                    Write-Error ('Failed to update work item type state [{0}] because of [{1} - {2}].' -f $state.Name, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                    continue
                }
                else {
                    Write-Verbose ("[^] Successfully updated work item type state [{0}]" -f $updateCommandResponse.name) -Verbose
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould update work item type states to:"
        $dryRunString += "`n======================================"

        $columns = @('#', 'Op', 'Name') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Name') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}