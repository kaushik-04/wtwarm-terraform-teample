function Get-ADORepoBranch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Repository,
        [string]
        $BranchName
    )
    $TaskDescriptor = 'Get and list all Azure Repo Branches'
    $cmd = "az repos ref list --repository '$Repository' --detect false | ConvertFrom-Json"
    try {
        Write-Verbose $TaskDescriptor
        $azureRepoBranches = Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Total found $($azureRepoBranches.Count) Azure Repo Branch(es)"
        $azureRepoBranches | ForEach-Object { Write-Verbose " - $($_.Name)'" }
        if ($BranchName) {
            $azureRepoBranches = $azureRepoBranches | Where-Object Name -like "*$BranchName*"
            Write-Verbose "$TaskDescriptor - Filtered to $($azureRepoBranches.Count) Azure Repo Branch(es)"
        }
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
    return $azureRepoBranches
}