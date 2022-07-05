<#
.SYNOPSIS
Deletes a range of existng iterations from a given Azure DevOps Project

.DESCRIPTION
Deletes a range of existng iterations from a given Azure DevOps Project

.PARAMETER Organization
Mandatory. The organization to remove the items from. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to remove the items from. E.g. 'Module Playground'

.PARAMETER IterationPaths
Mandatory. The project iterations to remove.

.PARAMETER DryRun
Optional. Simulate an end2end execution

.EXAMPLE
Remove-ProjectIterationRange -Organization Contoso -Project ADO-project -IterationPaths @(@{ name = 'Iteration 1'}, @{name = 'Iteration 2'})

Remove iteration path 'Iteration 1' & 'Iteration 2' from project [ADO-project|contoso]
#>
function Remove-ProjectIterationRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $IterationPaths,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    $relationStringProperty = 'GEN_RelationString'
    $pathsRemoved = [System.Collections.ArrayList]@()
    # All items except root
    $nonRootIterationPaths = $IterationPaths | Where-Object { $_.$relationStringProperty -match ".*(\-\[_Child_\]\-).*" }
    # Sort do get the highest level items first
    $sortedIterationPaths = $nonRootIterationPaths | Sort-Object -Property @{ Expression = { $_.$relationStringProperty.Split('-[_Child_]-').Count }; Descending = $false }
    foreach ($iterationPathToRemove in $sortedIterationPaths) {

        if ($DryRun) {
            $dryAction = @{
                Op   = '-'
                ID   = $iterationPathToRemove.Id
                Name = $iterationPathToRemove.name
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            if (($pathsRemoved | Where-Object { ($iterationPathToRemove.$relationStringProperty).StartsWith($_) }).Count -eq 0) {
                # extract iteration path: https://dev.azure.com/contoso/a0e8d9f6-0191-4f37-81ce-4f4e7ba1411a/_apis/wit/classificationNodes/Iterations/ > Iteration%204 <
                $path = $iterationPathToRemove.url.Split('classificationNodes/Iterations/')[1]
                $restInfo = Get-RelativeConfigData -configToken 'RESTProjectIterationClassificationNodeRemove'
                $restInputObject = @{
                    method = $restInfo.method
                    uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), $path)
                }
                if ($PSCmdlet.ShouldProcess(("Iteration path [{0}] from project [{1}]" -f $iterationPathToRemove.Name, $Project), "Remove")) {
                    $res = Invoke-RESTCommand @restInputObject
                    if($res.errorCode) {
                        Write-Error ("[{0}]: {1}" -f $res.typeKey, $res.message)
                        continue
                    } else {
                        Write-Verbose ("[-] Removed iteration & child paths of [{0}]" -f $iterationPathToRemove.$relationStringProperty) -Verbose
                    }
                }
                $null = $pathsRemoved.Add($iterationPathToRemove.$relationStringProperty)
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould remove iterations:"
        $dryRunString += "`n========================"

        $columns = @('#', 'Op', 'Id') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op','Id')})
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}