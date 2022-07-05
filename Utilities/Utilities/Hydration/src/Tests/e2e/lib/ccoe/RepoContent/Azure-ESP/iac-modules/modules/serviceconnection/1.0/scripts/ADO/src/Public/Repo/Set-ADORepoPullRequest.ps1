function Set-ADORepoPullRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int]
        $PullRequestID,
        [ValidateSet('abandoned', 'active','completed')]
        [string]
        $Status = "completed"
    )
    $TaskDescriptor = "Set Azure Repo Pull Request status to '$Status'"
    $cmd = "az repos pr update --id '$PullRequestID' --status $Status --detect false | ConvertFrom-Json"
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