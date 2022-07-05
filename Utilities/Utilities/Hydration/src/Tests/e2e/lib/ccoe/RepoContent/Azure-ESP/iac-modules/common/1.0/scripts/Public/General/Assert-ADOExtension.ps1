function Assert-ADOExtension {
    [CmdletBinding()]
    param()
    
    $TaskDescriptor = "Check if the Azure CLI extension for Azure DevOps is installed"
    $cmd = "az devops --help"
    try {
        Write-Verbose $TaskDescriptor
        $az = Invoke-Expression $cmd
        if ($az) {
            Write-Verbose "$TaskDescriptor - Installed"
        } else {
            Write-Verbose "$TaskDescriptor - Not installed"
        }
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        Write-Warning $_
    }
    return ($null -ne $az)
}