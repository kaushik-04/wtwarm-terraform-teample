<#
.SYNOPSIS
Update the given backlog levels based on provided latest version

.DESCRIPTION
Update the given backlog levels based on provided latest version

.PARAMETER Organization
Mandatory. The organization to update the items in

.PARAMETER backlogLevelsToUpdate
Mandatory. The backlog levels to update

.PARAMETER process
Mandatory. The process hosting the backlog levels to update

.PARAMETER DryRun
Optional. Simulate an end-to-end execution

.EXAMPLE
Set-DevOpsProcessBacklogLevelRange -Organization 'contoso' -process @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' } -backlogLevelsToUpdate  @( @{ name = "CustomLevel"; referenceName = "Custom.f9e9369e-2661-4eca-bc74-77c8a486f1ce"; color = 'eeeeee' })

Update the color property of backlog level 'CustomLevel' for process [contoso|myProcess]
#>
function Set-DevOpsProcessBacklogLevelRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $backlogLevelsToUpdate,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $process,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($backlogLevel in $backlogLevelsToUpdate) {

        if ($DryRun) {
            $dryAction = @{
                Op   = '^'
                Name = $backlogLevel.name
            }

            if (-not ([String]::IsNullOrEmpty($backlogLevel.Color))) {
                $dryAction['Color'] = "[{0} => {1}]" -f (($backlogLevel.'Old Color') ? $backlogLevel.'Old Color' : '()'), $backlogLevel.Color
            }

            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $body = @{ name = $backlogLevel.Name}
            if (-not [String]::IsNullOrEmpty($backlogLevel.Color)) { $body['color'] = $backlogLevel.Color }

            $restInfo = Get-RelativeConfigData -configToken 'RESTProcessBacklogLevelUpdate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $process.Id, [uri]::EscapeDataString($backlogLevel.referenceName))
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to update backlog level [{0}]' -f $backlogLevel.Name), "Invoke")) {
                $updateCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                    Write-Error ('Failed to update backlog level [{0}] because of [{1} - {2}].' -f $backlogLevel.Name, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                    continue
                }
                elseif($updateCommandResponse.name -ne $backlogLevel.name) {
                    # the above information would be returned of successful
                    Write-Error ('Failed to update backlog level [{0}] because of [{1}] using uri [{2}] and body [{3}].' -f $backlogLevel.Name, $updateCommandResponse.value.Message, $restInputObject.uri, $restInputObject.body)
                    continue
                }
                else {
                    Write-Verbose ("[^] Successfully updated backlog level [{0}]" -f $updateCommandResponse.name) -Verbose
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould update backlog levels to:"
        $dryRunString += "`n==============================="

        $columns = @('#', 'Op', 'Name') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Name') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}