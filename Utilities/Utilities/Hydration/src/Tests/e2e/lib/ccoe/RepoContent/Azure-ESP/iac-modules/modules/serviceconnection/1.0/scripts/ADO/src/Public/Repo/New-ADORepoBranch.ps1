function New-ADORepoBranch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Repository,
        [Parameter(Mandatory)]
        [string]
        $BranchName,
        [string]
        $SourceBranch = "master"
    )
    $RepoObj = Get-ADORepo -Name $Repository -Exact
    if (-not $RepoObj) {
        throw "The repo $Repository does not exist"
    }
    $SourceBranchObj = Get-ADORepoBranch -BranchName $SourceBranch -Repository $Repository
    if (-not $SourceBranchObj) {
        throw "The branch '$SourceBranch' do not exist in the repo '$Repository'"
    }
    $TaskDescriptor = "Create new branch '$($SourceBranchObj.name)' on '$($RepoObj.Name)'"
    $cmd = "az repos ref create --repository '$($RepoObj.Name)' --name heads/$BranchName --object-id '$($SourceBranchObj.objectid)' --detect false | ConvertFrom-Json"
    Write-Verbose $cmd
    try {
        Write-Verbose $TaskDescriptor
        $azureRepoBranch = Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
    return $azureRepoBranch
}