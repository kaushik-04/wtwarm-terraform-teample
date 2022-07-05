<#
.SYNOPSIS
Create the provided range of of backog levels

.DESCRIPTION
Create the provided range of of backog levels

.PARAMETER Organization
Mandatory. The organization to create the items in

.PARAMETER backlogLevelsToCreate
Mandatory. The backlog levels to create in the given process

.PARAMETER process
Mandatory. The process to create the backlog level in

.PARAMETER DryRun
Optional. Simulate an end-to-end execution

.EXAMPLE
New-DevOpsProcessBacklogLevelRange -organization 'contoso' -process @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' } -backlogLevelsToCreate @(@{ name = "Level1"; color = "f6546a" }, @{ name = "Level2"; color = "0366fc" })

Create the two backlog levels 'Level1' & 'Level2' in process [contoso|myProcess]
#>
function New-DevOpsProcessBacklogLevelRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $backlogLevelsToCreate,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $process,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($backlogLevelToCreate in $backlogLevelsToCreate) {

        if ($DryRun) {
            $dryAction = @{
                Op    = '+'
                Name  = $backlogLevelToCreate.Name
                Color = $backlogLevelToCreate.Color
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $body = @{
                name  = $backlogLevelToCreate.Name
                Color = $backlogLevelToCreate.Color
                inherits  = "System.PortfolioBacklogBehavior" # Only category that supports resizing
            }
            $restInfo = Get-RelativeConfigData -configToken 'RESTProcessBacklogLevelCreate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $process.Id)
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to create backlog level [{0}|{1}]' -f $process.Name, $backlogLevelToCreate.Name), "Invoke")) {
                $createCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($createCommandResponse.errorCode)) {
                    Write-Error ('Failed to create backlog level [{0}|{1}] because of [{2} - {3}]' -f $process.Name, $backlogLevelToCreate.Name, $createCommandResponse.typeKey, $createCommandResponse.message)
                    continue
                }
                else {
                    Write-Verbose ("[+] Successfully created backlog level [{0}|{1}]" -f $process.Name, $backlogLevelToCreate.name) -Verbose
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould create backlog levels:"
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