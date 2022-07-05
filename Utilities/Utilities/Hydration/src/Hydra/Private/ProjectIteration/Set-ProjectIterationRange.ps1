<#
.SYNOPSIS
Updates a range of existng iterations in the given Azure DevOps Project

.DESCRIPTION
Updates a range of existng iterations in the given Azure DevOps Project

.PARAMETER Organization
Mandatory. The organization to update the items in. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to update the items in. E.g. 'Module Playground'

.PARAMETER iterationsToUpdate
Mandatory. The project iterations to update including the required information.

.PARAMETER DryRun
Optional. Simulate an end2end execution

.EXAMPLE
Set-ProjectIterationRange -Organization Contoso -Project ADO-project -iterationsToUpdate  @(@{id = 1; Name = "Iteration 1 New"; 'Old Name' = "Iteration 1"; url = "https://dev.azure.com/contoso/Module%20Playground/_apis/wit/classificationNodes/Iterations/Iteration%201"; GEN_RelationString = "Module Playground-[_Child_]-Iteration 1"})

Update the given item with ID 1 in project [ADO-project|contoso] with a new name 'Iteration 1 New'
#>
function Set-ProjectIterationRange {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $iterationsToUpdate,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    $relationStringProperty = 'GEN_RelationString'

    foreach ($iteration in $iterationsToUpdate) {

        if ($DryRun) {
            $dryAction = @{
                Op = '^'
                ID = $iteration.id
            }

            if(-not ([String]::IsNullOrEmpty($iteration.Name))) {
                $dryAction['Name'] = "[{0} => {1}]" -f (($iteration.'Old Name') ? $iteration.'Old Name' : '()'), $iteration.Name
            }
            if(-not ([String]::IsNullOrEmpty($iteration.startDate))) {
                $dryAction['Start Date'] = "[{0} => {1}]" -f (($iteration.startDate) ? ([DateTime]$iteration.'Old startDate').ToString('yyyy-MM-dd') : '()'), ([DateTime]$iteration.startDate).ToString('yyyy-MM-dd')
            }
            if(-not ([String]::IsNullOrEmpty($iteration.finishDate))) {
                $dryAction['Finish Date'] = "[{0} => {1}]" -f (($iteration.finishDate) ? ([DateTime]$iteration.'Old finishDate').ToString('yyyy-MM-dd') : '()'), ([DateTime]$iteration.finishDate).ToString('yyyy-MM-dd')
            }

            $null = $dryRunActions.Add($dryAction)
        }
        else {
            # Build body
            $body = @{ id = $iteration.id }
            if (-not [String]::IsNullOrEmpty($iteration.Name)) { $body['Name'] = $iteration.Name }

            if (-not [String]::IsNullOrEmpty($iteration.startDate) -or -not [String]::IsNullOrEmpty($iteration.finishDate)) {
                $body['attributes'] = @{}
            }

            if (-not [String]::IsNullOrEmpty($iteration.startDate)) { $body.attributes['startDate'] = ([DateTime]$iteration.startDate).ToString('yyyy-MM-ddThh:mm:ssZ') }
            if (-not [String]::IsNullOrEmpty($iteration.finishDate)) { $body.attributes['finishDate'] = ([DateTime]$iteration.finishDate).ToString('yyyy-MM-ddThh:mm:ssZ') }

            # Build path (required to maintain hierarchy)
            $path = ''
            $relationParts = $iteration.$relationStringProperty.Split('-[_Child_]-')
            if ($relationParts.count -gt 2) {
                # Looks like: @('root', -> parent(s) <-, iteration). We need only the parents
                $path = ($relationParts[1..($relationParts.Count - 2)] | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
            }

            # Build & execute command
            $restInfo = Get-RelativeConfigData -configToken 'RESTProjectIterationClassificationNodeUpdate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), $path)
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to update iteration [{0}]' -f $iteration.Name), "Invoke")) {
                $updateCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                    Write-Error ('Failed to update iteration [{0}] because of [{1} - {2}]. Make sure the iteration does exist.' -f $iteration.Name, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                    continue
                }
                else {
                    Write-Verbose ("[^] Successfully updated iteration [{0}]" -f $iteration.$relationStringProperty) -Verbose
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould update iterations to:"
        $dryRunString += "`n==========================="

        $columns = @('#', 'Op', 'Id') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op','Id')})
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}