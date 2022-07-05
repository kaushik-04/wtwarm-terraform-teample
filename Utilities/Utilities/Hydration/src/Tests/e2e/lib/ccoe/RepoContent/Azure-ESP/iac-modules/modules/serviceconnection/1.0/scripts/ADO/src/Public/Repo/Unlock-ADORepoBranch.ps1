function Unlock-ADORepoBranch {
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
    $TaskDescriptor = "Unlock branch '$($BranchObj.name)' on '$($RepoObj.Name)'"
    
    $BranchName = $BranchObj.name
    if (($BranchObj.Name).StartsWith('refs')){
        $BranchName = ($BranchName.Split('/') | Select-Object -skip 1) -join "/"
    }
    $cmd = "az repos ref unlock --repository '$($RepoObj.Name)' --name '$BranchName' --detect false | ConvertFrom-Json"
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