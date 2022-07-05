<#
.SYNOPSIS
Create the provided set of work item types in the given process

.DESCRIPTION
Create the provided set of work item types in the given process

.PARAMETER Organization
Mandatory. The organization to create the work item types in

.PARAMETER workitemtypesToCreate
Mandatory. The work item types to create in the target process

.PARAMETER process
Mandatory. The process the create the work item types in

.PARAMETER remoteBacklogLevels
Optional. The available backlog levels in the target process. Must be provided if any of the given work item types should be assigned with a backlog level / behavior

.PARAMETER DryRun
Optional. Simulate an end-to-end execution

.EXAMPLE
New-DevOpsProcessWorkItemTypeRange -organization 'contoso' -workItemTypesToCreate @( @{ name = "Work Item Type 1"; Color = "f6546a"; icon = "icon_airplane" } ) -process @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' }

Create the work item type 'Work Item Type 1' in process [contoso|myProcess]

.EXAMPLE
New-DevOpsProcessWorkItemTypeRange -organization 'contoso' -workItemTypesToCreate @( @{ name = "Work Item Type 1"; Color = "f6546a"; icon = "icon_airplane"; assignedBacklogLevel = 'myLevel' } ) -process @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' } -remoteBacklogLevels @( @{ name = "myLevel"; referenceName = "Custom.f9e9369e-2661-4eca-bc74-77c8a486f1ce"  })

Create the work item type 'Work Item Type 1' in process [contoso|myProcess] and assign behavior 'myLevel' to it
#>
function New-DevOpsProcessWorkItemTypeRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $workitemtypesToCreate,

        [Parameter(Mandatory = $false)]
        [PSCustomObject[]] $remoteBacklogLevels,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $process,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($workitemtypeToCreate in $workitemtypesToCreate) {

        if ($DryRun) {
            $dryAction = @{
                Op    = '+'
                Name  = $workitemtypeToCreate.Name
                Color = $workitemtypeToCreate.Color
                Icon  = $workitemtypeToCreate.icon
            }
            if (-not [String]::IsNullOrEmpty($workitemtypeToCreate.Description)) {
                $dryAction['Description'] = $workitemtypeToCreate.Description
            }
            if ($workitemtypeToCreate.behavior) {
                if ($workitemtypeToCreate.behavior.assignedBacklogLevel) {
                    $dryAction['Assigned behavior'] = $workitemtypeToCreate.behavior.assignedBacklogLevel

                    if (($workitemtypeToCreate.behavior | Get-Member -MemberType 'NoteProperty').Name -contains 'isDefault') {
                        $dryAction['Is default behavior'] = $workitemtypeToCreate.behavior.isDefault
                    }
                }
            }

            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $body = @{
                name  = $workitemtypeToCreate.Name
                Color = $workitemtypeToCreate.Color
                Icon  = $workitemtypeToCreate.icon
            }
            if (-not [String]::IsNullOrEmpty($workitemtypeToCreate.Description)) { $body['Description'] = $workitemtypeToCreate.Description }

            $restInfo = Get-RelativeConfigData -configToken 'RESTProcessWorkItemTypeCreate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $process.Id)
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to create work item type [{0}|{1}]' -f $process.Name, $workitemtypeToCreate.Name), "Invoke")) {
                $createCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($createCommandResponse.errorCode)) {
                    Write-Error ('Failed to create work item type [{0}|{1}] because of [{2} - {3}]' -f $process.Name, $workitemtypeToCreate.Name, $createCommandResponse.typeKey, $createCommandResponse.message)
                    continue
                }
            }

            # Set behavior
            # ------------
            if ($workitemtypeToCreate.behavior) {
                $behaviorRef = $remoteBacklogLevels | Where-Object { $_.Name -eq $workitemtypeToCreate.behavior.assignedBacklogLevel }
                if (-not $behaviorRef) {
                    Write-Warning ("Behavior reference [{0}] configured for workitem [{1}|{2}] does not exist" -f $workitemtypeToCreate.behavior.assignedBacklogLevel, $process.Name, $workitemtypeToCreate.Name)
                    continue
                }

                $body = @{
                    behavior = @{
                        id = $behaviorRef.referenceName
                    }
                }

                if (($workitemtypeToCreate.behavior | Get-Member -MemberType 'NoteProperty').Name -contains 'isDefault') {
                    $body['isDefault'] = $workitemtypeToCreate.behavior.isDefault
                }

                $restInfo = Get-RelativeConfigData -configToken 'RESTProcessWorkItemTypeBehaviorCreate'
                $restInputObject = @{
                    method = $restInfo.method
                    uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $process.Id, $createCommandResponse.referenceName)
                    body   = ConvertTo-Json $body -Depth 10 -Compress
                }

                if ($PSCmdlet.ShouldProcess(('REST command to create work item type behavior [{0}|{1}|{2}]' -f $process.Name, $workitemtypeToCreate.Name, $workitemtypeToCreate.behavior.assignedBacklogLevel), "Invoke")) {
                    $createCommandResponse = Invoke-RESTCommand @restInputObject
                    if (-not [String]::IsNullOrEmpty($createCommandResponse.errorCode)) {
                        Write-Error ('Failed to create work item type behavior [{0}|{1}|{2}] because of [{3} - {4}]' -f $process.Name, $workitemtypeToCreate.Name, $workitemtypeToCreate.behavior.assignedBacklogLevel, $createCommandResponse.typeKey, $createCommandResponse.message)
                        continue
                    }
                }
            }

            Write-Verbose ("[+] Successfully created work item type [{0}|{1}]" -f $process.Name, $workitemtypeToCreate.name) -Verbose
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould create work item types:"
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