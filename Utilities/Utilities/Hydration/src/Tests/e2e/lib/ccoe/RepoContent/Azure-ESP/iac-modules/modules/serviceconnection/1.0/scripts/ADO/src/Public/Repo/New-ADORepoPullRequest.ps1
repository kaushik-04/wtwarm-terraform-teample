function New-ADORepoPullRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Repository,
        [string]
        $TargetBranch = "master",
        [Parameter(Mandatory)]
        [string]
        $SourceBranch,
        [string]
        $Title,
        [string]
        $Description,
        [switch]
        $AutoComplete,
        [switch]
        $Squash,
        [switch]
        $DeleteSourceBranch
    )
    $RepoObj = Get-ADORepo -Name $Repository -Exact
    if (-not $RepoObj) {
        throw "The repo $Repository does not exist"
    }
    $SourceBranchObj = Get-ADORepoBranch -BranchName $SourceBranch -Repository $Repository
    if (-not $SourceBranchObj) {
        throw "The source branch '$SourceBranch' do not exist in the repo '$Repository'"
    }
    $TargetBranchObj = Get-ADORepoBranch -BranchName $TargetBranch -Repository $Repository
    if (-not $TargetBranchObj) {
        throw "The target branch '$TargetBranch' do not exist in the repo '$Repository'"
    }
    
    $TaskDescriptor = "Create new pull request, merging '$($SourceBranchObj.name)' to '$($TargetBranchObj.name)' on '$($RepoObj.Name)'"
    $cmd = "az repos pr create --title '$Title' --repository '$($RepoObj.Name)' --source-branch '$($SourceBranchObj.name)' --description '$Description' --auto-complete $AutoComplete --squash $Squash --delete-source-branch $DeleteSourceBranch --detect false | ConvertFrom-Json"
    Write-Verbose $cmd
    try {
        Write-Verbose $TaskDescriptor
        $azureRepoPR = Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
    return $azureRepoPR
}
