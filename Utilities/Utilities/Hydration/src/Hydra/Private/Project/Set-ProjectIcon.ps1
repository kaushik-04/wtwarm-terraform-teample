<#
.SYNOPSIS
Set the icon for a given project

.DESCRIPTION
Set the icon for a given project

.PARAMETER iconPath
Mandatory. The local path to the icon file

.PARAMETER Organization
Madnatory. The organization hosting the project to set the icon for

.PARAMETER project
Mandatory. The project to set the icon for

.PARAMETER DryRun
Optional. Simulate end to end execution

.EXAMPLE
Set-ProjectIcon -iconPath 'C:\Rick.png' -organization 'contoso' -project 'Module Playground'

Set the icon in path 'C:\Rick.png' for project [contoso|Module Playround]
#>
function Set-ProjectIcon {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $iconPath,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $project,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if (-not (Test-Path $iconPath)) {
        Write-Error "Icon path [$iconPath] does not exist"
        return
    }

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
        $dryAction = @{
            Op   = '^'
            id   = $project.id
            name = $project.Name
            icon = Split-Path $iconPath -Leaf
        }
        $null = $dryRunActions.Add($dryAction)
    }
    else {
        $body = @{ image = [convert]::ToBase64String((Get-Content $iconPath -AsByteStream)) }
        $restInfo = Get-RelativeConfigData -configToken 'RESTProjectIconSet'
        $restInputObject = @{
            method = $restInfo.method
            uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project.name))
            body   = ConvertTo-Json $body -Depth 10 -Compress
        }

        if ($PSCmdlet.ShouldProcess(('REST command to set icon [{0}] for project [{1}]' -f (Split-Path $iconPath -Leaf), $project.Name), "Invoke")) {
                $createCommandResponse = Invoke-RESTCommand @restInputObject

                if (-not [String]::IsNullOrEmpty($createCommandResponse.errorCode) -and $createCommandResponse.message -notlike "*teamId must not be *Empty*") {
                    Write-Error ('Failed to set icon for project [{0}] because of [{1} - {2}]' -f $project.Name, $createCommandResponse.typeKey, $createCommandResponse.message)
                    return
                }
                elseif(-not [String]::IsNullOrEmpty($createCommandResponse.errorCode) -and $createCommandResponse.message -like "*teamId must not be *Empty*"){
                    # The project was not yet fully propagated. Let's wait some time and try again.
                    Write-Verbose "Waiting 5 seconds for project propagation."
                    Start-Sleep 5
                    Set-ProjectIcon -iconPath $iconPath -Organization $Organization -project $project
                }
                else {
                    Write-Verbose ("Successfully set icon [{0}] for project [{1}]" -f (Split-Path $iconPath -Leaf), $project.name)
                }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould set icon for project:"
        $dryRunString += "`n==========================="

        $columns = @('#', 'Op', 'Id') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Id') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}
