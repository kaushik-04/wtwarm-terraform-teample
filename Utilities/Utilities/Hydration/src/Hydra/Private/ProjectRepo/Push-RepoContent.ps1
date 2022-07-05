<#
.SYNOPSIS
Push content to ADO Repos

.DESCRIPTION
Push content to ADO Repos.
Flow:
1. Clone remote repo
2. Checkout target branch
3. Overwrite remote files with local (by copying the local files to the cloned repository folder)
4. Push changes

.PARAMETER localRepos
Mandatory. The Repos to hydrate

.PARAMETER RepoRoot
Mandatory. The Repos path to hydrate

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to create the items in. E.g. 'Module Playground'

.PARAMETER DryRun
Optional. Simulate the end2end execution

.PARAMETER removeExcessItems
Optional. Control whether or not to remove files that are not defined in the local dataset

.EXAMPLE
Push-ProjectRepo -localRepos @(@{ name = 'Wiki', relativePath = '.\Repos\Wiki' }, @{ name = 'Components', relativePath = '.\Repos\Components'})  -RepoRoot 'resources/' -organization 'contoso' -project 'Modules'

Push content to repository 'Wiki' & 'Components' in project [contoso|Modules]
#>

function Push-ProjectRepo {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localRepos,

        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }
    else {
        if ([String]::IsNullOrEmpty($env:AZURE_DEVOPS_EXT_PAT)) {
            Write-Verbose "Generating DevOps PAT" -Verbose
            $pat = (New-DevOpsPAT -organization $Organization).token
        }
        else {
            Write-Verbose "Leveraging provided DevOps PAT" -Verbose
            $pat = $env:AZURE_DEVOPS_EXT_PAT
        }
    }

    $SyncProcessingStartTime = Get-Date

    ####################
    #   Push Content   #
    ####################

    if ($localRepos) {
        foreach ($repo in $localRepos) {

            if ($DryRun) {
                $dryAction = @{
                    Op           = '+'
                    name         = $repo.Name
                    path         = $repo.relativePath
                    targetbranch = $repo.targetbranch
                }
                $null = $dryRunActions.Add($dryAction)
            }
            else {
                try {
                    Write-Verbose ("Repo {0} hydration for project: {1} started" -f $repo.name, $Project)
                    $url = (Get-RelativeConfigData -configToken 'DEVOPS_GIT_URL') -f ($pat, [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), [uri]::EscapeDataString($repo.name))

                    #Save the current location where the script is running
                    $currentLocation = Get-Location

                    #Create a temporal path to create the repo and push the files
                    $temp = [System.IO.Path]::GetTempPath()
                    $tempFolder = (Get-Random).ToString()
                    $tempPath = Join-Path $temp $tempFolder
                    #If the path exists we remove it
                    if (test-path $tempPath) { remove-item -literalpath $tempPath -Force -Recurse ; Write-Verbose ("Folder removed: {0}" -f $tempPath) }

                    $null = New-Item -Path $tempPath -ItemType 'Directory'


                    Set-Location $tempPath

                    # Setup git details
                    $gitUserName = git config 'user.name'
                    if ([String]::IsNullOrEmpty($gitUserName)) {
                        Write-Warning 'Using default git user.name [hydration]'
                        git config --global user.name 'hydration'
                    }
                    $gitEmail = git config 'user.email'
                    if ([String]::IsNullOrEmpty($gitEmail)) {
                        Write-Warning 'Using default git user.email [hydration@microsoft.com]'
                        git config --global user.email "hydration@microsoft.com"
                    }

                    # Clone remote repo
                    $destinationDirectory = Join-Path $tempPath $repo.Name
                    if (-not (Test-Path $destinationDirectory)) {
                        git clone $url
                    }

                    [string]$sourceDirectory = Join-Path $RepoRoot $repo.relativePath

                    # push all changes and go back to the starting location
                    Set-Location $destinationDirectory

                    if($removeExcessItems) {
                        # we remove all current to only leverage what we have local and overwrite the state
                        Get-ChildItem $destinationDirectory | Remove-Item -Force -Recurse
                    }

                    #copy content from the local repo to the cloned repo
                    $null = Copy-item -Force -Recurse "$sourceDirectory\*" -Destination $destinationDirectory

                    #Initialize the remote repo (we don't need to clone an empty repo)
                    if ($branchExists = ((git branch -r) | ForEach-Object { $_.Trim() }) -contains ('origin/{0}' -f $repo.targetBranch)) {
                        # branch already exists in target
                        git checkout $repo.targetBranch
                    }
                    else {
                        # create new branch
                        git checkout -b $repo.targetbranch
                    }

                    #wait to propagate changes
                    Start-Sleep -s 5

                    git add .
                    git commit -m "Hydration commit: Push repo Content"

                    if ($branchExists) { git pull origin $repo.targetbranch }
                    git push origin $repo.targetbranch

                    Write-Verbose ("Files commited to {0} branch on Repo {1}" -f $repo.targetbranch, $repo.Name)

                    #return to the  initial location where the script was running
                    Set-Location $currentLocation
                }
                catch {
                    throw $_
                }
                finally {
                    # Remove temp files and folders
                    if ((-not [String]::IsNullOrEmpty($tempPath)) -and (Test-Path $tempPath)) {
                        Write-Verbose ("Removing temp files from {0}" -f $tempPath)
                        Remove-item -literalpath $tempPath -Force -Recurse
                    }
                }
            }
        }
    }
    else {
        Write-Verbose "No Repos to push content"
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould hydrate repos:"
        $dryRunString += "`n===================="

        $columns = @('#', 'Op', 'Name') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Name') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }

    #elapsed time
    $elapsedTime = (get-date) - $SyncProcessingStartTime
    $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
    Write-Verbose ("Repository hydration took [{0}]" -f $totalTime)
}