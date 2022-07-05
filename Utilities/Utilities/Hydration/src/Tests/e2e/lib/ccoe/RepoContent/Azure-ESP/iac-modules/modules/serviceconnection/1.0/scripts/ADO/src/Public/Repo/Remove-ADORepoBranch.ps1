function Remove-ADORepoBranch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Repository,
        [Parameter(Mandatory)]
        [string]
        $BranchName
    )
    $RepoObj = Get-ADORepo -Name $Repository -Exact
    if (-not $RepoObj) {
        throw "The repo $Repository does not exist"
    }
    $BranchObj = Get-ADORepoBranch -BranchName $BranchName -Repository $Repository
    if (-not $BranchObj) {
        throw "The branch '$BranchName' do not exist in the repo '$Repository'"
    }
    $TaskDescriptor = "Remove branch '$($BranchObj.name)' on '$($RepoObj.Name)'"
    $cmd = "az repos ref delete --repository '$($RepoObj.Name)' --name '$($BranchObj.name)' --object-id '$($BranchObj.objectId)' --detect false | ConvertFrom-Json"
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