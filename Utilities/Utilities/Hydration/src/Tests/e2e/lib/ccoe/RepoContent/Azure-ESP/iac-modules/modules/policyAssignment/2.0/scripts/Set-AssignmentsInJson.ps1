function Set-AssignmentsInJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject
    )

    Write-Output "======================================================================================================================="
    Write-Output "Processing the scope of ""$($InputObject.scope.value)"" ($($InputObject.properties.value.policyAssignment.displayName))"
    Write-Output "======================================================================================================================="

    $AssignmentInJson = $InputObject.properties.value.policyAssignment

    Write-Output "    Fetching existing assignments from Azure..."
    $AssignmentsInAzure = Get-AzPolicyAssignment -Scope $InputObject.scope.value -WarningAction SilentlyContinue | Where-Object { $_.Properties.scope -eq $InputObject.scope.value }
    Write-Output "    Number of current assignments in Azure in this scope: $($AssignmentsInAzure.Count)"
    Write-Output "    Number of current assignments in JSON in this scope: $($AssignmentInJson.Count)"
    Write-Output ""
    Write-Output ""

    # Fetching policy definitons for the given scope, if it has any assignments defined
    if ($AssignmentInJson) {
        Write-Output "    Fetching policy/initiative definitions for this scope..."
        if ($InputObject.scope.value -like "*managementGroups*") {
            $ManagementGroupName = ($InputObject.scope.value -split "/")[-1]
            $DefinitionsInScope = Get-AzPolicyDefinition -ManagementGroupName $ManagementGroupName
            $DefinitionsInScope += Get-AzPolicySetDefinition -ManagementGroupName $ManagementGroupName
        }
        elseif ($InputObject.scope.value -like "*subscriptions*") {
            $SubscriptionId = ($InputObject.scope.value -split "/")[-1]
            $DefinitionsInScope = Get-AzPolicyDefinition -SubscriptionId $SubscriptionId
            $DefinitionsInScope += Get-AzPolicySetDefinition -SubscriptionId $SubscriptionId
        }
    }
        
    $ParametersInJson = $AssignmentInJson.parameters
    $ParameterNamesInJson = $null
    if ($ParametersInJson) {
        $ParameterNamesInJson = ($ParametersInJson | Get-Member -MemberType NoteProperty).Name
    }

    ## Create name based on displayname
    $AssignmentDisplayName = $AssignmentInJson.displayName
    $stream = [IO.MemoryStream]::new([byte[]][char[]]$AssignmentDisplayName)
    $AssignmentName = (Get-FileHash -InputStream $stream -Algorithm SHA256).hash.substring(0,24)

    Write-Output "    ___________________________________________________________________________________________________________________"
    $AssignmentId = $InputObject.scope.value + "/providers/Microsoft.Authorization/policyAssignments/" + $AssignmentName

    # Getting the definition is required not just for new assignments, but also for existing ones, in case there are roleDefinitionIds defined
    Write-Output "    Fetching definition from Azure: $($AssignmentInJson.definitionId)"
    # $Definition = Get-AzPolicyDefinition -Id $AssignmentInJson.definitionId -WarningAction SilentlyContinue
    $Definition = $DefinitionsInScope | Where-Object { $_.ResourceId -eq $AssignmentInJson.definitionId } -WarningAction SilentlyContinue

    $DefinitionsInInitative = $null
    if ($Definition.ResourceType -eq 'Microsoft.Authorization/policySetDefinitions') {
        $DefinitionsInInitative = $Definition.Properties.policyDefinitions
        Write-Output "    This is a policy set (initiative) definition, containing $($DefinitionsInInitative.policyDefinitionId.Count) policy definitions."
        # $DefinitionsInInitative.policyDefinitionId
    }

    #region CREATION scenario
    if ($AssignmentsInAzure.Name -notcontains $AssignmentName) {
        Write-Output "    New assignment"


        $AssignmentConfig = @{
            Name            = $AssignmentName
            DisplayName     = $AssignmentInJson.displayName
            EnforcementMode = $AssignmentInJson.enforcementMode
            Scope           = $InputObject.scope.value
        }

        # New-AzPolicyAssignment requires different parameter for creating an assignment for Policy (-PolicyDefinition) or Initiative (-PolicySetDefinition)
        if ($Definition.ResourceType -eq 'Microsoft.Authorization/policySetDefinitions') {
            $AssignmentConfig.Add('PolicySetDefinition', $Definition)
        }
        else {
            $AssignmentConfig.Add('PolicyDefinition', $Definition)
        }

        # add parameters
        if (-not ('' -eq $ParametersInJson -or $null -eq $ParametersInJson)) {
            $PolicyParameterObject = $ParametersInJson | ConvertTo-Hashtable
            $AssignmentConfig.Add('PolicyParameterObject', $PolicyParameterObject)
        }

        if ($AssignmentInJson.notScopes) { $AssignmentConfig.Add('NotScope', $AssignmentInJson.notScopes) }
        if ($AssignmentInJson.description) { $AssignmentConfig.Add('Description', $AssignmentInJson.description) }
        if ($AssignmentInJson.managedIdentity.assignIdentity -eq $true) {
            if ($AssignmentInJson.managedIdentity.location) {
                $AssignmentConfig.Add('AssignIdentity', $true)
                $AssignmentConfig.Add('Location', $AssignmentInJson.managedIdentity.location)
            }
            else {
                Write-Error "The managed identity won't be created for the assignment ""$AssignmentId"" without having the 'location' value defined. Provide the 'location' value for the managed identity, or set the value of the 'assignIdentity' property to false, in case you don't want to have a managed identity created." -ErrorAction Stop
            }
        }

        # add metadata
        $Metadata = @{"assignedBy" = "$($Identity.DisplayName) (ObjectId: $($Identity.Id))" } | ConvertTo-Json
        $AssignmentConfig.Add('Metadata', $Metadata)

        # CREATE assignment
        Write-Output "    Creating assignment in Azure: $AssignmentId"
        $NewAssignment = New-AzPolicyAssignment @AssignmentConfig -WarningAction SilentlyContinue -InformationAction SilentlyContinue
        if ($NewAssignment) {
            Write-Output ""
            Write-Output "        Policy successfully assigned in Azure."
            $script:noOfAssignmentsCreated++

            # creating RBAC role assignments based on the policy definition
            if ($AssignmentInJson.managedIdentity.assignIdentity -eq $true -and $AssignmentInJson.managedIdentity.location) {
                $roleDefinitionIds = @()
                # fetching role definition IDs for RBAC
                if ($null -ne $DefinitionsInInitative) {
                    # if it's an initiative definition
                    foreach ($DefinitionInInitative in $DefinitionsInInitative) {
                        $Def = $DefinitionsInScope | Where-Object { $_.ResourceId -eq $DefinitionInInitative.policyDefinitionId } -WarningAction SilentlyContinue
                        # if the policy definition has roleDefinitionIds, add them to the array
                        if ($Def.Properties.policyRule.then.details.roleDefinitionIds) {
                            foreach ($RoleDefInDefinition in $Def.Properties.policyRule.then.details.roleDefinitionIds) {
                                if ($roleDefinitionIds -notcontains $RoleDefInDefinition) {
                                    $roleDefinitionIds += $RoleDefinDefinition
                                }
                            }
                        }
                    }
                }
                else {
                    # if it's a single policy definition
                    # if the policy definition has roleDefinitionIds, add them to the array
                    if ($Definition.Properties.policyRule.then.details.roleDefinitionIds) {
                        foreach ($RoleDefInDefinition in $Definition.Properties.policyRule.then.details.roleDefinitionIds) {
                            if ($roleDefinitionIds -notcontains $RoleDefInDefinition) {
                                $roleDefinitionIds += $RoleDefInDefinition
                            }
                        }
                    }
                }

                Write-Output "    RBAC role definitions used in policy/initative definition(s) in this assignement:"
                Write-Output "        There are $($roleDefinitionIds.Count) distinct RBAC role definitions attached to definition(s) in this assignement (in JSON)."

                # actually creating RBAC role assignments based on the policy definition
                if ($roleDefinitionIds.Count -gt 0) {
                    foreach ($roleDefinitionId in $roleDefinitionIds) {
                        $roleDefId = $roleDefinitionId.Split("/") | Select-Object -Last 1

                        while ($true) {
                            if (Get-AzADServicePrincipal -ObjectId $NewAssignment.Identity.PrincipalId -ErrorAction SilentlyContinue) {
                                Start-Sleep -Seconds 3
                                break
                            }
                        }

                        $ExistingRoleAssignment = $null
                        Write-Output "    Fetching RBAC role assignment (definitionId: $roleDefId) for the managed identity ($($NewAssignment.Identity.PrincipalId)) of this assignment..."
                        $ExistingRoleAssignment = Get-AzRoleAssignment -Scope $InputObject.scope.value -ObjectId $NewAssignment.Identity.PrincipalId -RoleDefinitionId $roleDefId -ErrorAction SilentlyContinue

                        if (-not $ExistingRoleAssignment) {
                            Write-Output "    Creating RBAC role assignment (definitionId:$roleDefId) for the managed identity ($($NewAssignment.Identity.PrincipalId)) of this assignment..."
                            $NewRoleAssignment = New-AzRoleAssignment -Scope $InputObject.scope.value -ObjectId $NewAssignment.Identity.PrincipalId -RoleDefinitionId $roleDefId -InformationAction SilentlyContinue
                            if ($NewRoleAssignment) {
                                $script:noOfRoleAssignmentsCreated++
                                Write-Output "        RBAC role assignments created."
                            }
                        }
                        else {
                            Write-Output "        This RBAC Role assignment is already configured."
                        }
                    }
                }
                else {
                    Write-Warning "This assignment has a managed service identity assigned, but there are no role definition IDs provided in the policy/initiative definition(s)."
                }
            }
        }
        else {
            Write-Error "Policy couldn't be assigned." -ErrorAction Stop
        }
    }
    #endregion CREATION scenario

    #region UPDATE scenario
    else {
        $AssignmentInAzure = $AssignmentsInAzure | Where-Object { $_.Name -eq $AssignmentName }
        Write-Output "    Assignment already exists: $($AssignmentInAzure.ResourceId)"
        Write-Output "    Comparing attributes..."

        # check if Assignment parameters in Azure are equal to ParamsInJson
        # compare parameters
        $ParametersInAzure = $null
        $ParametersInAzure = $AssignmentInAzure.Properties.parameters
        $ParameterNamesInAzure = $null
        if ($ParametersInAzure) {
            $ParameterNamesInAzure = ($ParametersInAzure | Get-Member -MemberType NoteProperty).Name
        }

        # no parameters in JSON, parameters required by Assignment
        if (('' -eq $ParametersInJson -or $null -eq $ParametersInJson) -and $ParameterNamesInAzure) {
            # go with the default value in the assignment, if it has any, otherwise go with empty values
            Write-Output "    There are no parameters in the assignments JSON, but some parameters are required by Assignment: ""$($ParameterNamesInAzure -join '"; "')""" -ErrorAction Stop
            $parametersMatch = $false
        }
        # no parameters in JSON, no parameters in Azure
        elseif (('' -eq $ParametersInJson -or $null -eq $ParametersInJson) -and -not $ParameterNamesInAzure) {
            Write-Output "    There are no parameters in the assignments JSON, but no parameters are required by Assignment."
            $parametersMatch = $true
        }
        # parameters are defined in JSON (check if they are equal, to parameters in Azure)
        else {
            $parametersMatch = $true
            # check value in json and compare to azure
            foreach ($ParamName in $ParameterNamesInJson) {
                # parameter exists in JSON but it doesn't exist in the Azure assignment
                if ($null -eq $ParametersInAzure.$ParamName.value -or '' -eq $ParametersInAzure.$ParamName.value) {
                    $parametersMatch = $false
                    Write-Output "    The parameter ""$ParamName"" exists in JSON but it doesn't exist in the Azure assignment - adding the parameter to the assignment."
                }
                # parameter exists in JSON but is different from the one in the Azure assignment
                else {
                    if ($ParametersInJson.$ParamName -is [array]) {
                        If ( Compare-Object -ReferenceObject $ParametersInJson.$ParamName -DifferenceObject $ParametersInAzure.$ParamName.value ) {
                            $parametersMatch = $false
                            Write-Output "    The ""$ParamName"" parameter exists in JSON but has a different value from the one in the Azure assignment - changing the value in the assignment."

                        }
                    }
                    elseif ($ParametersInJson.$ParamName -is [PsCustomObject]) {
                        if (-not (Compare-ParameterObjects $ParametersInJson.$ParamName $ParametersInAzure.$ParamName.value)) {
                            $parametersMatch = $false
                            Write-Output "    The ""$ParamName"" parameter exists in JSON but has a different value from the one in the Azure assignment - changing the value in the assignment."
                        }
                    }
                    elseif ($ParametersInJson.$ParamName.GetType().Name -eq 'DateTime') {
                        if ($ParametersInJson.$ParamName.ToString("o") -ne $ParametersInAzure.$ParamName.value) {
                            $parametersMatch = $false
                            Write-Output "    The ""$ParamName"" parameter exists in JSON but has a different value from the one in the Azure assignment - changing the value in the assignment."
                        }
                    }
                    else {
                        if (-not (($ParametersInJson.$ParamName) -eq ($ParametersInAzure.$ParamName.value))) {
                            $parametersMatch = $false
                            Write-Output "    The ""$ParamName"" parameter exists in JSON but has a different value from the one in the Azure assignment - changing the value in the assignment."
                        }
                    }
                }
            }
            # if params in JSONassignment match AzureAssigmentParameters, check if JSONassignment is missing some AzureAssignmentParameters
            if ($parametersMatch -eq $true) {
                foreach ($ParamName in $ParameterNamesInAzure) {
                    # check if azure param is present in json
                    if (('' -eq $ParametersInJson.$ParamName -or $null -eq $ParametersInJson.$ParamName)) {
                        $parametersMatch = $false
                        Write-Output "    The parameter ""$ParamName"" is in Azure assignment, but not in defined in JSON - removing the parameter from the assignemnt will only work if it has a default value in the definition."
                    }
                }
            }
        }

        #if match is false create policyparamobject  from JSON params
        if ($parametersMatch -eq $false) {
            $PolicyParameterObject = @{ }

            if (-not ('' -eq $ParametersInJson -or $null -eq $ParametersInJson)) {
                $PolicyParameterObject = $ParametersInJson | ConvertTo-Hashtable
            }
        } # end policyparamobject creation


        #region compare basic attributes
        $displayNameMatches = $AssignmentInAzure.Properties.displayName -eq $AssignmentInJson.displayName
        $enforcementModeMatches = $AssignmentInAzure.Properties.enforcementMode -eq $AssignmentInJson.enforcementMode
        # extra tricks are required, otherwise the description couldn't be removed once it was set
        $descriptionMatches = ($AssignmentInAzure.Properties.description -eq $AssignmentInJson.description) -or ($AssignmentInAzure.Properties.description -eq ' ' -and $null -eq $AssignmentInJson.description) -or ($AssignmentInAzure.Properties.description -eq ' ' -and '' -eq $AssignmentInJson.description)


        # compare notScopes
        if ($null -eq $AssignmentInAzure.Properties.notScopes -and '' -eq $AssignmentInJson.notScopes) {
            $notScopesMatch = $true
        }
        elseif ($null -ne $AssignmentInAzure.Properties.notScopes -and '' -ne $AssignmentInJson.notScopes) {
            If ( Compare-Object -ReferenceObject $AssignmentInAzure.Properties.notScopes -DifferenceObject $AssignmentInJson.notScopes ) {
                $notScopesMatch = $false
            }
            else {
                $notScopesMatch = $true
            }
        }
        else {
            $notScopesMatch = $false
        }

        # compare assignedIdentity - (assignedIdentity removal not possible)
        $turnOnAssignedIdentity = $AssignmentInJson.managedIdentity.assignIdentity -eq $true
        if ($AssignmentInAzure.Identity) {
            $assignedIdentityEnabledOnAzure = $true
        }
        else {
            $assignedIdentityEnabledOnAzure = $false
        }
        $assignedIdentityMatches = $assignedIdentityEnabledOnAzure -eq $AssignmentInJson.managedIdentity.assignIdentity

        #endregion compare basic attributes

        #region update assignment of necessary
        if (-not $assignedIdentityMatches -and -not $turnOnAssignedIdentity) {
            Write-Error "It's not possible to remove managed Identity, once it was created for the assignment. To remove the managed identity, you need to delete and recreate this assignment." -ErrorAction Stop
        }
        elseif ($assignedIdentityEnabledOnAzure -and $AssignmentInJson.managedIdentity.location -ne $AssignmentInAzure.Location) {
            Write-Error "You can't change the location of the already existing managed identity of the assignment ""$AssignmentId"". To change the location of the assignment, you need to delete and recreate this assignment." -ErrorAction Stop
        }
        elseif ( $turnOnAssignedIdentity -and -not $AssignmentInJson.managedIdentity.location ) {
            Write-Error "The managed identity won't be created for the assignment ""$AssignmentId"" without having the 'location' value defined. Provide the 'location' value for the managed identity, or set the value of the 'assignIdentity' property to false, in case you don't want to have a managed identity created." -ErrorAction Stop
        }
        elseif ( $displayNameMatches -and $descriptionMatches -and $parametersMatch -and $notScopesMatch -and $enforcementModeMatches -and $assignedIdentityMatches) {
            Write-Output "        No changes are required in the policy/initative assignment."
        }
        # updates are necessary
        else {
            Write-Output "    The assignments JSON file does not match the assignment in Azure."
            Write-Output "        Updating the following value(s):"
            Write-Output "         - displayName :        $(-not $displayNameMatches)"
            Write-Output "         - description :        $(-not $descriptionMatches)"
            Write-Output "         - parameters :         $(-not $parametersMatch)"
            Write-Output "         - notScopes :          $(-not $notScopesMatch)"
            Write-Output "         - enforcementMode :    $(-not $enforcementModeMatches)"
            Write-Output "         - assignedIdentity :   $(-not $assignedIdentityMatches)"
            Write-Output "        Updating assignment..."


            $AssignmentConfig = @{
                Id              = $AssignmentId
                DisplayName     = $AssignmentInJson.displayName
                EnforcementMode = $AssignmentInJson.enforcementMode
            }
            # add parameters if they don't match
            if (-not $parametersMatch) {
                $AssignmentConfig.Add('PolicyParameterObject', $PolicyParameterObject)
            }

            # add notScopes
            if ($AssignmentInJson.notScopes) { $AssignmentConfig.Add('NotScope', $AssignmentInJson.notScopes) }

            # add description
            if ($AssignmentInJson.description) { $AssignmentConfig.Add('Description', $AssignmentInJson.description) }
            else {
                $AssignmentConfig.Add('Description', ' ')
            }
            if ($AssignmentInJson.assignIdentity -eq $true -and $AssignmentInJson.location) {
                $AssignmentConfig.Add('AssignIdentity', $true)
                $AssignmentConfig.Add('Location', $AssignmentInJson.location)
            }

            # add metadata
            $Metadata = @{"assignedBy" = "$($Identity.DisplayName) (ObjectId: $($Identity.Id))" } | ConvertTo-Json
            $AssignmentConfig.Add('Metadata', $Metadata)

            # add managedIdentity
            if ($turnOnAssignedIdentity) {
                $AssignmentConfig.Add('AssignIdentity', $true)
                $AssignmentConfig.Add('Location', $AssignmentInJson.managedIdentity.location)
            }

            # UPDATE assignment
            $UpdatedAssignment = Set-AzPolicyAssignment @AssignmentConfig -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            if ($UpdatedAssignment) {
                Write-Output "    Assignment successfully updated."
                $script:noOfAssignmentsUpdated++
            }
            else {
                Write-Error "Policy couldn't be updated." -ErrorAction Stop
            }
        }
        #endregion update assignment of necessary

        #region RBAC continuous check
        # creating RBAC role assignments based on the policy definition
        if ($AssignmentInJson.managedIdentity.assignIdentity -eq $true -and $AssignmentInJson.managedIdentity.location) {
            $roleDefinitionIds = @()
            # fetching role definition IDs for RBAC
            if ($null -ne $DefinitionsInInitative) {
                # if it's an initiative definition

                foreach ($DefinitionInInitative in $DefinitionsInInitative) {
                    # $Def = Get-AzPolicyDefinition -Id $DefinitionInInitative.policyDefinitionId -WarningAction SilentlyContinue
                    $Def = $DefinitionsInScope | Where-Object { $_.ResourceId -eq $DefinitionInInitative.policyDefinitionId } -WarningAction SilentlyContinue
                    # if the policy definition has roleDefinitionIds, add them to the array
                    if ($Def.Properties.policyRule.then.details.roleDefinitionIds) {
                        foreach ($RoleDefInDefinition in $Def.Properties.policyRule.then.details.roleDefinitionIds) {
                            if ($roleDefinitionIds -notcontains $RoleDefInDefinition) {
                                $roleDefinitionIds += $RoleDefinDefinition
                            }
                        }
                    }
                }
            }
            else {
                # if it's a single policy definition
                # if the policy definition has roleDefinitionIds, add them to the array
                if ($Definition.Properties.policyRule.then.details.roleDefinitionIds) {
                    foreach ($RoleDefInDefinition in $Definition.Properties.policyRule.then.details.roleDefinitionIds) {
                        if ($roleDefinitionIds -notcontains $RoleDefInDefinition) {
                            $roleDefinitionIds += $RoleDefInDefinition
                        }
                    }
                }
            }

            Write-Output "    RBAC role definitions used in policy/initative definition(s) in this assignement:"
            Write-Output "        There are $($roleDefinitionIds.Count) distinct RBAC role definitions attached to definition(s) in this assignement (in JSON)."

            # actually creating RBAC role assignments based on the policy definition
            if ($roleDefinitionIds.Count -gt 0) {

                $ExistingRoleAssignments = $null
                $ExistingRoleAssignments = Get-AzRoleAssignment -Scope $InputObject.scope.value -ObjectId $AssignmentInAzure.Identity.PrincipalId -ErrorAction SilentlyContinue
                Write-Output "        There are $($ExistingRoleAssignments.Count) distinct RBAC role assignments on this scope, attached to definition(s) in this assignement (in Azure)."

                foreach ($roleDefinitionId in $roleDefinitionIds) {
                    $roleDefId = $roleDefinitionId.Split("/") | Select-Object -Last 1

                    while ($true) {
                        if (Get-AzADServicePrincipal -ObjectId $AssignmentInAzure.Identity.PrincipalId -ErrorAction SilentlyContinue) {
                            break
                        }
                    }

                    $ExistingRoleAssignment = $null
                    Write-Output "    Fetching RBAC role assignment (definitionId: $roleDefId) for the managed identity ($($AssignmentInAzure.Identity.PrincipalId)) of this assignment..."
                    $ExistingRoleAssignment = $ExistingRoleAssignments | Where-Object { $_.RoleDefinitionId -eq $roleDefId }

                    if (-not $ExistingRoleAssignment) {
                        Write-Output "        RBAC Role assignment doesn't exist."
                        Write-Output "        Creating RBAC role assignment (definitionId: $roleDefId) for the managed identity ($($AssignmentInAzure.Identity.PrincipalId)) of this assignment..."
                        $NewRoleAssignment = New-AzRoleAssignment -Scope $InputObject.scope.value -ObjectId $AssignmentInAzure.Identity.PrincipalId -RoleDefinitionId $roleDefId -InformationAction SilentlyContinue
                        if ($NewRoleAssignment) {
                            $script:noOfRoleAssignmentsChanged++
                            Write-Output "        RBAC role assignments changed (created)."
                        }
                    }
                    else {
                        Write-Output "        This RBAC Role assignment is already configured."

                        # removing RBAC role assignment from scope, in case it the roleDefinitionId has been removed from the policy definition
                        Write-Output "        Looking for any RBAC Role assignments to clean up..."

                        foreach ($RoleAssignment in $ExistingRoleAssignments) {
                            $roleDefIds = @()
                            foreach ($roleDefinitionId in $roleDefinitionIds) {
                                $roleDefIds += $roleDefinitionId.Split("/") | Select-Object -Last 1
                            }

                            if ($RoleAssignment.RoleDefinitionId -notin $roleDefIds) {
                                Write-Output "        Removing Role assignment (definitionId: $roleDefId) for the managed identity ($($AssignmentInAzure.Identity.PrincipalId))."
                                Remove-AzRoleAssignment -Scope $RoleAssignment.Scope -ObjectId $RoleAssignment.ObjectId -RoleDefinitionId $RoleAssignment.RoleDefinitionId
                                $script:noOfRoleAssignmentsRemoved++
                                Write-Output "        RBAC role assignments deleted."
                            }
                            else {
                                Write-Output "        There are no RBAC Role assignments to be removed."
                            }
                        }
                    }
                }

            }
            else {
                Write-Warning "This assignment has a managed service identity assigned, but there are no role definition IDs provided in the policy/initiative definition(s)."
            }
        }
        #endregion RBAC continuous check

    }
    #endregion UPDATE scenario
}
