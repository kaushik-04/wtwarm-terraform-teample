<#
.SYNOPSIS
Creates a given range of iterations in a given Azure DevOps Project

.DESCRIPTION
Creates a given range of iterations in a given Azure DevOps Project

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to create the items in. E.g. 'Module Playground'

.PARAMETER Iterations
Mandatory. The project iterations to create.

.PARAMETER DryRun
Optional. Simulate an end2end execution

.EXAMPLE
New-ProjectIterationRange -Organization Contoso -Project ADO-project -Iterations @(@{ name = 'Iteration 1'}, @{name = 'Iteration 2'})

Create a both iterations 'Iteration 1' & 'Iteration 2' in project [ADO-project|contoso]
#>
function New-ProjectIterationRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $Iterations,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    $relationStringProperty = 'GEN_RelationString'

    # All items except root
    $nonRootIterations = $Iterations | Where-Object { $_.$relationStringProperty -match ".*(\-\[_Child_\]\-).*" }
    # Sort do get the highest level items first
    $sortedIterations = $nonRootIterations | Sort-Object -Property @{ Expression = { $_.$relationStringProperty.Split('-[_Child_]-').Count }; Descending = $false }
    foreach ($iterationsToAdd in $sortedIterations) {

        if ($DryRun) {
            $dryAction = @{
                Op   = '+'
                Name = $iterationsToAdd.name
                Path = $iterationsToAdd.'GEN_RelationString'
            }

            if (-not ([String]::IsNullOrEmpty($iterationsToAdd.attributes.startDate))) {
                $dryAction['Start Date'] = ([DateTime]$iterationsToAdd.attributes.startDate).ToString('yyyy-MM-dd')
            }
            if (-not ([String]::IsNullOrEmpty($iterationsToAdd.attributes.finishDate))) {
                $dryAction['Finish Date'] = ([DateTime]$iterationsToAdd.attributes.finishDate).ToString('yyyy-MM-dd')
            }

            $null = $dryRunActions.Add($dryAction)
        }
        else {
            # Build url path
            # -------------
            $root, $children = $iterationsToAdd.$relationStringProperty.Split('-[_Child_]-')
            $childArray = $children | ForEach-Object { [uri]::EscapeDataString($_) }
            # The required path is represented by all parents of current iteration lvl excluding root
            $path = ($children.Count -gt 1) ? $childArray[0..($childArray.Length - 2)] -join '/' : ''

            # Build Body
            # ----------
            $body = @{ name = $iterationsToAdd.Name }
            if (-not [String]::IsNullOrEmpty($iterationsToAdd.attributes.startDate) -or -not [String]::IsNullOrEmpty($iterationsToAdd.attributes.finishDate)) {
                $body['attributes'] = @{}
            }

            if (-not [String]::IsNullOrEmpty($iterationsToAdd.attributes.startDate)) { $body.attributes['startDate'] = ([DateTime]$iterationsToAdd.attributes.startDate).ToString('yyyy-MM-ddThh:mm:ssZ') }
            if (-not [String]::IsNullOrEmpty($iterationsToAdd.attributes.finishDate)) { $body.attributes['finishDate'] = ([DateTime]$iterationsToAdd.attributes.finishDate).ToString('yyyy-MM-ddThh:mm:ssZ') }

            # Build & Fire Request
            # ---------=======----
            $restInfo = Get-RelativeConfigData -configToken 'RESTProjectIterationClassificationNodeCreate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), $path)
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }
            if ($PSCmdlet.ShouldProcess(("Iteration path [{0}] to project [{1}]" -f $iterationsToAdd.Name, $Project), "Add")) {
                $res = Invoke-RESTCommand @restInputObject
                if ($res.errorCode) {
                    Write-Error ('Failed to create iteration path [{0}|{1}] because of [{3} - {4}]' -f $Project, $iterationsToAdd.Name, $res.typeKey, $res.message)
                    continue
                }
                elseif (-not $res.name) {
                    Write-Error ('Failed to create iteration path [{0}|{1}] because of [{2}] using uri [{3}] and body [{4}].' -f $Project, $iterationsToAdd.Name, $res.Message, $restInputObject.uri, $restInputObject.body)
                    continue
                }
                else {
                    Write-Verbose ("[+] Created iteration [{0}] in path [{1}]" -f $res.Name, $iterationsToAdd.$relationStringProperty) -Verbose
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould add iterations:"
        $dryRunString += "`n================"

        $columns = @('#', 'Op') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}