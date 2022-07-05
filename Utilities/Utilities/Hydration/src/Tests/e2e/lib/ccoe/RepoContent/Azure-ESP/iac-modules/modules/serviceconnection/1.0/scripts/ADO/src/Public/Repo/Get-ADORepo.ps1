function Get-ADORepo {
    [CmdletBinding()]
    param (
        [string]
        $Name,
        [switch]
        $Exact
    )
    $TaskDescriptor = 'Get and list all Azure Repos'
    $cmd = 'az repos list | ConvertFrom-Json | Sort-Object -Property Name'
    try {
        Write-Verbose $TaskDescriptor
        $azureRepos = Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Total found $($azureRepos.Count) Azure Repo(s)"
        if ($Exact) {
            $azureRepos = $azureRepos | Where-Object Name -EQ $Name
            if ($azureRepos) {
                $subcmd = "az repos show --repository $($azureRepos.Name) --detect false | ConvertFrom-Json"
                $azureRepos = Invoke-Expression $subcmd
            } else {
                Write-Warning "Found no repo with that exact name: $Name"
                return $null
            }
        } else {
            $azureRepos = $azureRepos | Where-Object Name -Match $Name
        }
        $azureRepos | ForEach-Object { Write-Verbose " - '$($_.Path) - $($_.Name)'" }
        Write-Verbose "$TaskDescriptor - Filtered to $($azureRepos.Count) Azure Repo(s)"
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
    return $azureRepos
}