function Set-ServicePrincipal {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Name of the Azure Active Directory Service Principal to set"
        )]
        [ValidateNotNullOrEmpty()]
        [string] $ServicePrincipalName,
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Id of the linked Azure Active Directory Application to set"
        )]
        [ValidateNotNullOrEmpty()]
        [string] $ApplicationId
    )

    $TaskDescriptor = "Set-ServicePrincipal"

    #get Service Principal
    Write-Verbose "$TaskDescriptor - Get Azure Active Directory Service Principal with name '$ServicePrincipalName'"
    $ServicePrincipal = Get-AzAdServicePrincipal -DisplayName $ServicePrincipalName
    if ($ServicePrincipal) {
        #update Service Principal
        if ($ServicePrincipal.ApplicationId -ne $ApplicationId) {
            Throw "$TaskDescriptor - Azure Active Directory Service Principal with name '$ServicePrincipalName' should be linked with Application Id '$ApplicationId'"
        }
        Write-Verbose "$TaskDescriptor - Azure Active Directory Service Principal with name '$ServicePrincipalName' already exists"
    }
    else {
        #create Service Principal
        Write-Verbose "$TaskDescriptor - Create Azure Active Directory Service Principal with name '$ServicePrincipalName' linked to Application with Id '$ApplicationId'"
        $params = @{
            DisplayName    = $ServicePrincipalName
            ApplicationId  = $ApplicationId
            SkipAssignment = $true
        }
        Write-Verbose ($params | Out-String)
        $ServicePrincipal = New-AzAdServicePrincipal @params
        Write-Verbose "$TaskDescriptor - Create Azure Active Directory Service Principal OK"
    }
    if ([String]::IsNullOrEmpty($ServicePrincipal)) {
        throw "$TaskDescriptor - Set Azure Active Directory Service Principal with name '$ServicePrincipalName' FAILED"
    }

    Write-Verbose ($ServicePrincipal | Out-String)
    return $ServicePrincipal
}