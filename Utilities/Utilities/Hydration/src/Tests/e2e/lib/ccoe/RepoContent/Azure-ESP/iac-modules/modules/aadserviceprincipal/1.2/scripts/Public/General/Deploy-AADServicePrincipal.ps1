#
# Deploy-AADServicePrincipal
#
Function Deploy-AADServicePrincipal {
    [cmdletbinding()]
    param (
        [parameter(mandatory)]
        [String]
        $ParametersFilePath
    )

    $TaskDescriptor = "Deploy-AADServicePrincipal"

    #region read and validate parameters
    Write-Output "$TaskDescriptor - Read parameters from '$ParametersFilePath'"
    if (-not (Test-Path -Path $ParametersFilePath)) {
        Throw "$TaskDescriptor - Path '$ParametersFilePath' not found"
    }
    try {
        $servicePrincipalParams = Get-Content -Raw -Path $ParametersFilePath | ConvertFrom-Json
        Write-Output "$TaskDescriptor - File '$ParametersFilePath' read"
    }
    catch {
        Write-Error "$TaskDescriptor - The JSON file is not valid"
    }

    #parameter: aadServicePrincipalName
    $spName = $servicePrincipalParams.Name
    if ([String]::IsNullOrEmpty($spName)) {
        Throw "Mandatory parameter 'Name' not found"
    }
    Write-Output "$TaskDescriptor - Parameter 'Name' set with value '$spName'"

    #parameter: rotatePassword
    $spRotatePassword = $servicePrincipalParams.rotatePassword
    if ([String]::IsNullOrEmpty($spRotatePassword)) {
        $spRotatePassword = $false # default value
        Write-Output "$TaskDescriptor - Parameter 'rotatePassword' set with default value '$spRotatePassword'"
    }
    else {
        $spRotatePassword = [bool]::Parse($spRotatePassword )
        Write-Output "$TaskDescriptor - Parameter 'rotatePassword' set with value '$spRotatePassword'"
    }

    #parameter: outputVarNameEncrypted_ServicePrincipalPassword
    $outputVarNameEncrypted_ServicePrincipalPassword = $servicePrincipalParams.outputVarNameEncrypted_ServicePrincipalPassword
    if ([String]::IsNullOrEmpty($outputVarNameEncrypted_ServicePrincipalPassword)) {
        $outputVarNameEncrypted_ServicePrincipalPassword = "$($spName)_ServicePrincipalPassword" # default value
        Write-Output "$TaskDescriptor - Parameter 'outputVarNameEncrypted_ServicePrincipalPassword' set with default value '$outputVarNameEncrypted_ServicePrincipalPassword'"
    }
    else {
        Write-Output "$TaskDescriptor - Parameter 'outputVarNameEncrypted_ServicePrincipalPassword' set with value '$outputVarNameEncrypted_ServicePrincipalPassword'"
    }

    #parameter: outputVarName_ApplicationId
    $outputVarName_ApplicationId = $servicePrincipalParams.outputVarName_ApplicationId
    if ([String]::IsNullOrEmpty($outputVarName_ApplicationId)) {
        $outputVarName_ApplicationId = "$($spName)_ApplicationId" # default value
        Write-Output "$TaskDescriptor - Parameter 'outputVarName_ApplicationId' set with default value '$outputVarName_ApplicationId'"
    }
    else {
        Write-Output "$TaskDescriptor - Parameter 'outputVarName_ApplicationId' set with value '$outputVarName_ApplicationId'"
    }

    #endregion

    #region Set Azure Active Directory Application (App Registration)
    Write-Output "$TaskDescriptor - Set Azure Active Directory Application with name '$spName'"
    $params = @{
        ApplicationName = $spName
    }
    Write-Output ($params | Out-String)
    $aadApp = Set-Application @params
    Write-Output "$TaskDescriptor - Set Azure Active Directory Application OK"
    Write-Output ($aadApp | Out-String)
    #endregion

    #region Set Azure Active Directory Service Principal (Enterprise Application)
    Write-Output "$TaskDescriptor - Set Azure Active Directory Service Principal with name '$spName'"
    $params = @{
        ServicePrincipalName = $spName
        ApplicationId        = $aadApp.ApplicationId
    }
    Write-Output ($params | Out-String)
    $aadSp = Set-ServicePrincipal @params
    Write-Output "$TaskDescriptor - Set Azure Active Directory Service Principal OK"
    Write-Output ($aadSp | Out-String)

    Write-Output "$TaskDescriptor - Set pipeline output with name '$outputVarName_ApplicationId' for Service Principal Application Id '$($aadApp.ApplicationId)'"
    Write-Host "##vso[task.setvariable variable=$outputVarName_ApplicationId;isOutput=true]$($aadApp.ApplicationId)"
    #The line above generates an azure devops pipeline secret variable. Secret variables can only be used in a YAML pipeline. For use in Script, pass the value of the secret variable to an env variable in the appropriate task. See: https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#secret-variables 
    Write-Output "$TaskDescriptor - Set pipeline output OK"
    #endregion

    #region Set Service Principal Password
    if ($spRotatePassword) {
        Write-Output "$TaskDescriptor - Set Password for Azure Active Directory Service Principal with name '$spName'"
        $params = @{
            ApplicationId  = $aadApp.ApplicationId
            ValidityMonths = 12
        }
        Write-Output ($params | Out-String)
        $aadSpSecret = Set-Password @params | ConvertFrom-SecureString -Key (1..16) #ConvertFrom-SecureString converts from System.Security.SecureString to String (not plain text). The string can be turned to System.Security.SecureString using the ConvertTo-SecureString command later
        Write-Output "$TaskDescriptor - Set Password for Azure Active Directory Service Principal OK"
        
        Write-Output "$TaskDescriptor - Set encrypted pipeline output with name '$outputVarNameEncrypted_ServicePrincipalPassword' for Service Principal password as Secure String"
        Write-Host "##vso[task.setvariable variable=$outputVarNameEncrypted_ServicePrincipalPassword;isOutput=true]$aadSpSecret"
        #The line above generates an azure devops pipeline secret variable. Secret variables can only be used in a YAML pipeline. For use in Script, pass the value of the secret variable to an env variable in the appropriate task. See: https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#secret-variables 
        Write-Output "$TaskDescriptor - Set encrypted pipeline output OK"

        # clear password credentials
        $keepNewest = 3
        Write-Output "$TaskDescriptor - Clear all Credentials except $keepNewest newest of type Password for Azure Active Directory Service Principal with name '$spName'"
        $params = @{
            ApplicationId = $aadApp.ApplicationId
            Type          = "Password"
            KeepNewest    = $keepNewest
        }
        Write-Output ($params | Out-String)
        Clear-Credentials @params
        Write-Output "$TaskDescriptor - Clear Credentials of type Password OK"
    }
    else {
        Write-Output "$TaskDescriptor - Set Password for Azure Active Directory Service Principal SKIPPED"
    }
    #endregion
    

    #region Set owners
    # Uses Microsoft Graph API
    # https://docs.microsoft.com/en-us/graph/api/serviceprincipal-list-owners
    # https://docs.microsoft.com/en-us/graph/api/serviceprincipal-post-owners
    # https://docs.microsoft.com/en-us/graph/api/serviceprincipal-delete-owners
    # $Token = Get-AzAccessToken -Resource "https://graph.microsoft.com/" -TenantID $(Get-AzContext).Tenant.Id

    # $DeclaredOwners = $servicePrincipalParams.owners
    # foreach ($DeclaredOwner in $DeclaredOwners) {
    #         
    # }
    #endregion
            
    #region add app permission
    # Uses Microsoft Graph API
    # https://docs.microsoft.com/en-us/graph/api/resources/requiredresourceaccess
    # https://docs.microsoft.com/en-us/graph/api/resources/resourceaccess
    $Token = Get-AzAccessToken -Resource "https://graph.microsoft.com/" -TenantID $(Get-AzContext).Tenant.Id
            
    $RequiredAccess = $servicePrincipalParams.ApplicationPermissions
    if ($null -eq $RequiredAccess) {
        $RequiredAccess = @()
    }
    # Declaratively set permissions that the app requires
    #https://docs.microsoft.com/en-us/graph/api/application-update
    $listOperations = @{
        Uri     = "https://graph.microsoft.com/v1.0/applications/$($aadApp.ObjectId)"
        Headers = @{
            Authorization  = "Bearer $($Token.Token)"
            'Content-Type' = 'application/json'
        }
        Body    = @{
            requiredResourceAccess = $RequiredAccess
        } | ConvertTo-Json -Depth 100
        Method  = 'PATCH'
    }
    try {
        Write-Output "$TaskDescriptor - Processing SPN: $spName - Declaring required app permissions"
        Invoke-RestMethod @listOperations -ErrorAction Stop -Verbose:$false | Out-Null
        Write-Output "$TaskDescriptor - Processing SPN: $spName - Declaring required app permissions - Done"
    }
    catch {
        Write-Output "$TaskDescriptor - Configure Permissions for Service Principal with name '$spName'. Declaring required app permissions - Failed"
        throw $_
    }
    #Get current application permission consents that the application has
    $listOperations = @{
        Uri     = "https://graph.microsoft.com/v1.0/servicePrincipals/$($aadSp.Id)/appRoleAssignments"
        Headers = @{
            Authorization  = "Bearer $($Token.Token)"
            'Content-Type' = 'application/json'
        }
        Method  = 'GET'
    }
    try {
        Write-Output "$TaskDescriptor - Configure Permissions for Service Principal with name '$spName'. Getting current app permissison consents"
        $currentAssignments = (Invoke-RestMethod @listOperations  -ErrorAction Stop -Verbose:$false).value
        Write-Output ($currentAssignments | Out-String)
        $currentAssignments | ForEach-Object {
            $listOperations = @{
                Uri     = "https://graph.microsoft.com/v1.0/servicePrincipals/$($Assignment.resourceId)"
                Headers = @{
                    Authorization  = "Bearer $($Token.Token)"
                    'Content-Type' = 'application/json'
                }
                Method  = 'GET'
            }
            try {
                $ResourceAppliction = (Invoke-RestMethod @listOperations -ErrorAction Stop -Verbose:$false)
                $roleInfo = ($ResourceAppliction.approles | where-object id -match $Assignment.appRoleId)
            }
            catch {
                throw $_
            }

            Write-Output "$TaskDescriptor - Configure Permissions for Service Principal with name '$spName'. $($_.resourceDisplayName) - $($_.appRoleId)"
        }
        Write-Output "$TaskDescriptor - Configure Permissions for Service Principal with name '$spName'. Getting current app permissison consents - Done"
    }
    catch {
        Write-Output "$TaskDescriptor - Configure Permissions for Service Principal with name '$spName'. Getting current app permissison consents - Failed"
        throw $_
    }

    foreach ($Assignment in $currentAssignments) {
        if ($Assignment.appRoleId -notin $RequiredAccess.resourceAccess.id) {
            $listOperations = @{
                Uri     = "https://graph.microsoft.com/v1.0/servicePrincipals/$($Assignment.resourceId)"
                Headers = @{
                    Authorization  = "Bearer $($Token.Token)"
                    'Content-Type' = 'application/json'
                }
                Method  = 'GET'
            }
            try {
                $ResourceAppliction = (Invoke-RestMethod @listOperations -ErrorAction Stop -Verbose:$false)
                $roleInfo = ($ResourceAppliction.approles | where-object id -match $Assignment.appRoleId)
            }
            catch {
                throw $_
            }




            Write-Output "$TaskDescriptor - Configure Permissions for Service Principal with name '$spName'. $($Assignment.resourceDisplayName) - ($($roleInfo.origin)) $($roleInfo.value) - Remove consent"
            #Get current consents that the application has
            $listOperations = @{
                Uri     = "https://graph.microsoft.com/v1.0/servicePrincipals/$($Assignment.resourceId)/appRoleAssignedTo/$($Assignment.id)"
                Headers = @{
                    Authorization  = "Bearer $($Token.Token)"
                    'Content-Type' = 'application/json'
                }
                Method  = 'DELETE'
            }
            try {
                Invoke-RestMethod @listOperations -ErrorAction Stop -Verbose:$false | Out-Null
            }
            catch {
                throw $_
            }
        }
        else {
            Write-Output "$TaskDescriptor - Configure Permissions for Service Principal with name '$spName'. $($Assignment.resourceDisplayName) - ($($roleInfo.origin)) $($roleInfo.value) - Keep consent"
        }
    } 
                
    #Consent to the permissions
    #$ResourceAppRef = ($RequiredAccess)[0]
    foreach ($ResourceAppRef in $RequiredAccess) {
        $ResourceApp = Get-AzADServicePrincipal -ApplicationId $ResourceAppRef.resourceAppId
        Write-Output "$TaskDescriptor - Configure Permissions for Service Principal with name '$spName'. Processing $($ResourceApp.DisplayName) - $($ResourceApp.ID)"
        #$ResourceAccess = ($ResourceAppRef.resourceAccess)[0]
        foreach ($ResourceAccess in $ResourceAppRef.resourceAccess) {
            if ($ResourceAccess.id -notin $currentAssignments.appRoleId) {

                $listOperations = @{
                    Uri     = "https://graph.microsoft.com/v1.0/servicePrincipals/$($ResourceApp.Id)"
                    Headers = @{
                        Authorization  = "Bearer $($Token.Token)"
                        'Content-Type' = 'application/json'
                    }
                    Method  = 'GET'
                }
                try {
                    $ResourceAppliction = (Invoke-RestMethod @listOperations -ErrorAction Stop -Verbose:$false)
                    $roleInfo = ($ResourceAppliction.approles | Where-Object id -match $ResourceAccess.id)
                }
                catch {
                    throw $_
                }


                $listOperations = @{
                    Uri     = "https://graph.microsoft.com/v1.0/servicePrincipals/$($ResourceApp.ID)/appRoleAssignedTo"
                    Headers = @{
                        Authorization  = "Bearer $($Token.Token)"
                        'Content-Type' = 'application/json'
                    }
                    Body    = @{
                        principalId = $aadSp.ID
                        resourceId  = $ResourceApp.ID
                        appRoleId   = $ResourceAccess.ID
                    } | ConvertTo-Json
                    Method  = 'POST'
                }
                try {
                    Write-Output "$TaskDescriptor - Configure Permissions for Service Principal with name '$spName'. Processing $($ResourceApp.DisplayName) - ($($roleInfo.origin)) $($roleInfo.value) - Consenting"
                    Invoke-RestMethod @listOperations -ErrorAction Stop -Verbose:$false | Out-Null
                    Write-Output "$TaskDescriptor - Configure Permissions for Service Principal with name '$spName'. Processing $($ResourceApp.DisplayName) - ($($roleInfo.origin)) $($roleInfo.value) - Consenting - Done"
                }
                catch {
                    Write-Output "$TaskDescriptor - Configure Permissions for Service Principal with name '$spName'. Processing $($ResourceApp.DisplayName) - ($($roleInfo.origin)) $($roleInfo.value) - Consenting - Failed"
                    throw $_
                }
            }
            else {
                Write-Output "$TaskDescriptor - Configure Permissions for Service Principal with name '$spName'. Processing $($ResourceApp.DisplayName) - ($($roleInfo.origin)) $($roleInfo.value) - Consent exists"
            }
        }
    }
    #endregion
    
}