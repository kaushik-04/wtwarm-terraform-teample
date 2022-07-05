function Get-AzureCLIVersion {
    [CmdletBinding()]
    param ()
    
    $TaskDescriptor = "Getting Azure CLI version"
    $cmd = "az version | ConvertFrom-Json"
    try {
        Write-Verbose $TaskDescriptor
        $azversion = Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
    }
    return $azversion
}