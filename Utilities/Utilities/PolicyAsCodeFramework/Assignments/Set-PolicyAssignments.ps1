#Requires -PSEdition Core

<#
.SYNOPSIS
    This script creates/updates/deletes Policy and Policy Set (Initiative) assignments in management groups, subscriptions or resource groups, based on the provided assignment.json file.
.DESCRIPTION
    The script supports assigning policy definitions anywhere in the management group hierarchy, directly in the subscriptions or resource gruops.

    Tests whether a User/ServicePrincipal executing this script has the given RBAC role(s) assigned on the Management Group level or Subscription level.
    In case of RBAC roles assigned to AAD Groups, the function does not check nested AAD Groups, only direct Group members are considered
    Role Limitations: The code checks only the specific given RBAC role(s), and ignores whether higher role is assigned (Contributor, Owner, or custom role)
.PARAMETER AssignmentFilePath
    Path to the assignments JSON file.
.PARAMETER AssignmentSchemaPath
    Path to the assignments JSON schema.
.PARAMETER AadTenantFqdn
    FQDN of the AAD tenant, e.g. <your company>.onmicrosoft.com .  It is mandatory, if the script runs on behalf of a guest user.
.PARAMETER SkipRbacValidation
    When this switch is used, RBAC validation steps are skipped
.PARAMETER CheckRbacPermissionsForAllScopes
    When this switch is used, RBAC permissions are checked for all scopes. When not in use, only the root scope is checked.
.EXAMPLE
    .\Set-PolicyAssignments.ps1 -AssignmentFilePath './assignments.json' -AssignmentSchemaPath './assignmentSchema.json' -DeleteIfMarkedForDeletion -AadTenantFqdn company.onmicrosoft.com

    Configuring Policy and Initiative assignments based on the assignments.json, that is validated against the schema in assignmentSchema.json. Existing assignments that are not defined in assignments.json will be deleted.
.EXAMPLE
    .\Set-PolicyAssignments.ps1 -AssignmentFilePath './assignments.json' -AssignmentSchemaPath './assignmentSchema.json'

    Configuring Policy and Initiative assignments based on the assignments.json, that is validated against the schema in assignmentSchema.json. The script will show which existing assignments are not defined in assignments.json but will NOT delete them.
.EXAMPLE
    .\Set-PolicyAssignments.ps1 -AssignmentFilePath './assignments.json' -AssignmentSchemaPath './assignmentSchema.json' -SkipRbacValidation

    Configuring Policy and Initiative assignments based on the assignments.json, that is validated against the schema in assignmentSchema.json. RBAC validation is completely skipped.
.EXAMPLE
    .\Set-PolicyAssignments.ps1 -AssignmentFilePath './assignments.json' -AssignmentSchemaPath './assignmentSchema.json' -CheckRbacPermissionsForAllScopes

    Configuring Policy and Initiative assignments based on the assignments.json, that is validated against the schema in assignmentSchema.json. RBAC is validated recursively on all scopes defined in assignments.json.
.INPUTS
   <none>
.OUTPUTS
   <none>
.NOTES
    This script is designed to be run in Azure DevOps pipelines.
    Version:        1.0
    Creation Date:  2020-03-27
#>

param (

    [Parameter(Mandatory = $false,
        HelpMessage = "Path to the assignments JSON file.")]
    [string]$AssignmentFilePath = "./assignments.json",

    [Parameter(Mandatory = $false,
        HelpMessage = "Path to the assignments JSON schema.")]
    [string]$AssignmentSchemaPath = "./assignmentSchema.json",

    [Parameter(Mandatory = $false,
        HelpMessage = "When using this switch, the script deletes all policy and policy set (initiative) assignments from Azure that are not included in the assignment JSON.")]
    [switch]$DeleteIfMarkedForDeletion,

    [Parameter(Mandatory = $false,
        HelpMessage = "FQDN of the AAD tenant, e.g. <your company>.onmicrosoft.com . It is mandatory, if the script runs on behalf of a guest user.")]
    [string]$AadTenantFqdn = "company.onmicrosoft.com",

    [Parameter(Mandatory = $false,
        HelpMessage = "When this switch is used, RBAC validation steps are skipped")]
    [switch]$SkipRbacValidation,

    [Parameter(Mandatory = $false,
        HelpMessage = "When this switch is used, RBAC permissions are checked for all scopes. When not in use, only the root scope is checked.")]
    [switch]$CheckRbacPermissionsForAllScopes

)

# Initialize counters
$noOfAssignmentsCreated = 0
$noOfAssignmentsUpdated = 0
$noOfAssignmentsDeleted = 0
$noOfAssignmentsToDelete = 0

$noOfRoleAssignmentsCreated = 0
$noOfRoleAssignmentsChanged = 0
$noOfRoleAssignmentsRemoved = 0

$NumberOfScopes = 0



#region Functions

function  Test-GroupMembers
{
    param (
        [Parameter(Mandatory = $true)][string]$GroupId,
        [Parameter(Mandatory = $true)][string]$PrincipalId,
        [Parameter(Mandatory = $true)][boolean]$ScopeAuthorizationStatus
    )

    $groupMembers = Get-AzADGroupMember -GroupObjectId $GroupId
    if ($groupMembers.Id -contains $PrincipalId)
    {
        return $true
    }
    elseif ($groupIds = ($groupMembers | Where-Object { $_.ObjectType -eq "Group" }).Id)
    {

        foreach ($groupId in $groupIds)
        {

            Test-GroupMembers -GroupId $groupId -PrincipalId $PrincipalId

            if ($ScopeAuthorizationStatus -eq $true)
            {
                break
            }
        }

    }

}

function Get-Identity
{
    Write-Host ""
    Write-Host ""
    Write-Host "-------------------------------------------------------------------------------------------------------------------"
    Write-Host "Checking RBAC permissions"
    Write-Host "-------------------------------------------------------------------------------------------------------------------"

    Write-Host "    Getting the Object ID of the User / Service Principal..."

    $Context = Get-AzContext
    $Account = $Context.Account

    if ($Account.Type -eq "User")
    {
        # Standard user
        $Obj = Get-AzADUser -UserPrincipalName $Account.Id
        if ($Obj)
        {
            $ObjId = $Obj.Id
            Write-Host "    The script is running on behalf of this User (Object ID): $ObjId"
        }
        # Guest user
        else
        {
            $UPN = $Account.Id.Replace('@', '_') + "#EXT#@$AadTenantFqdn"
            $Obj = Get-AzADUser -UserPrincipalName $UPN
            $ObjId = $Obj.Id
            Write-Host "    The script is running on behalf of this guest User (Object ID): $ObjId"
        }

    }
    elseif ($Account.Type -eq "ServicePrincipal")
    {
        $Obj = Get-AzADServicePrincipal -ApplicationId $Account.Id
        $ObjId = $Obj.Id
        Write-Host "    The script is running on behalf of this Service Principal (Object ID): $ObjId"
    }
    else
    {
        Write-Host "Unknown/Unsupported type of the principal: $($Account.Type), aborting the script !" -ErrorAction Stop
    }


    return $Obj
}

function Test-RbacPermissions
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [boolean]$CheckRbacPermissionsForAllScopes,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Identity,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AssignmentsObject
    )

    Write-Output "    Checking the User/Service Principal authorization on the specified scopes..."

    #Initialize authorization status variable and required roles authorized to assign/modify Policies
    $ScopeAuthorizationStatus = $null

    $requiredRoleNames = @("Owner")

    if ($CheckRbacPermissionsForAllScopes -eq $true)
    {
        Write-Output "    Checking authorization on all scopes..."
        $Scopes = Get-Scopes -InputObject $AssignmentsObject.root
    }
    else
    {
        Write-Output "    Checking authorization on root scope only (inheritence applies)..."
        $Scopes = $AssignmentsObject.root.scope
    }

    foreach ($scope in $Scopes)
    {
        Write-Output "        Checking authorization on scope: $scope..."
        $roleAssignments = Get-AzRoleAssignment -Scope $scope -ErrorAction SilentlyContinue | Where-Object { $requiredRoleNames -contains $_.RoleDefinitionName }

        if (-not $roleAssignments)
        {
            Write-Warning "Unable to get Azure RBAC Role Assignments ! Check whether the Client with Object ID: $($Identity.Id) has permissions to read on the given scope and if a Service Principal is used, check whether it has assigned the AAD DIRECTORY READER role"
            Write-Output ""
        }

        $ScopeAuthorizationStatus = $false

        if ($roleAssignments.ObjectId -contains $Identity.Id)
        {
            $ScopeAuthorizationStatus = $true
        }
        elseif ($groupIds = ($roleAssignments | Where-Object { $_.ObjectType -eq "Group" }).ObjectId)
        {
            foreach ($groupId in $groupIds)
            {
                $ScopeAuthorizationStatus = Test-GroupMembers -GroupId $groupId -PrincipalId $Identity.Id -ScopeAuthorizationStatus $ScopeAuthorizationStatus

                if ($ScopeAuthorizationStatus -eq $true)
                {
                    break
                }
            }
        }

        # Abort the script execution in case one of the scopes did not pass authorization check
        if ($ScopeAuthorizationStatus -eq $false)
        {
            Write-Error "        The Client with Object ID: $($Identity.Id) is not assigned one of the required roles to change assignments on the given scope, aborting the script !" -ErrorAction Stop
            Write-Output ""
        }
    }

    # Report successful auhtorization check while all of the scopes passed
    Write-Output "    The Client with Object ID: $($Identity.Id) has been authorized"
}

function Compare-ParameterObjects
{

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$InputObject1,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$InputObject2
    )

    $areEqual = $true
    foreach ($property1 in $InputObject1.PSObject.Properties)
    {

        $key = $property1.Name
        $property2 = $InputObject2.PSObject.Properties.Item($key)

        if ($null -ne $property2)
        {
            if ($InputObject1.$key -is [array])
            {
                If ( Compare-Object -ReferenceObject $property1.Value -DifferenceObject $property2.value)
                {
                    return $false
                }
            }
            elseif ($property1.Value -is [PsCustomObject])
            {
                $areEqual = Compare-ParameterObjects $property1.value $property2.value
                if (-not ($areEqual))
                {
                    return $false
                }
            }
            elseif ($property1.Value.GetType().Name -eq 'DateTime')
            {
                Write-Output "COMPARING DATETIME Value in SuObject!!!"
                # ToString("o") converts DateTime format to string like "03/31/2020 21:51:19"
                if ($property1.Value.ToString("o") -ne $property2.value)
                {
                    return $false
                }
            }
            else
            {
                if (-not (($property1.Value) -eq ($property2.value)))
                {
                    return $false
                }
            }
        }
        else
        {
            return $false
        }
    }
    #check if there is an object in object2 that is missing in object1, then obj1 and obj2 are also different
    foreach ($property2 in $InputObject2.PSObject.Properties)
    {
        $key2 = $property2.Name
        $property1 = $InputObject1.PSObject.Properties.Item($key2)
        if ($null -eq $property1)
        {
            return $false
        }
    }
    return $areEqual
}

function Get-Scopes
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [PSCustomObject[]]$InputObject
    )

    begin
    {
        $Scopes = @()
    }

    process
    {
        foreach ($Item in $InputObject)
        {
            $Scopes += $Item.Scope

            # recursively going through all "child" scopes
            if ($Item.Children)
            {
                $Item.Children | Get-Scopes
            }
        }
    }
    end
    {
        return $Scopes
    }

}


function Test-AssignmentsJson
{
    param (
        [Parameter(Mandatory = $true)][PSCustomObject]$JsonRootScope
    )

    $script:NumberOfScopes++

    Write-Host "        Testing assignment scope $($script:NumberOfScopes): $($JsonRootScope.Scope)"

    ($JsonRootScope | ConvertTo-Json -Depth 100) | Test-Json -Schema $schema -ErrorAction Stop | Out-Null

    $uniqueAssignments = @()
    $AssignmentsInScope = $JsonRootScope.policyAssignments + $JsonRootScope.policySetAssignments
    foreach ($Item in $AssignmentsInScope)
    {
        if ($uniqueAssignments -notcontains $Item.name)
        {
            $uniqueAssignments += $Item.name
        }
        else
        {
            Write-Error "There is more than one policy assignment defined in the JSON in the ""$($JsonRootScope.Scope)"" scope with the name of ""$($Item.name)""." -ErrorAction Stop
        }
    }

    if ($JsonRootScope.children)
    {
        foreach ($JsonChildScope in $JsonRootScope.children)
        {
            Test-AssignmentsJson -JsonRootScope $JsonChildScope
        }
    }

}

function ConvertTo-Hashtable
{
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    process
    {
        if ($null -eq $InputObject) { return $null }
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject)
                {
                    ConvertTo-Hashtable $object
                }
            )
            $collection
        }
        elseif ($InputObject -is [psobject])
        {
            $hash = @{ }
            foreach ($property in $InputObject.PSObject.Properties)
            {
                # special treatment for arrays required. if they contain 0 or 1 element they are not treated as array objects anymore
                if ($property.value -is [array])
                {
                    $hash[$property.Name] = [array](ConvertTo-Hashtable $property.Value)
                }
                else
                {
                    $hash[$property.Name] = ConvertTo-Hashtable $property.Value
                }
            }
            $hash
        }
        else
        {
            $InputObject
        }
    }
}


function Set-AssignmentsInJson
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject
    )

    foreach ($Item in $InputObject)
    {

        Write-Output "======================================================================================================================="
        Write-Output "Processing the scope of ""$($Item.Scope)"" ($($Item.scopeDisplayName))"
        Write-Output "======================================================================================================================="

        $AssignmentsInJson = $Item.policyAssignments + $Item.policySetAssignments

        Write-Output "    Fetching existing assignments from Azure..."
        $AssignmentsInAzure = Get-AzPolicyAssignment -Scope $Item.Scope -WarningAction SilentlyContinue | Where-Object { $_.Properties.scope -eq $Item.Scope }
        Write-Output "    Number of current assignments in Azure in this scope: $($AssignmentsInAzure.Count)"
        Write-Output "    Number of current assignments in JSON in this scope: $($AssignmentsInJson.Count)"
        Write-Output ""
        Write-Output ""

        # Fetching policy definitons for the given scope, if it has any assignments defined
        if ($AssignmentsInJson)
        {
            Write-Output "    Fetching policy/initiative definitions for this scope..."
            if ($Item.Scope -like "*managementGroups*")
            {
                $ManagementGroupName = ($Item.Scope -split "/")[-1]
                $DefinitionsInScope = Get-AzPolicyDefinition -ManagementGroupName $ManagementGroupName
                $DefinitionsInScope += Get-AzPolicySetDefinition -ManagementGroupName $ManagementGroupName
            }
            elseif ($Item.Scope -like "*subscriptions*")
            {
                $SubscriptionId = ($Item.Scope -split "/")[2]
                $DefinitionsInScope = Get-AzPolicyDefinition -SubscriptionId $SubscriptionId
                $DefinitionsInScope += Get-AzPolicySetDefinition -SubscriptionId $SubscriptionId
            }
        }
        
        foreach ($AssignmentInJson in $AssignmentsInJson)
        {
            $ParametersInJson = $AssignmentInJson.parameters
            $ParameterNamesInJson = $null
            if ($ParametersInJson)
            {
                $ParameterNamesInJson = ($ParametersInJson | Get-Member -MemberType NoteProperty).Name
            }

            Write-Output "    ___________________________________________________________________________________________________________________"
            $AssignmentId = $Item.Scope + "/providers/Microsoft.Authorization/policyAssignments/" + $AssignmentInJson.name

            # Getting the definition is required not just for new assignments, but also for existing ones, in case there are roleDefinitionIds defined
            Write-Output "    Fetching definition from Azure: $($AssignmentInJson.definitionId)"
            # $Definition = Get-AzPolicyDefinition -Id $AssignmentInJson.definitionId -WarningAction SilentlyContinue
            $Definition = $DefinitionsInScope | Where-Object {$_.ResourceId -eq $AssignmentInJson.definitionId} -WarningAction SilentlyContinue

            $DefinitionsInInitative = $null
            if ($Definition.ResourceType -eq 'Microsoft.Authorization/policySetDefinitions')
            {
                $DefinitionsInInitative = $Definition.Properties.policyDefinitions
                Write-Output "    This is a policy set (initiative) definition, containing $($DefinitionsInInitative.policyDefinitionId.Count) policy definitions."
                # $DefinitionsInInitative.policyDefinitionId
            }

            #region CREATION scenario
            if ($AssignmentsInAzure.Name -notcontains $AssignmentInJson.name)
            {
                Write-Output "    New assignment"


                $AssignmentConfig = @{
                    Name             = $AssignmentInJson.name
                    DisplayName      = $AssignmentInJson.displayName
                    EnforcementMode  = $AssignmentInJson.enforcementMode
                    Scope            = $Item.Scope
                }

                # New-AzPolicyAssignment requires different parameter for creating an assignment for Policy (-PolicyDefinition) or Initiative (-PolicySetDefinition)
                if ($Definition.ResourceType -eq 'Microsoft.Authorization/policySetDefinitions')
                {
                    $AssignmentConfig.Add('PolicySetDefinition', $Definition)
                }
                else
                {
                    $AssignmentConfig.Add('PolicyDefinition', $Definition)
                }

                # add parameters
                if (-not ('' -eq $ParametersInJson -or $null -eq $ParametersInJson))
                {
                    $PolicyParameterObject = $ParametersInJson | ConvertTo-Hashtable
                    $AssignmentConfig.Add('PolicyParameterObject', $PolicyParameterObject)
                }

                if ($AssignmentInJson.notScopes) { $AssignmentConfig.Add('NotScope', $AssignmentInJson.notScopes) }
                if ($AssignmentInJson.description) { $AssignmentConfig.Add('Description', $AssignmentInJson.description) }
                if ($AssignmentInJson.managedIdentity.assignIdentity -eq $true)
                {
                    if ($AssignmentInJson.managedIdentity.location)
                    {
                        $AssignmentConfig.Add('AssignIdentity', $true)
                        $AssignmentConfig.Add('Location', $AssignmentInJson.managedIdentity.location)
                    }
                    else
                    {
                        Write-Error "The managed identity won't be created for the assignment ""$AssignmentId"" without having the 'location' value defined. Provide the 'location' value for the managed identity, or set the value of the 'assignIdentity' property to false, in case you don't want to have a managed identity created." -ErrorAction Stop
                    }
                }

                # add metadata
                $Metadata = @{"assignedBy" = "$($Identity.DisplayName) (ObjectId: $($Identity.Id))" } | ConvertTo-Json
                $AssignmentConfig.Add('Metadata', $Metadata)

                # CREATE assignment
                Write-Output "    Creating assignment in Azure: $AssignmentId"
                $NewAssignment = New-AzPolicyAssignment @AssignmentConfig -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                if ($NewAssignment)
                {
                    Write-Output ""
                    Write-Output "        Policy successfully assigned in Azure."
                    $script:noOfAssignmentsCreated++

                    # creating RBAC role assignments based on the policy definition
                    if ($AssignmentInJson.managedIdentity.assignIdentity -eq $true -and $AssignmentInJson.managedIdentity.location)
                    {
                        $roleDefinitionIds = @()
                        # fetching role definition IDs for RBAC
                        if ($null -ne $DefinitionsInInitative) # if it's an initiative definition
                        {
                            foreach ($DefinitionInInitative in $DefinitionsInInitative)
                            {
                                $Def = $DefinitionsInScope | Where-Object {$_.ResourceId -eq $DefinitionInInitative.policyDefinitionId} -WarningAction SilentlyContinue
                                # if the policy definition has roleDefinitionIds, add them to the array
                                if ($Def.Properties.policyRule.then.details.roleDefinitionIds)
                                {
                                    foreach ($RoleDefInDefinition in $Def.Properties.policyRule.then.details.roleDefinitionIds)
                                    {
                                        if ($roleDefinitionIds -notcontains $RoleDefInDefinition)
                                        {
                                            $roleDefinitionIds += $RoleDefinDefinition
                                        }
                                    }
                                }
                            }
                        }
                        else # if it's a single policy definition
                        {
                            # if the policy definition has roleDefinitionIds, add them to the array
                            if ($Definition.Properties.policyRule.then.details.roleDefinitionIds)
                            {
                                foreach ($RoleDefInDefinition in $Definition.Properties.policyRule.then.details.roleDefinitionIds)
                                {
                                    if ($roleDefinitionIds -notcontains $RoleDefInDefinition)
                                    {
                                        $roleDefinitionIds += $RoleDefInDefinition
                                    }
                                }
                            }
                        }

                        Write-Output "    RBAC role definitions used in policy/initative definition(s) in this assignement:"
                        Write-Output "        There are $($roleDefinitionIds.Count) distinct RBAC role definitions attached to definition(s) in this assignement (in JSON)."

                        # actually creating RBAC role assignments based on the policy definition
                        if ($roleDefinitionIds.Count -gt 0)
                        {
                            foreach ($roleDefinitionId in $roleDefinitionIds)
                            {
                                $roleDefId = $roleDefinitionId.Split("/") | Select-Object -Last 1

                                while ($true)
                                {
                                    if (Get-AzADServicePrincipal -ObjectId $NewAssignment.Identity.PrincipalId -ErrorAction SilentlyContinue)
                                    {
                                        Start-Sleep -Seconds 3
                                        break
                                    }
                                }

                                $ExistingRoleAssignment = $null
                                Write-Output "    Fetching RBAC role assignment (definitionId: $roleDefId) for the managed identity ($($NewAssignment.Identity.PrincipalId)) of this assignment..."
                                $ExistingRoleAssignment = Get-AzRoleAssignment -Scope $Item.Scope -ObjectId $NewAssignment.Identity.PrincipalId -RoleDefinitionId $roleDefId -ErrorAction SilentlyContinue

                                if (-not $ExistingRoleAssignment)
                                {
                                    Write-Output "    Creating RBAC role assignment (definitionId:$roleDefId) for the managed identity ($($NewAssignment.Identity.PrincipalId)) of this assignment..."
                                    $NewRoleAssignment = New-AzRoleAssignment -Scope $Item.Scope -ObjectId $NewAssignment.Identity.PrincipalId -RoleDefinitionId $roleDefId -InformationAction SilentlyContinue
                                    if ($NewRoleAssignment)
                                    {
                                        $script:noOfRoleAssignmentsCreated++
                                        Write-Output "        RBAC role assignments created."
                                    }
                                }
                                else
                                {
                                    Write-Output "        This RBAC Role assignment is already configured."
                                }
                            }
                        }
                        else
                        {
                            Write-Warning "This assignment has a managed service identity assigned, but there are no role definition IDs provided in the policy/initiative definition(s)."
                        }
                    }
                }
                else
                {
                    Write-Error "Policy couldn't be assigned." -ErrorAction Stop
                }
            }
            #endregion CREATION scenario

            #region UPDATE scenario
            else
            {
                $AssignmentInAzure = $AssignmentsInAzure | Where-Object { $_.Name -eq $AssignmentInJson.name }
                Write-Output "    Assignment already exists: $($AssignmentInAzure.ResourceId)"
                Write-Output "    Comparing attributes..."

                # check if Assignment parameters in Azure are equal to ParamsInJson
                # compare parameters
                $ParametersInAzure = $null
                $ParametersInAzure = $AssignmentInAzure.Properties.parameters
                $ParameterNamesInAzure = $null
                if ($ParametersInAzure)
                {
                    $ParameterNamesInAzure = ($ParametersInAzure | Get-Member -MemberType NoteProperty).Name
                }

                # no parameters in JSON, parameters required by Assignment
                if (('' -eq $ParametersInJson -or $null -eq $ParametersInJson) -and $ParameterNamesInAzure)
                {
                    # go with the default value in the assignment, if it has any, otherwise go with empty values
                    Write-Output "    There are no parameters in the assignments JSON, but some parameters are required by Assignment: ""$($ParameterNamesInAzure -join '"; "')""" -ErrorAction Stop
                    $parametersMatch = $false
                }
                # no parameters in JSON, no parameters in Azure
                elseif (('' -eq $ParametersInJson -or $null -eq $ParametersInJson) -and -not $ParameterNamesInAzure)
                {
                    Write-Output "    There are no parameters in the assignments JSON, but no parameters are required by Assignment."
                    $parametersMatch = $true
                }
                # parameters are defined in JSON (check if they are equal, to parameters in Azure)
                else
                {
                    $parametersMatch = $true
                    # check value in json and compare to azure
                    foreach ($ParamName in $ParameterNamesInJson)
                    {
                        # parameter exists in JSON but it doesn't exist in the Azure assignment
                        if ($null -eq $ParametersInAzure.$ParamName.value -or '' -eq $ParametersInAzure.$ParamName.value)
                        {
                            $parametersMatch = $false
                            Write-Output "    The parameter ""$ParamName"" exists in JSON but it doesn't exist in the Azure assignment - adding the parameter to the assignment."
                        }
                        # parameter exists in JSON but is different from the one in the Azure assignment
                        else
                        {
                            if ($ParametersInJson.$ParamName -is [array])
                            {
                                If ( Compare-Object -ReferenceObject $ParametersInJson.$ParamName -DifferenceObject $ParametersInAzure.$ParamName.value )
                                {
                                    $parametersMatch = $false
                                    Write-Output "    The ""$ParamName"" parameter exists in JSON but has a different value from the one in the Azure assignment - changing the value in the assignment."

                                }
                            }
                            elseif ($ParametersInJson.$ParamName -is [PsCustomObject])
                            {
                                if (-not (Compare-ParameterObjects $ParametersInJson.$ParamName $ParametersInAzure.$ParamName.value))
                                {
                                    $parametersMatch = $false
                                    Write-Output "    The ""$ParamName"" parameter exists in JSON but has a different value from the one in the Azure assignment - changing the value in the assignment."
                                }
                            }
                            elseif ($ParametersInJson.$ParamName.GetType().Name -eq 'DateTime')
                            {
                                if ($ParametersInJson.$ParamName.ToString("o") -ne $ParametersInAzure.$ParamName.value)
                                {
                                    $parametersMatch = $false
                                    Write-Output "    The ""$ParamName"" parameter exists in JSON but has a different value from the one in the Azure assignment - changing the value in the assignment."
                                }
                            }
                            else
                            {
                                if (-not (($ParametersInJson.$ParamName) -eq ($ParametersInAzure.$ParamName.value)))
                                {
                                    $parametersMatch = $false
                                    Write-Output "    The ""$ParamName"" parameter exists in JSON but has a different value from the one in the Azure assignment - changing the value in the assignment."
                                }
                            }
                        }
                    }
                    # if params in JSONassignment match AzureAssigmentParameters, check if JSONassignment is missing some AzureAssignmentParameters
                    if ($parametersMatch -eq $true)
                    {
                        foreach ($ParamName in $ParameterNamesInAzure)
                        {
                            # check if azure param is present in json
                            if (('' -eq $ParametersInJson.$ParamName -or $null -eq $ParametersInJson.$ParamName))
                            {
                                $parametersMatch = $false
                                Write-Output "    The parameter ""$ParamName"" is in Azure assignment, but not in defined in JSON - removing the parameter from the assignemnt will only work if it has a default value in the definition."
                            }
                        }
                    }
                }

                #if match is false create policyparamobject  from JSON params
                if ($parametersMatch -eq $false)
                {
                    $PolicyParameterObject = @{ }

                    if (-not ('' -eq $ParametersInJson -or $null -eq $ParametersInJson))
                    {
                        $PolicyParameterObject = $ParametersInJson | ConvertTo-Hashtable
                    }
                } # end policyparamobject creation


                #region compare basic attributes
                $displayNameMatches = $AssignmentInAzure.Properties.displayName -eq $AssignmentInJson.displayName
                $enforcementModeMatches = $AssignmentInAzure.Properties.enforcementMode -eq $AssignmentInJson.enforcementMode
                # extra tricks are required, otherwise the description couldn't be removed once it was set
                $descriptionMatches = ($AssignmentInAzure.Properties.description -eq $AssignmentInJson.description) -or ($AssignmentInAzure.Properties.description -eq ' ' -and $null -eq $AssignmentInJson.description) -or ($AssignmentInAzure.Properties.description -eq ' ' -and '' -eq $AssignmentInJson.description)


                # compare notScopes
                if ($null -eq $AssignmentInAzure.Properties.notScopes -and '' -eq $AssignmentInJson.notScopes)
                {
                    $notScopesMatch = $true
                }
                elseif ($null -ne $AssignmentInAzure.Properties.notScopes -and '' -ne $AssignmentInJson.notScopes)
                {
                    If ( Compare-Object -ReferenceObject $AssignmentInAzure.Properties.notScopes -DifferenceObject $AssignmentInJson.notScopes )
                    {
                        $notScopesMatch = $false
                    }
                    else
                    {
                        $notScopesMatch = $true
                    }
                }
                else
                {
                    $notScopesMatch = $false
                }

                # compare assignedIdentity - (assignedIdentity removal not possible)
                $turnOnAssignedIdentity = $AssignmentInJson.managedIdentity.assignIdentity -eq $true
                if ($AssignmentInAzure.Identity)
                {
                    $assignedIdentityEnabledOnAzure = $true
                }
                else
                {
                    $assignedIdentityEnabledOnAzure = $false
                }
                $assignedIdentityMatches = $assignedIdentityEnabledOnAzure -eq $AssignmentInJson.managedIdentity.assignIdentity

                #endregion compare basic attributes

                #region update assignment of necessary
                if (-not $assignedIdentityMatches -and -not $turnOnAssignedIdentity)
                {
                    Write-Error "It's not possible to remove managed Identity, once it was created for the assignment. To remove the managed identity, you need to delete and recreate this assignment." -ErrorAction Stop
                }
                elseif ($assignedIdentityEnabledOnAzure -and $AssignmentInJson.managedIdentity.location -ne $AssignmentInAzure.Location)
                {
                    Write-Error "You can't change the location of the already existing managed identity of the assignment ""$AssignmentId"". To change the location of the assignment, you need to delete and recreate this assignment." -ErrorAction Stop
                }
                elseif ( $turnOnAssignedIdentity -and -not $AssignmentInJson.managedIdentity.location )
                {
                    Write-Error "The managed identity won't be created for the assignment ""$AssignmentId"" without having the 'location' value defined. Provide the 'location' value for the managed identity, or set the value of the 'assignIdentity' property to false, in case you don't want to have a managed identity created." -ErrorAction Stop
                }
                elseif ( $displayNameMatches -and $descriptionMatches -and $parametersMatch -and $notScopesMatch -and $enforcementModeMatches -and $assignedIdentityMatches)
                {
                    Write-Output "        No changes are required in the policy/initative assignment."
                }
                # updates are necessary
                else
                {
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
                    if (-not $parametersMatch)
                    {
                        $AssignmentConfig.Add('PolicyParameterObject', $PolicyParameterObject)
                    }

                    # add notScopes
                    if ($AssignmentInJson.notScopes) { $AssignmentConfig.Add('NotScope', $AssignmentInJson.notScopes) }

                    # add description
                    if ($AssignmentInJson.description) { $AssignmentConfig.Add('Description', $AssignmentInJson.description) }
                    else
                    {
                        $AssignmentConfig.Add('Description', ' ')
                    }
                    if ($AssignmentInJson.assignIdentity -eq $true -and $AssignmentInJson.location)
                    {
                        $AssignmentConfig.Add('AssignIdentity', $true)
                        $AssignmentConfig.Add('Location', $AssignmentInJson.location)
                    }

                    # add metadata
                    $Metadata = @{"assignedBy" = "$($Identity.DisplayName) (ObjectId: $($Identity.Id))" } | ConvertTo-Json
                    $AssignmentConfig.Add('Metadata', $Metadata)

                    # add managedIdentity
                    if ($turnOnAssignedIdentity)
                    {
                        $AssignmentConfig.Add('AssignIdentity', $true)
                        $AssignmentConfig.Add('Location', $AssignmentInJson.managedIdentity.location)
                    }

                    # UPDATE assignment
                    $UpdatedAssignment = Set-AzPolicyAssignment @AssignmentConfig -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                    if ($UpdatedAssignment)
                    {
                        Write-Output "    Assignment successfully updated."
                        $script:noOfAssignmentsUpdated++
                    }
                    else
                    {
                        Write-Error "Policy couldn't be updated." -ErrorAction Stop
                    }
                }
                #endregion update assignment of necessary

                #region RBAC continuous check
                # creating RBAC role assignments based on the policy definition
                if ($AssignmentInJson.managedIdentity.assignIdentity -eq $true -and $AssignmentInJson.managedIdentity.location)
                {
                    $roleDefinitionIds = @()
                    # fetching role definition IDs for RBAC
                    if ($null -ne $DefinitionsInInitative) # if it's an initiative definition
                    {

                        foreach ($DefinitionInInitative in $DefinitionsInInitative)
                        {
                            # $Def = Get-AzPolicyDefinition -Id $DefinitionInInitative.policyDefinitionId -WarningAction SilentlyContinue
                            $Def = $DefinitionsInScope | Where-Object {$_.ResourceId -eq $DefinitionInInitative.policyDefinitionId} -WarningAction SilentlyContinue
                            # if the policy definition has roleDefinitionIds, add them to the array
                            if ($Def.Properties.policyRule.then.details.roleDefinitionIds)
                            {
                                foreach ($RoleDefInDefinition in $Def.Properties.policyRule.then.details.roleDefinitionIds)
                                {
                                    if ($roleDefinitionIds -notcontains $RoleDefInDefinition)
                                    {
                                        $roleDefinitionIds += $RoleDefinDefinition
                                    }
                                }
                            }
                        }
                    }
                    else # if it's a single policy definition
                    {
                            # if the policy definition has roleDefinitionIds, add them to the array
                            if ($Definition.Properties.policyRule.then.details.roleDefinitionIds)
                            {
                                foreach ($RoleDefInDefinition in $Definition.Properties.policyRule.then.details.roleDefinitionIds)
                                {
                                    if ($roleDefinitionIds -notcontains $RoleDefInDefinition)
                                    {
                                        $roleDefinitionIds += $RoleDefInDefinition
                                    }
                                }
                            }
                    }

                    Write-Output "    RBAC role definitions used in policy/initative definition(s) in this assignement:"
                    Write-Output "        There are $($roleDefinitionIds.Count) distinct RBAC role definitions attached to definition(s) in this assignement (in JSON)."

                    # actually creating RBAC role assignments based on the policy definition
                    if ($roleDefinitionIds.Count -gt 0)
                    {

                        $ExistingRoleAssignments = $null
                        $ExistingRoleAssignments = Get-AzRoleAssignment -Scope $Item.Scope -ObjectId $AssignmentInAzure.Identity.PrincipalId -ErrorAction SilentlyContinue
                        Write-Output "        There are $($ExistingRoleAssignments.Count) distinct RBAC role assignments on this scope, attached to definition(s) in this assignement (in Azure)."

                        foreach ($roleDefinitionId in $roleDefinitionIds)
                        {
                            $roleDefId = $roleDefinitionId.Split("/") | Select-Object -Last 1

                            while ($true)
                            {
                                if (Get-AzADServicePrincipal -ObjectId $AssignmentInAzure.Identity.PrincipalId -ErrorAction SilentlyContinue)
                                {
                                    break
                                }
                            }

                            $ExistingRoleAssignment = $null
                            Write-Output "    Fetching RBAC role assignment (definitionId: $roleDefId) for the managed identity ($($AssignmentInAzure.Identity.PrincipalId)) of this assignment..."
                            $ExistingRoleAssignment = $ExistingRoleAssignments | Where-Object {$_.RoleDefinitionId -eq $roleDefId}

                            if (-not $ExistingRoleAssignment)
                            {
                                Write-Output "        RBAC Role assignment doesn't exist."
                                Write-Output "        Creating RBAC role assignment (definitionId: $roleDefId) for the managed identity ($($AssignmentInAzure.Identity.PrincipalId)) of this assignment..."
                                $NewRoleAssignment = New-AzRoleAssignment -Scope $Item.Scope -ObjectId $AssignmentInAzure.Identity.PrincipalId -RoleDefinitionId $roleDefId -InformationAction SilentlyContinue
                                if ($NewRoleAssignment)
                                {
                                    $script:noOfRoleAssignmentsChanged++
                                    Write-Output "        RBAC role assignments changed (created)."
                                }
                            }
                            else
                            {
                                Write-Output "        This RBAC Role assignment is already configured."

                                # removing RBAC role assignment from scope, in case it the roleDefinitionId has been removed from the policy definition
                                Write-Output "        Looking for any RBAC Role assignments to clean up..."

                                foreach ($RoleAssignment in $ExistingRoleAssignments)
                                {
                                    $roleDefIds = @()
                                    foreach ($roleDefinitionId in $roleDefinitionIds)
                                    {
                                        $roleDefIds += $roleDefinitionId.Split("/") | Select-Object -Last 1
                                    }

                                    if ($RoleAssignment.RoleDefinitionId -notin $roleDefIds)
                                    {
                                        Write-Output "        Removing Role assignment (definitionId: $roleDefId) for the managed identity ($($AssignmentInAzure.Identity.PrincipalId))."
                                        Remove-AzRoleAssignment -Scope $RoleAssignment.Scope -ObjectId $RoleAssignment.ObjectId -RoleDefinitionId $RoleAssignment.RoleDefinitionId
                                        $script:noOfRoleAssignmentsRemoved++
                                        Write-Output "        RBAC role assignments deleted."
                                    }
                                    else
                                    {
                                        Write-Output "        There are no RBAC Role assignments to be removed."
                                    }
                                }
                            }
                        }

                    }
                    else
                    {
                        Write-Warning "This assignment has a managed service identity assigned, but there are no role definition IDs provided in the policy/initiative definition(s)."
                    }
                }
                #endregion RBAC continuous check

            }
            #endregion UPDATE scenario
        }

        #region DELETION scenario
        Write-Output ""
        Write-Output ""
        Write-Output "    -------------------------------------------------------------------------------------------------------------------"
        Write-Output "    Fetching assignments for removal"
        Write-Output "    -------------------------------------------------------------------------------------------------------------------"

        $AssignmentIdsInJson = @()
        $AssignmentsToDelete = @()
        foreach ($AssignmentInJson in $AssignmentsInJson)
        {
            $AssignmentIdsInJson += $Item.Scope + "/providers/Microsoft.Authorization/policyAssignments/" + $AssignmentInJson.name
        }
        foreach ($AssignmentInAzure in $AssignmentsInAzure)
        {
            if ($AssignmentInAzure.ResourceId -notin $AssignmentIdsInJson)
            {
                Write-Warning "Marked for deletion: $($AssignmentInAzure.Properties.displayName) - $($AssignmentInAzure.ResourceId)"
                #delete
                $AssignmentsToDelete += $AssignmentInAzure
            }
        }

        $script:noOfAssignmentsToDelete += $AssignmentsToDelete.Count

        if ($AssignmentsToDelete.Count -eq 0)
        {
            Write-Output "    There are no assignments marked for deletion."
            Write-Output ""
            Write-Output ""
        }

        # DELETE assignments
        if ($AssignmentsToDelete.Count -gt 0)
        {
            if ($DeleteIfMarkedForDeletion.IsPresent)
            {
                Write-Output ""
                Write-Output ""
                Write-Output "    -------------------------------------------------------------------------------------------------------------------"
                Write-Output "    Removing assignments"
                Write-Output "    -------------------------------------------------------------------------------------------------------------------"

                foreach ($AssignmentToDelete in $AssignmentsToDelete)
                {
                    Write-Warning "Removing assignment: $($AssignmentToDelete.Properties.displayName) - $($AssignmentToDelete.ResourceId)"

                    $ItemDeleted = Remove-AzPolicyAssignment -Id $AssignmentToDelete.ResourceId -Confirm:$false -ErrorAction Stop -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                    if ($ItemDeleted -eq $true)
                    {
                        $script:noOfAssignmentsDeleted++
                        Write-Output "    Policy definition successfully deleted from Azure."

                        if ($AssignmentToDelete.Identity.PrincipalId)
                        {
                            Write-Output "    Removing RBAC assignment(s)..."
                            $ExistingRoleAssignments = Get-AzRoleAssignment -Scope $Item.Scope -ObjectId $AssignmentToDelete.Identity.PrincipalId
                            foreach ($RoleAssignment in $ExistingRoleAssignments)
                            {
                                Remove-AzRoleAssignment -Scope $RoleAssignment.Scope -ObjectId $RoleAssignment.ObjectId -RoleDefinitionId $RoleAssignment.RoleDefinitionId
                                $script:noOfRoleAssignmentsRemoved++
                                Write-Output "        RBAC role assignments deleted."
                            }
                        }
                        Write-Output "    _______________________________________________________________________________________________________________"
                    }
                    Write-Output ""
                    $ItemDeleted = $null
                }
            }
            else
            {
                Write-Output ""
                Write-Output ""
                Write-Output "    -------------------------------------------------------------------------------------------------------------------"
                Write-Output "    Assignments marked for removal"
                Write-Output "    -------------------------------------------------------------------------------------------------------------------"
                Write-Warning "The following assignments are not defined in the assignment JSON file. These should be deleted by running this script again, using the ""-DeleteIfMarkedForDeletion"" switch."
                foreach ($AssignmentToDelete in $AssignmentsToDelete)
                {
                    Write-Output "    $($AssignmentToDelete.Properties.displayName) - $($AssignmentToDelete.ResourceId)"
                }
                Write-Output ""
            }
            Write-Output ""
        }
        #endregion DELETION scenario

        # recursively going through all "child" scopes
        if ($Item.Children)
        {
            Set-AssignmentsInJson -InputObject $Item.Children
        }
    }
}

#endregion Functions



#region Get/check JSON files

Write-Output "-------------------------------------------------------------------------------------------------------------------"
Write-Output "Looking for the Assignment and Assignment Schema JSON files in the folder provided"
Write-Output "-------------------------------------------------------------------------------------------------------------------"

# Reading assignments from JSON files
$JsonFile = Get-Item -Path $AssignmentFilePath -ErrorAction Stop

# Check if the JSON file has content
if ($JsonFile)
{
    Write-Output "    Assignment file found: $AssignmentFilePath"
    $AssignmentsJson = Get-Content -Path $AssignmentFilePath -Raw -ErrorAction Stop
    if ($AssignmentsJson)
    {
        Write-Output "    Assignment file has content: $AssignmentFilePath"
    }
    else
    {
        Write-Error "Assignment file is empty" -ErrorAction Stop
    }
}

# Check if the assignments JSON file is a valid JSON
try
{
    $AssignmentsJson | Test-Json -ErrorAction Stop | Out-Null
    Write-Output "    Assignment file is a valid JSON."
}
catch
{
    Write-Error "The assignment file is not a valid JSON." -ErrorAction Stop
}

$AssignmentsObject = $AssignmentsJson | ConvertFrom-Json

# Load the assignment schema
$SchemaFile = Get-Item -Path $AssignmentSchemaPath -ErrorAction Stop

# Check if the schema file has content
if ($SchemaFile)
{
    Write-Output "    Schema file found: $($AssignmentSchemaPath)"
    $Schema = $SchemaFile | Get-Content -Raw -ErrorAction Stop
    if ($Schema)
    {
        Write-Output "    Schema file has content: $($AssignmentSchemaPath)"
    }
    else
    {
        Write-Error "Schema file is empty" -ErrorAction Stop
    }
}

# Check if the assignments JSON file is compatible with the schema - convert to JSON first
Write-Output "    Testing the assignments file against the master schema..."
if (($AssignmentsObject.Count -ne 1) -or (-not $AssignmentsObject.root))
{
    Write-Error "The assignments file content does not have exactly one top-level 'root' element!" -ErrorAction Stop
}

# TESTING against the schema
Test-AssignmentsJson -JsonRootScope $AssignmentsObject.root
Write-Output "    The JSON file is compliant with the schema."

#endregion Get/check JSON files



#region Process assignments JSON

# Getting
$Identity = Get-Identity

# Checking RBAC permissions
if (-not $SkipRbacValidation.IsPresent)
{
    Test-RbacPermissions -Identity $Identity -AssignmentsObject $AssignmentsObject -CheckRbacPermissionsForAllScopes $CheckRbacPermissionsForAllScopes
}

# Getting assignments from the JSON file
$ScopesInJson = Get-Scopes -InputObject $AssignmentsObject.root

Write-Output ""
Write-Output ""
Write-Output "-------------------------------------------------------------------------------------------------------------------"
Write-Output "Processing assignments in the JSON file"
Write-Output "-------------------------------------------------------------------------------------------------------------------"
Write-Output "    Parsing assignments..."
Write-Output "    There are $($ScopesInJson.Count) scopes in the assignments file:"

foreach ($ScopeInJson in $ScopesInJson)
{
    Write-Output "        $ScopeInJson"
}
Write-Output ""
Write-Output ""

# PROCESSING assignments JSON
if ($AssignmentsObject)
{
    $Root = $AssignmentsObject.root
    Set-AssignmentsInJson -InputObject $Root
}

# Summary (stats)
Write-Output "======================================================================================================================="
Write-Output "Statistics:"
Write-Output "======================================================================================================================="
Write-Output "Number of assignments created       : $noOfAssignmentsCreated"
Write-Output "Number of assignments updated       : $noOfAssignmentsUpdated"
Write-Output "Number of assignments to be deleted : $noOfAssignmentsToDelete"
Write-Output "Number of assignments deleted       : $noOfAssignmentsDeleted"
Write-Output ""
Write-Output "Number of _RBAC role assignments created_ for new policy/initative assignments      : $noOfRoleAssignmentsCreated"
Write-Output "Number of _RBAC role assignments changed_ for existing policy/initative assignments : $noOfRoleAssignmentsChanged"
Write-Output "Number of _RBAC role assignments deleted_ for existing policy/initative assignments : $noOfRoleAssignmentsRemoved"
Write-Output ""
Write-Output "Tip: if you want to find where the above changes have happened, search for the highlighted words between the '_' signes in this log - e.g. 'RBAC role assignments deleted'"
Write-Output ""
#endregion Process assignments JSON
