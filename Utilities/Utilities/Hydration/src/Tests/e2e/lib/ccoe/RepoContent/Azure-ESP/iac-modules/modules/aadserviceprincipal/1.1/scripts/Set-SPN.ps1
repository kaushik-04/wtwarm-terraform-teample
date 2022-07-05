#
# Set-SPN
#
Function Set-SPN {
    [cmdletbinding()]
    param (
        [parameter(mandatory)]
        [String]
        $ParametersFilePath
    )

    Write-Output "Set-SPN - $ParametersFilePath"

    if (Test-Path -Path $ParametersFilePath) {
        $File = Get-Item -Path $ParametersFilePath
        Write-Output "Processing file $($File.Name)"
        $JSON = $File | Get-Content -Raw
        
        try {
            $Json | Test-Json -ErrorAction Stop
            Write-Output "The JSON file is valid."
        } catch {
            Write-Error "The JSON file is not valid." -ErrorAction Stop
        }
        $SPNObject = $JSON | ConvertFrom-Json

        #region Set App Object
        $SPNName = $SPNObject.Name
        Write-Output "Processing SPN: $SPNName - App Registration Object"
        $App = Get-AzAdApplication -DisplayName $SPNName
        if ($App) {
            Write-Output "Processing SPN: $SPNName - App Registration Object - Already exists"
        } else {
            Write-Output "Processing SPN: $SPNName - App Registration Object - Creating"
            $App = New-AzAdApplication -DisplayName $SPNName -IdentifierUris "http://$SPNName" -HomePage "http://$SPNName"
            Write-Output "Processing SPN: $SPNName - App Registration Object - Creating - Successfull"
        }
        if ($App) {
            Write-Output "Processing SPN: $SPNName - App Registration Object - ID      - $($App.ObjectId)"
            Write-Output "Processing SPN: $SPNName - App Registration Application - ID - $($App.ApplicationId)"
        } else {
            throw "Processing SPN: $SPNName - App Registration Object - Creating/Getting - Failed"
        }
        #endregion

        #region Set App Object
        $SPN = Get-AzAdServicePrincipal -DisplayName $SPNName
        if ($SPN) {
            Write-Output "Processing SPN: $SPNName - Enterprise Application Object - Already exists"
        } else {
            Write-Output "Processing SPN: $SPNName - Enterprise Application Object - Creating SPN"
            $SPN = New-AzAdServicePrincipal -DisplayName $SPNName -ApplicationId $App.ApplicationId -SkipAssignment
            Write-Output "Processing SPN: $SPNName - Enterprise Application Object - Creating SPN - Successfull"
        }
        if ($SPN) {
            Write-Output "Processing SPN: $SPNName - Enterprise Application Object - ID - $($SPN.ID)"
        } else {
            throw "Processing SPN: $SPNName - Enterprise Application Object - Creating/Getting SPN - Failed"
        }
        #endregion

        #region Set owners
        # Uses Microsoft Graph API
        # https://docs.microsoft.com/en-us/graph/api/serviceprincipal-list-owners
        # https://docs.microsoft.com/en-us/graph/api/serviceprincipal-post-owners
        # https://docs.microsoft.com/en-us/graph/api/serviceprincipal-delete-owners
        # $Token = Get-AzAccessToken -Resource "https://graph.microsoft.com/" -TenantID $(Get-AzContext).Tenant.Id

        # $DeclaredOwners = $SPNObject.owners
        # foreach ($DeclaredOwner in $DeclaredOwners) {
        #         
        # }
        #endregion
            
        #region add app permission
        # Uses Microsoft Graph API
        # https://docs.microsoft.com/en-us/graph/api/resources/requiredresourceaccess
        # https://docs.microsoft.com/en-us/graph/api/resources/resourceaccess
        $Token = Get-AzAccessToken -Resource "https://graph.microsoft.com/" -TenantID $(Get-AzContext).Tenant.Id
            
        $RequiredAccess = $SPNObject.ApplicationPermissions
        if ($null -eq $RequiredAccess) {
            $RequiredAccess = @()
        }
        # Declaratively set permissions that the app requires
        #https://docs.microsoft.com/en-us/graph/api/application-update
        $listOperations = @{
            Uri     = "https://graph.microsoft.com/v1.0/applications/$($App.ObjectId)"
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
            Write-Output "Processing SPN: $SPNName - Declaring required app permissions"
            Invoke-RestMethod @listOperations -ErrorAction Stop -Verbose:$false | Out-Null
            Write-Output "Processing SPN: $SPNName - Declaring required app permissions - Done"
        } catch {
            Write-Output "Processing SPN: $SPNName - Declaring required app permissions - Failed"
            throw $_
        }
        #Get current application permission consents that the application has
        $listOperations = @{
            Uri     = "https://graph.microsoft.com/v1.0/servicePrincipals/$($SPN.Id)/appRoleAssignments"
            Headers = @{
                Authorization  = "Bearer $($Token.Token)"
                'Content-Type' = 'application/json'
            }
            Method  = 'GET'
        }
        try {
            Write-Output "Processing SPN: $SPNName - Getting current app permissison consents"
            $currentAssignments = (Invoke-RestMethod @listOperations  -ErrorAction Stop -Verbose:$false).value
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
                } catch {
                    throw $_
                }

                Write-Output "Processing SPN: $SPNName - $($_.resourceDisplayName) - $($_.appRoleId)"
            }
            Write-Output "Processing SPN: $SPNName - Getting current app permissison consents - Done"
        } catch {
            Write-Output "Processing SPN: $SPNName - Getting current app permissison consents - Failed"
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
                } catch {
                    throw $_
                }




                Write-Output "Processing SPN: $SPNName - $($Assignment.resourceDisplayName) - ($($roleInfo.origin)) $($roleInfo.value) - Remove consent"
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
                } catch {
                    throw $_
                }
            } else {
                Write-Output "Processing SPN: $SPNName - $($Assignment.resourceDisplayName) - ($($roleInfo.origin)) $($roleInfo.value) - Keep consent"
            }
        } 
                
        #Consent to the permissions
        #$ResourceAppRef = ($RequiredAccess)[0]
        foreach ($ResourceAppRef in $RequiredAccess) {
            $ResourceApp = Get-AzADServicePrincipal -ApplicationId $ResourceAppRef.resourceAppId
            Write-Output "Processing SPN: $SPNName - Processing $($ResourceApp.DisplayName) - $($ResourceApp.ID)"
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
                    } catch {
                        throw $_
                    }


                    $listOperations = @{
                        Uri     = "https://graph.microsoft.com/v1.0/servicePrincipals/$($ResourceApp.ID)/appRoleAssignedTo"
                        Headers = @{
                            Authorization  = "Bearer $($Token.Token)"
                            'Content-Type' = 'application/json'
                        }
                        Body    = @{
                            principalId = $SPN.ID
                            resourceId  = $ResourceApp.ID
                            appRoleId   = $ResourceAccess.ID
                        } | ConvertTo-Json
                        Method  = 'POST'
                    }
                    try {
                        Write-Output "Processing SPN: $SPNName - Processing $($ResourceApp.DisplayName) - ($($roleInfo.origin)) $($roleInfo.value) - Consenting"
                        Invoke-RestMethod @listOperations -ErrorAction Stop -Verbose:$false | Out-Null
                        Write-Output "Processing SPN: $SPNName - Processing $($ResourceApp.DisplayName) - ($($roleInfo.origin)) $($roleInfo.value) - Consenting - Done"
                    } catch {
                        Write-Output "Processing SPN: $SPNName - Processing $($ResourceApp.DisplayName) - ($($roleInfo.origin)) $($roleInfo.value) - Consenting - Failed"
                        throw $_
                    }
                } else {
                    Write-Output "Processing SPN: $SPNName - Processing $($ResourceApp.DisplayName) - ($($roleInfo.origin)) $($roleInfo.value) - Consent exists"
                }
            }
        }
        #endregion
    } else {
        throw "Set-SPN - $ParametersFilePath - File does not exist"
    }
}