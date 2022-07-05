function Assert-AzureCLI {
    [CmdletBinding()]
    param()

    $TaskDescriptor = "Check if Azure CLI is installed"
    $cmd = "az --help"
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