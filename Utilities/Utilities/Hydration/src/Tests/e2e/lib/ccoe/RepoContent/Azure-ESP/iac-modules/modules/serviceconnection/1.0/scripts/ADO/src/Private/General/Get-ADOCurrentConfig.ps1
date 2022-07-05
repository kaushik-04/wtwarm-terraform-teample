function Get-ADOCurrentConfig {
    [CmdletBinding()]
    param()

    $TaskDescriptor = "Get current config for Azure DevOps"
    $cmd = "az devops configure --list"
    try {
        Write-Verbose $TaskDescriptor
        $CurrentConfig = Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
        $CurrentConfig | ForEach-Object {Write-Verbose $_}
        return $CurrentConfig
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
}