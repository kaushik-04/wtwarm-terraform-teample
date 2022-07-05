<#
.SYNOPSIS
Update the given processes based on provided latest version

.DESCRIPTION
Update the given processes based on provided latest version

.PARAMETER Organization
Mandatory. The organization to update the processes in

.PARAMETER processesToUpdate
Mandatory. The processes to update

.PARAMETER DryRun
Parameter description

.EXAMPLE
Optional. Simulate an end-to-end execution

.NOTES
Set-DevOpsProcessRange  -Organization 'contoso' -processesToUpdate @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879'; description 'New Description' }

Update the description of process 'myProcess' in organization 'contoso'
#>
function Set-DevOpsProcessRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $processesToUpdate,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($process in $processesToUpdate) {

        if ($DryRun) {
            $dryAction = @{
                Op = '^'
                Name = $process.name
            }

            if(-not ([String]::IsNullOrEmpty($process.Description))) {
                $dryAction['Description'] = "[{0} => {1}]" -f (($process.'Old Description') ? $process.'Old Description' : '()'), $process.Description
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $body = @{}
            if (-not [String]::IsNullOrEmpty($process.Description)) { $body['Description'] = $process.Description }

            $restInfo = Get-RelativeConfigData -configToken 'RESTProcessUpdate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $process.id)
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to update process [{0}]' -f $process.Name), "Invoke")) {
                $updateCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                    Write-Error ('Failed to update process [{0}] because of [{1} - {2}]. Make sure the process does exist.' -f $process.Name, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                    continue
                }
                else {
                    Write-Verbose ("[^] Successfully updated process [{0}]" -f $updateCommandResponse.name) -Verbose
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould update processes to:"
        $dryRunString += "`n=========================="

        $columns = @('#', 'Op', 'Name') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op','Name')})
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}