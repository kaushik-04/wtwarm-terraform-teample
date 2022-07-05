function Assert-ADOExtensionVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [version]
        $MinimumVersion
    )

    $TaskDescriptor = "Checking the Azure CLI DevOps extension version"
    $cmd = "(Get-AzureCLIVersion).extensions.'azure-devops'"
    try {
        Write-Verbose $TaskDescriptor
        $CmdResult = Invoke-Expression $cmd 
        $OkVersion = $CmdResult -ge $MinimumVersion
        Write-Verbose "$TaskDescriptor - Minimum: $MinimumVersion"
        Write-Verbose "$TaskDescriptor - Acctual: $CmdResult"
        if ($OkVersion) {
            Write-Verbose "$TaskDescriptor - Ok"
        } else {
            Write-Verbose "$TaskDescriptor - Not ok"
        }
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        Write-Warning $_
    }
    return ($OkVersion)
}