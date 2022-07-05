enum ADOActions{
    None = 0
    Use = 1
    Administer = 2
    Create = 4
    ViewAuthorization = 8
    ViewEndpoint = 16
    User = 1
    Administrator = 3
    Reader = 16
}

function Set-ADOPermission {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [guid]
        $ObjectID,
        [string]
        $GroupID,
        [ADOActions[]]
        $Allow,
        [ADOActions[]]
        $Deny,
        [switch]
        $AllowAllPipelineAccess
    )
    $ServiceConnectionNamespace = Get-ADOSecurityNamespace -Name ServiceEndpoint
    $ADOProject = Get-ADOProject
    $ServiceConnectionID = "endpoints/$($ADOProject.ID)/$ObjectID"

    if ($GroupID) {
        $AllowPermissions = 0
        $Allow | ForEach-Object {$AllowPermissions += $_}

        $DenyPermissions = 0
        $Deny | ForEach-Object {$AllowPermissions += $_}


        $TaskDescriptor = "Setting permission on service connection"
        $cmd = "az devops security permission update --deny-bit $DenyPermissions --allow-bit $AllowPermissions --namespace-id $($ServiceConnectionNamespace.namespaceId) --subject $GroupID --token $ServiceConnectionID --detect false"
        
        try {
            Write-Verbose "$TaskDescriptor - $ObjectID - $GroupID"
            $SubjectObj = Invoke-Expression $cmd
            Write-Verbose "$TaskDescriptor - Ok"
        } catch {
            Write-Verbose "$TaskDescriptor - Failed"
            throw $_
        }
    }
    if ($AllowAllPipelineAccess){
        $TaskDescriptor = "Setting permission on service connection to all pipelines to $AllowAllPipelineAccess"
        $cmd = "az devops service-endpoint update --id $ObjectID --enable-for-all $AllowAllPipelineAccess --detect false"
        try {
            Write-Verbose $TaskDescriptor
            Invoke-Expression $cmd | Out-Null
            Write-Verbose "$TaskDescriptor - Ok"
        } catch {
            Write-Verbose "$TaskDescriptor - Failed"
            throw $_
        }
    }
    return $SubjectObj
}