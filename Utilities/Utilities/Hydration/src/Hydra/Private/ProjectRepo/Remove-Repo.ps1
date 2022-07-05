<#
.SYNOPSIS
Deletes an existing Repo from a given Azure DevOps Project

.DESCRIPTION
Deletes an existing Repo from a given Azure DevOps Project

.PARAMETER Organization
Organization Name

.PARAMETER Project
Project Name

.PARAMETER repoToRemove
Mandatory. The repos to remove. The identifier must be the id of the repo.

.PARAMETER DryRun
Simulate and end2end execution

.EXAMPLE
Remove-Repo -Organization Contoso -Project ADO-project -RepoToRemove @(@{id = '99999999-9999-9999-9999-999999999999'})

Remove Repo with Id '99999999-9999-9999-9999-999999999999' from DevOps project 'ADO-project'
#>
function Remove-Repo {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $reposToRemove,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($repo in $reposToRemove) {

        if ($DryRun) {
            $dryAction = @{
                Op   = '-'
                Name = $repo.Name
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {

            $restInfo = Get-RelativeConfigData -configToken 'RESTRepositoriesRemove'
            $restInputObject = @{
                method = $restInfo.method
                uri    = $restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), $repo.id
            }

            if ($PSCmdlet.ShouldProcess(('REST command to remove project [{0}]' -f $repo.id), "Invoke")) {
                $removeCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($removeCommandResponse.errorCode)) {
                    Write-Error ('Failed to remove repo [{0}] because of [{1}]. Make sure the repo does exist.' -f $repo.id, $removeCommandResponse.typeKey)
                    return
                }
            }
            Write-Verbose ("Successfully removed repo [{0}]" -f $repo.Name)
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould remove repos:"
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