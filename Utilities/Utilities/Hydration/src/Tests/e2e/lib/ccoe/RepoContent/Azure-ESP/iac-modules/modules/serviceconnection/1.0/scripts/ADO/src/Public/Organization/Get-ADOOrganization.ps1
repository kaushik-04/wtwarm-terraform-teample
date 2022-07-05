function Get-ADOOrganization {
    [Cmdletbinding()]
    param()

    $TaskDescriptor = "Get current organization config"
    try {
        Write-Verbose $TaskDescriptor
        $CurrentConfig = Get-ADOCurrentConfig
        if($CurrentConfig) {
            $Organization = ($CurrentConfig | Where-Object {$_ -like "organization*"}).split('=')[-1].trim()
            return $Organization
        } else {
            Write-Verbose "$TaskDescriptor - No config found"
            return $null
        }
        Write-Verbose "$TaskDescriptor - Found $Organization"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
    }
}