function Set-ADOOrganization {
    [CmdletBinding()]
    param (
        [string]
        $OrganizationName
    )
    
    if (($null -eq $OrganizationName) -or ("" -eq $OrganizationName)) {
        $orgUrl = ""
    } else {
        $orgUrl = "https://dev.azure.com/$OrganizationName/"
    }

    $TaskDescriptor = "Set Azure DevOps configuration to organization: '$OrganizationName'"
    $cmd = "az devops configure --defaults organization='$orgUrl'"
    try {
        Write-Verbose $TaskDescriptor
        Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        Write-Warning $_
    }

    if (($null -eq $OrganizationName) -or ("" -eq $OrganizationName)) {
        return $null
    } else {
        return $orgUrl
    }
}