function Connect-ADOOrganization {
    [CmdletBinding(DefaultParameterSetName = "OrgName")]
    param (
        [Parameter(Mandatory,ParameterSetName = "OrgName")]
        [string]
        $OrganizationName,
        [Parameter(Mandatory,ParameterSetName = "OrgURI")]
        [string]
        $OrganizationURI,
        [Parameter(Mandatory)]
        [string]
        $ProjectName,
        [Parameter(Mandatory)]
        [string]
        $PAT
    )
    if ($PSCmdlet.ParameterSetName -eq "OrgURI") {
        $OrganizationName = $OrganizationURI.TrimEnd('/').Split('/')[-1]
    }
    if ($PSCmdlet.ParameterSetName -eq "OrgName") {
        $OrganizationURI = "https://dev.azure.com/$OrganizationName/"
    }
    $env:AZURE_DEVOPS_EXT_PAT = $PAT

    $TaskDescriptor = "Login to Azure DevOps Organization - $OrganizationName"
    $cmd = "`$env:AZURE_DEVOPS_EXT_PAT | az devops login --organization '$OrganizationURI'"
    try {
        Write-Verbose $TaskDescriptor
        Invoke-Expression $cmd
        Set-ADOOrganization -OrganizationName $OrganizationName
        Set-ADOProject -ProjectName $ProjectName
        Write-Verbose "$TaskDescriptor - Connected"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
}