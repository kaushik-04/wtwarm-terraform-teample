<#
.SYNOPSIS
    Creates a new Repo for a given Azure DevOps Project

.DESCRIPTION
    Creates a new Repo for a given Azure DevOps Project

.PARAMETER Organization
Mandatory. Organization Name. E.g. 'contoso'

.PARAMETER Project
Mandatory. Azure DevOps Project Name

.PARAMETER reposToCreate
Mandatory. The Repos to create. Each object must at least contain a name.

.PARAMETER DryRun
Simulate and end2end execution

.EXAMPLE
New-Repository -Organization Contoso -Project ADO-project -ReposToCreate @(@{ Name = 'Components'})

Create new Repo 'Components'
#>
function New-Repository {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $reposToCreate,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    $ProjectObject = get-project -Organization $Organization -project $Project

    foreach ($repo in $reposToCreate) {

        if ($DryRun) {
            $dryAction = @{
                Op   = '+'
                name = $repo.Name
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $body = @{ name = $repo.Name }
            $body['Project'] = @{'id' = $ProjectObject.id }
            $restInfo = Get-RelativeConfigData -configToken 'RESTRepositoriesCreate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project))
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to create a repo [{0}]' -f $repo.value), "Invoke")) {
                $createCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($createCommandResponse.errorCode)) {
                    Write-Error ('Failed to create repository [{0}] because of [{1}]' -f $repo.Name, $createCommandResponse.typeKey)
                    return
                }
                else {
                    Write-Verbose ("Successfully created repo [{0}]" -f $createCommandResponse.name)
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould create repos:"
        $dryRunString += "`n==================="

        $columns = @('#', 'Op') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op')})
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}