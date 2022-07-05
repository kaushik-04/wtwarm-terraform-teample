function Set-ADORepoPullRequestVote {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int]
        $PullRequestID,
        [ValidateSet('approve', 'approve-with-suggestions', 'reject', 'reset', 'wait-for-author')]
        [string]
        $Vote = "approve"
    )
    $TaskDescriptor = "Set Azure Repo Pull Request vote to '$Vote'"
    $cmd = "az repos pr set-vote --id $PullRequestID --vote $Vote --detect false | ConvertFrom-Json"
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