<#
.SYNOPSIS
Creates a new Area for a given Azure DevOps Project

.DESCRIPTION
Creates a new Area for a given Azure DevOps Project

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to create the items in. E.g. 'Module Playground'

.PARAMETER AreaPaths
Mandatory. The project areas to create.

.PARAMETER DryRun
Optional. Simulate an end2end execution

.EXAMPLE
New-ProjectAreaRange -Organization Contoso -Project ADO-project -AreaPaths @(@{ name = 'Area 1'}, @{name = 'Area 2'})

Create a both areas 'Area 1' & 'Area 2' in project [ADO-project|contoso]
#>
function New-ProjectAreaRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
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

    # All items except root
    $nonRootAreaPaths = $AreaPaths | Where-Object { $_.$relationStringProperty -match ".*(\-\[_Child_\]\-).*" }
    # Sort do get the highest level items first
    $sortedAreaPaths = $nonRootAreaPaths | Sort-Object -Property @{ Expression = { $_.$relationStringProperty.Split('-[_Child_]-').Count }; Descending = $false }
    foreach ($areaPathToAdd in $sortedAreaPaths) {

        if ($DryRun) {
            $dryAction = @{
                Op   = '+'
                Name = $areaPathToAdd.name
                Path = $areaPathToAdd.'GEN_RelationString'
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $root, $children = $areaPathToAdd.$relationStringProperty.Split('-[_Child_]-')
            $childArray = $children | ForEach-Object { [uri]::EscapeDataString($_) }
            # The required path is represented by all parents of current area lvl excluding root
            $path = ($children.Count -gt 1) ? $childArray[0..($childArray.Length - 2)] -join '/' : ''
            $restInfo = Get-RelativeConfigData -configToken 'RESTProjectAreaClassificationNodeCreate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), $path)
                body   = ConvertTo-Json @{ name = $areaPathToAdd.Name } -Depth 10 -Compress
            }
            if ($PSCmdlet.ShouldProcess(("Area path [{0}] from project [{1}]" -f $areaPathToAdd.Name, $Project), "Add")) {
                $res = Invoke-RESTCommand @restInputObject
                if ($res.errorCode) {
                    Write-Error ("[{0}]: {1}" -f $res.typeKey, $res.message)
                    continue
                }
                else {
                    Write-Verbose ("[+] Created area path [{0}]" -f $areaPathToAdd.$relationStringProperty) -Verbose
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould add areas:"
        $dryRunString += "`n================"

        $columns = @('#', 'Op') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op')})
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}