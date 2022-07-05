<#
.SYNOPSIS
Deletes an existng Area from a given Azure DevOps Project

.DESCRIPTION
Deletes an existng Area from a given Azure DevOps Project

.PARAMETER Organization
Mandatory. The organization to remove the items from. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to remove the items from. E.g. 'Module Playground'

.PARAMETER AreaPaths
Mandatory. The project areas to remote.

.PARAMETER DryRun
Optional. Simulate an end2end execution

.EXAMPLE
Remove-ProjectAreaRange -Organization Contoso -Project ADO-project -AreaPaths @(@{ name = 'Area 1'}, @{name = 'Area 2'})

Remove area path 'Area 1' & 'Area 2' from project [ADO-project|contoso]
#>
function Remove-ProjectAreaRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $AreaPaths,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    $relationStringProperty = 'GEN_RelationString'
    $pathsRemoved = [System.Collections.ArrayList]@()
    # All items except root
    $nonRootAreaPaths = $AreaPaths | Where-Object { $_.$relationStringProperty -match ".*(\-\[_Child_\]\-).*" }
    # Sort do get the highest level items first
    $sortedAreaPaths = $nonRootAreaPaths | Sort-Object -Property @{ Expression = { $_.$relationStringProperty.Split('-[_Child_]-').Count }; Descending = $false }
    foreach ($areaPathToRemove in $sortedAreaPaths) {

        if ($DryRun) {
            $dryAction = @{
                Op   = '-'
                ID   = $areaPathToRemove.Id
                Name = $areaPathToRemove.name
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            if (($pathsRemoved | Where-Object { ($areaPathToRemove.$relationStringProperty).StartsWith($_) }).Count -eq 0) {
                # extract area path: https://dev.azure.com/contoso/a0e8d9f6-0191-4f37-81ce-4f4e7ba1411a/_apis/wit/classificationNodes/Areas/ > Area%204 <
                $path = $areaPathToRemove.url.Split('classificationNodes/Areas/')[1]
                $restInfo = Get-RelativeConfigData -configToken 'RESTProjectAreaClassificationNodeRemove'
                $restInputObject = @{
                    method = $restInfo.method
                    uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), $path)
                }
                if ($PSCmdlet.ShouldProcess(("Area path [{0}] from project [{1}]" -f $areaPathToRemove.Name, $Project), "Remove")) {
                    $res = Invoke-RESTCommand @restInputObject
                    if($res.errorCode) {
                        Write-Error ("[{0}]: {1}" -f $res.typeKey, $res.message)
                        continue
                    } else {
                        Write-Verbose ("[-] Removed area & child paths of [{0}]" -f $areaPathToRemove.$relationStringProperty) -Verbose
                    }
                }
                $null = $pathsRemoved.Add($areaPathToRemove.$relationStringProperty)
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould remove areas:"
        $dryRunString += "`n==================="

        $columns = @('#', 'Op', 'Id') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op','Id')})
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}