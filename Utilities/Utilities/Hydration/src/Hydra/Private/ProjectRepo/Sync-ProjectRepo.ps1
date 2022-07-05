<#
.SYNOPSIS
Create or delete ADO Repos

.DESCRIPTION
Create or delete ADO Repos

.PARAMETER localRepos
Mandatory. The Repos to create

.PARAMETER ConfigurationRoot
Mandatory. The path of the Repos to hydrate

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to create the items in. E.g. 'Module Playground'

.PARAMETER removeExcessItems
Optional. Control whether or not to remove Repos that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-ProjectRepo -localRepos @(@{ name = 'repo1' }, @{ name = 'repo1' }) -ConfigurationRoot './resources/repos' -organization 'contoso' -project 'Modules'

Create repository 'repo1' & 'repo2' in project [contoso|Modules]
#>
function Sync-ProjectRepo {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localRepos,

        [Parameter(Mandatory = $true)]
        [string] $ConfigurationRoot,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    $SyncProcessingStartTime = Get-Date

    ################
    #   Get Data   #
    ################

    # Get remote repos
    $remoteRepos = Get-RepoList -Organization $Organization -Project $Project

    ####################
    #   Create Repos   #
    ####################

    $ReposToCreate = $localRepos | Where-Object { $_.Name -notin $remoteRepos.Name }
    if ($ReposToCreate.Count -gt 0) {
        $newRepoInputObject = @{
            Organization  = $Organization
            Project       = $Project
            reposToCreate = $reposToCreate
            DryRun        = $DryRun
        }
        if ($PSCmdlet.ShouldProcess(("Creation of [{0}] repositories in project [{1}]" -f $ReposToCreate.Count, $Project), "Initiate")) {
            New-Repository @newRepoInputObject
        }
    }
    else {
        Write-Verbose "No Repos to create"
    }

    ####################
    #  Hydrate Repos   #
    ####################

    $ReposToHydrate = $localRepos | Where-Object { (-not [String]::IsNullOrEmpty($_.relativePath)) -and (test-path (Join-Path $ConfigurationRoot $_.relativePath)) }
    if ($ReposToHydrate.Count -gt 0) {
        $pushRepoInputObject = @{
            Organization      = $Organization
            Project           = $Project
            RepoRoot          = $ConfigurationRoot
            localRepos        = $ReposToHydrate
            removeExcessItems = $removeExcessItems
            DryRun            = $DryRun
        }
        Push-ProjectRepo @pushRepoInputObject
    }
    else {
        Write-Verbose "No Repos to push content"
    }

    ####################
    #   Remove Repos   #
    ####################
    if ($removeExcessItems) {
        $ReposToRemove = $remoteRepos | Where-Object { $_.Name -notin $localRepos.Name }
        if ($ReposToRemove.Count -gt 0) {
            $newRepoInputObject = @{
                Organization  = $Organization
                Project       = $Project
                ReposToRemove = $ReposToRemove
                DryRun        = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("Removal of [{0}] repos from project [{1}]" -f $ReposToRemove.Count, $Project), "Initiate")) {
                Remove-Repo @newRepoInputObject
            }
        }
        else {
            Write-Verbose "No repos to remove"
        }
    }

    $elapsedTime = (get-date) - $SyncProcessingStartTime
    $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
    Write-Verbose ("Repository sync took [{0}]" -f $totalTime)
}