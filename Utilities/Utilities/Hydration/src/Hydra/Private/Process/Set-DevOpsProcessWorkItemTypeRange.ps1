<#
.SYNOPSIS
Update the given work item types based on provided latest version

.DESCRIPTION
Update the given work item types based on provided latest version

.PARAMETER Organization
Mandatory. The organization to update the items in

.PARAMETER workItemTypesToUpdate
Mandatory. The work item types to update

.PARAMETER process
Mandatory. The process hosting the work item types to update

.PARAMETER DryRun
Optional. Simulate an end-to-end execution

.EXAMPLE
Set-DevOpsProcessWorkItemTypeRange -Organization 'contoso' -process @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' } -workItemTypesToUpdate @(@{ referenceName = agile-product-management.Component"; name = "Component"; description = "New description" })

Update the description of work item type 'Component' in process [contoso|myProcess]
#>
function Set-DevOpsProcessWorkItemTypeRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $workItemTypesToUpdate,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $process,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($workItemType in $workItemTypesToUpdate) {

        if ($DryRun) {
            $dryAction = @{
                Op   = '^'
                Name = $workItemType.name
            }

            if (-not ([String]::IsNullOrEmpty($workItemType.Color))) {
                $dryAction['Color'] = "[{0} => {1}]" -f (($workItemType.'Old Color') ? $workItemType.'Old Color' : '()'), $workItemType.Color
            }
            if (-not ([String]::IsNullOrEmpty($workItemType.Icon))) {
                $dryAction['Icon'] = "[{0} => {1}]" -f (($workItemType.'Old Icon') ? $workItemType.'Old Icon' : '()'), $workItemType.Icon
            }
            if (-not ([String]::IsNullOrEmpty($workItemType.Description))) {
                $dryAction['Description'] = "[{0} => {1}]" -f (($workItemType.'Old Description') ? $workItemType.'Old Description' : '()'), $workItemType.Description
            }
            if (-not ([String]::IsNullOrEmpty($workItemType.AssignedBacklogLevel))) {
                $dryAction['Assigned backlog level'] = "[{0} => {1}]" -f (($workItemType.'Old AssignedBacklogLevel') ? $workItemType.'Old AssignedBacklogLevel' : '()'), $workItemType.AssignedBacklogLevel
            }
            if (-not ([String]::IsNullOrEmpty($workItemType.isDefault))) {
                $dryAction['Is default behavior'] = "[{0} => {1}]" -f $workItemType.'Old isDefault', $workItemType.isDefault
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {

            # Update properties
            if ((-not [String]::IsNullOrEmpty($workItemType.Color)) -or (-not [String]::IsNullOrEmpty($workItemType.Icon)) -or (-not [String]::IsNullOrEmpty($workItemType.Description))) {
                $body = @{}
                if (-not [String]::IsNullOrEmpty($workItemType.Color)) { $body['Color'] = $workItemType.Color }
                if (-not [String]::IsNullOrEmpty($workItemType.Icon)) { $body['Icon'] = $workItemType.Icon }
                if (-not [String]::IsNullOrEmpty($workItemType.Description)) { $body['Description'] = $workItemType.Description }
                $restInfo = Get-RelativeConfigData -configToken 'RESTWorkItemTypeUpdate'
                $restInputObject = @{
                    method = $restInfo.method
                    uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $process.Id, [uri]::EscapeDataString($workItemType.referenceName))
                    body   = ConvertTo-Json $body -Depth 10 -Compress
                }

                if ($PSCmdlet.ShouldProcess(('REST command to update work item type [{0}]' -f $workItemType.Name), "Invoke")) {
                    $updateCommandResponse = Invoke-RESTCommand @restInputObject
                    if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                        Write-Error ('Failed to update work item type [{0}] because of [{1} - {2}].' -f $workItemType.Name, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                        continue
                    }
                }
            }

            # Update Behavior
            if (-not ([String]::IsNullOrEmpty($workItemType.assignedBacklogLevel)) -or -not ([String]::IsNullOrEmpty($workItemType.isDefault))) {

                if($updateCommandResponse.referenceName) {
                    $workItemTypeReference = $updateCommandResponse.referenceName
                } else {
                    $remoteWorkItemType = Get-DevOpsProcessWorkItemTypeList -organization $Organization -processId $process.id | Where-Object { $_.Name -eq  $workItemType.Name}
                    $workItemTypeReference = $remoteWorkItemType.referenceName
                }

                $body = @{
                    behavior = @{
                        id = $workItemType.'AssignedBacklogLevel Ref'
                    }
                }

                if (-not [String]::IsNullOrEmpty($workItemType.isDefault)) {
                    $body['isDefault'] = $workItemType.isDefault
                }

                $restInfo = Get-RelativeConfigData -configToken 'RESTProcessWorkItemTypeBehaviorUpdate'
                $restInputObject = @{
                    method = $restInfo.method
                    uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $process.Id, $workItemTypeReference)
                    body   = ConvertTo-Json $body -Depth 10 -Compress
                }

                if ($PSCmdlet.ShouldProcess(('REST command to update work item type behavior [{0}|{1}|{2}]' -f $process.Name, $workItemType.Name, $workItemType.assignedBacklogLevel), "Invoke")) {
                    $updateCommandResponse = Invoke-RESTCommand @restInputObject
                    if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                        Write-Error ('Failed to update work item type behavior [{0}|{1}|{2}] because of [{3} - {4}]' -f $process.Name, $workItemType.Name, $workItemType.assignedBacklogLevel, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                        continue
                    }
                }
            }
            Write-Verbose ("[^] Successfully updated work item type [{0}]" -f $workItemType.name) -Verbose
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould update work item types to:"
        $dryRunString += "`n================================"

        $columns = @('#', 'Op', 'Name') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Name') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}