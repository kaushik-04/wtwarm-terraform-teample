<#
.SYNOPSIS
Remove a given project from an DevOps organization

.DESCRIPTION
Remove a given project from an DevOps organization

.PARAMETER Organization
Mandatory. The organization to remove the project from.

.PARAMETER Project
Mandatory. The project to remove.

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Remove-Project -organization 'contoso' -project @{ name = 'Module Playground'; id = 1 }

Remove project 'Module Playground' from DevOps organization 'contoso'
#>
function Remove-Project {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $project,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    if ($DryRun) {
        $dryAction = @{
            Op = '-'
            ID = $project.Name
        }
        $null = $dryRunActions.Add($dryAction)
    }
    else {

        $restInfo = Get-RelativeConfigData -configToken 'RESTProjectRemove'
        $restInputObject = @{
            method = $restInfo.method
            uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $project.id)
        }

        if ($PSCmdlet.ShouldProcess(('REST command to remove project [{0}]' -f $project.Name), "Invoke")) {
            $removeCommandResponse = Invoke-RESTCommand @restInputObject
            if (-not [String]::IsNullOrEmpty($removeCommandResponse.errorCode)) {
                Write-Error ('Failed to remove project [{0}] because of [{1} - {2}]. Make sure the project does exist.' -f $project.Name, $removeCommandResponse.typeKey, $removeCommandResponse.message)
                return
            }
        }
        Write-Verbose ("[-] Successfully removed project [{0}]" -f $project.Name) -Verbose
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould remove project:"
        $dryRunString += "`n======================"

        $columns = @('#', 'Op', 'Id') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op','Id')})
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}