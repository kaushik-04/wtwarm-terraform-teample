<#
.SYNOPSIS
Create the provided range of processes in the target organization

.DESCRIPTION
Create the provided range of processes in the target organization

.PARAMETER Organization
Mandatory. The organization to create the processes in

.PARAMETER processesToCreate
Mandatory. The processes to create

.PARAMETER DryRun
Optional. Simulate an end-to-end execution

.EXAMPLE
New-DevOpsProcessRange -organization 'contoso' -processesToCreate @(@{ name = 'Process 1'; parentProcess = 'Agile' },@{ name = 'Process 2'; parentProcess = 'Agile'; description = 'Custom Description' })

Create the processes 'Process 1' & 'Process 2' in organization 'contoso'
#>
function New-DevOpsProcessRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $processesToCreate,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($processToCreate in $processesToCreate) {

        # Resolve parent process ID (can be provided via name or GUID directly)
        if ($processToCreate.parentProcess -match (Get-RelativeConfigData -configToken 'RegexGUID')) {
            $parentProcessId = $processToCreate.parentProcess
        }
        else {
            $parentProcess = Get-DevOpsProcessList -Organization $Organization | Where-Object { $_.Name -eq $processToCreate.parentProcess }
            $parentProcessId = $parentProcess.Id
        }

        if ($DryRun) {
            $dryAction = @{
                Op               = '+'
                Name             = $processToCreate.Name
                'Parent Process' = $parentProcess ? $parentProcess.Name : $parentProcessId
            }
            if (-not [String]::IsNullOrEmpty($processToCreate.Description)) {
                $dryAction['Description'] = $processToCreate.Description
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $body = @{
                name                = $processToCreate.Name
                parentProcessTypeId = $parentProcessId
            }
            if (-not [String]::IsNullOrEmpty($processToCreate.Description)) { $body['Description'] = $processToCreate.Description }

            $restInfo = Get-RelativeConfigData -configToken 'RESTProcessCreate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization))
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to create DevOps process [{0}]' -f $processToCreate.Name), "Invoke")) {
                $createCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($createCommandResponse.errorCode)) {
                    Write-Error ('Failed to create DevOps process [{0}] because of [{1} - {2}]' -f $processToCreate.Name, $createCommandResponse.typeKey, $createCommandResponse.message)
                    continue
                }
                else {
                    Write-Verbose ("[+] Successfully created DevOps process [{0}]" -f $processToCreate.name) -Verbose
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould create DevOps processes:"
        $dryRunString += "`n==================="

        $columns = @('#', 'Op') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}