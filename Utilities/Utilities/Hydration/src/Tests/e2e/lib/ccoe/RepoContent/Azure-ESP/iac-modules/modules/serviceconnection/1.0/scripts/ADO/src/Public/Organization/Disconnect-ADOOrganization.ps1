function Disconnect-ADOOrganization {
    [CmdletBinding()]
    param ()

    $OrgName = Get-ADOOrganization
    $TaskDescriptor = "Disconnect from Azure DevOps Organization - $OrgName"
    $cmd = "az devops logout"
    try {
        Write-Verbose $TaskDescriptor
        Invoke-Expression $cmd
        Set-ADOOrganization -OrganizationName ''
        Set-ADOProject -ProjectName ''
        Write-Verbose "$TaskDescriptor - Removing PAT token"
        $env:AZURE_DEVOPS_EXT_PAT = ''
        Write-Verbose "$TaskDescriptor - Removing PAT token - Ok"
        Write-Verbose "$TaskDescriptor - Disconnected"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
}