function Get-ADOSecurityNamespace {
    param(
        $Name
    )
    $TaskDescriptor = "Get Azure DevOps security namespaces"
    $NameSpaces = az devops security permission namespace list | ConvertFrom-Json
    return $NameSpaces | Where-Object name -match $Name
}