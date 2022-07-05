function Update-AzureCLI {
    [Cmdletbinding()]
    param(
        [switch]
        $Silent
    )
    $TaskDescriptor = "Upgrading Azure CLI"
    $cmd = "az upgrade --all"
    if ($PSBoundParameters.ContainKey('Silent')) {
        $cmd, "--yes" -join " "
    }

    try {
        Write-Verbose $TaskDescriptor
        Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
    return $true
}
