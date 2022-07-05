function Get-ADOPermission {
    param(
        [Parameter(Mandatory)]
        [string]
        $GroupID,
        [Parameter(Mandatory)]
        [guid]
        $ObjectID
    )
    $ServiceConnectionNamespace = Get-ADOSecurityNamespace -Name ServiceEndpoint
    $ADOProject = Get-ADOProject
    $ServiceConnectionID = "endpoints/$($ADOProject.ID)/$ObjectID"

    $TaskDescriptor = "Getting permission on service connection"
    $cmd = "az devops security permission show --id $($ServiceConnectionNamespace.namespaceId) --subject $GroupID --token $ServiceConnectionID --detect false"
    
    try {
        Write-Verbose $TaskDescriptor
        $SubjectObj = Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
        return $SubjectObj | ConvertFrom-Json
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
}