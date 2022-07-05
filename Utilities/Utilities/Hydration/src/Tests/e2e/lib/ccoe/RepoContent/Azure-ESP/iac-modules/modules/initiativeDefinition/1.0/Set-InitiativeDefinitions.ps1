# Requires -PSEdition Core

<#
.SYNOPSIS
    This script creates new Initiatives/PolicySet definitions in the management group or subscription it is running against.

.DESCRIPTION
    The script supports creating policyset definitions anywhere in the management group hierarchi and directly in the subscription.
    Tests whether a User/ServicePrincipal executing this script has the given RBAC role(s) assigned on the Management Group level or Subscription level.
    In case of RBAC roles assigned to AAD Groups, the function does not check nested AAD Groups, only direct Group members are considered
    Role Limitations: The code checks only the specific given RBAC role(s), and ignores whether higher role is assigned (Contributor, Owner, or custom role)

.PARAMETER ManagementGroupName
    Mandatory. Name of the management group to create the PolicySet definitions in. Cannot be used in combination with the "SubscriptionId" parameter

.PARAMETER SubscriptionId
    Mandatory. ID of the subscription to create the PolicySet definitions in. Cannot be used in combination with the "ManagementGroupName" parameter

.PARAMETER InitiativeDefinitionRootFolder
    Optional. Path of the root folder containing the PolicySet definitions.

.PARAMETER InitiativeDefinitionSchemaFilePath
    Optional. Path to the PolicySet definition JSON schema.

.PARAMETER AadTenantFqdn
    Optional. FQDN of the AAD tenant, e.g. <your company>.onmicrosoft.com .  It is mandatory, if the script runs on behalf of a guest user.

.PARAMETER CheckRbacPermissions
    Optional. When this switch is used, RBAC permissions are checked before acting on definitions. To perfom this check, the running user needs Graph API permissions.


.EXAMPLE
    .\Set-InitiativeDefinitions.ps1 -ManagementGroupName "DefaultManagementGroup"

    Create the initiative/policyset definitions in the ManagementGroup "DefaultManagementGroup"

.EXAMPLE
    .\Set-InitiativeDefinitions.ps1 -SubscriptionId 123456789-1234-1234-1234-12345678abcd

    Create the initiative/policyset definitions in the subscription "123456789-1234-1234-1234-12345678abcd"

.EXAMPLE
    .\Set-InitiativeDefinitions.ps1 -SubscriptionId 123456789-1234-1234-1234-12345678abcd -DeleteIfMarkedForDeletion

    Create the initiative/policyset definitions in the subscription "123456789-1234-1234-1234-12345678abcd" while deleting all policyset definitions not included in the policyset definition root folder

.EXAMPLE
    .\Set-InitiativeDefinitions.ps1 -SubscriptionId 123456789-1234-1234-1234-12345678abcd -InitiativeDefinitionRootFolder "./InitiativeDefinitions" -DeleteIfMarkedForDeletion -InitiativeDefinitionSchemaFilePath ".\initiativeDefinitionSchema"

    Create the initiative/policyset definitions in the subscription "123456789-1234-1234-1234-12345678abcd" deleting all policyset definitions not included in the policyset definition root folder. The root folder is set to "./InitiativeDefinitions" and schema path ".\initiativeDefinitionSchema"

.NOTES
    This script is designed to be run in Azure DevOps pipelines.
    Version:        1.1
    Creation Date:  2020-06-29
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true,
        ParameterSetName = "mg",
        HelpMessage = "Name of the management group to create the Initiative definitions in.")]
    [string]$ManagementGroupName,

    [Parameter(Mandatory = $true,
        ParameterSetName = "sub",
        HelpMessage = "ID of the subscription to create the Initiative definitions in.")]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false,
        HelpMessage = "Path of the root folder containing the Initiative definitions.")]
    [string]$InitiativeDefinitionRootFolder = "./InitiativeDefinitions",

    [Parameter(Mandatory = $false,
        HelpMessage = "Path to the Initiative definition JSON schema.")]
    [string]$InitiativeDefinitionSchemaFilePath = "./initiativeDefinitionSchema.json",

    [Parameter(Mandatory = $false,
        HelpMessage = "FQDN of the AAD tenant, e.g. <your company>.onmicrosoft.com .  It is mandatory, if the script runs on behalf of a guest user.")]
    [string]$AadTenantFqdn = "company.onmicrosoft.com",

    [Parameter(Mandatory = $false,
        HelpMessage = "When this switch is used, RBAC permissions are checked before trying any activity on the definitions. This requires Graph API permissions.")]
    [switch]$CheckRbacPermissions = $false
)

# Initialize counters
$noOfPolicySetsCreated = 0
$noOfPolicySetsModified = 0
$noOfPolicySetsDeleted = 0

#region Get/check JSON files

# Load the PolicySet definition schema
$Schema = Get-Content -Path $InitiativeDefinitionSchemaFilePath -Raw -ErrorAction Stop

# Reading PolicySet definitions from JSON files
$policySets = Get-ChildItem -Path $InitiativeDefinitionRootFolder -Recurse -File -Filter "*.json"

# Check if the root folder contains JSON files
Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose
Write-Verbose  "Looking for JSON files in the folder provided ($InitiativeDefinitionRootFolder)." -Verbose
Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose

if ($policySets.Count -lt 1 -and (-not $DeleteIfMarkedForDeletion.IsPresent)) {
    Write-Error "There aren't any JSON files in the folder provided ($InitiativeDefinitionRootFolder)!"
    Write-Error "Make sure you provided the correct folder path in the -InitiativeDefinitionRootFolder parameter!"
    Write-Error "If you want to delete all the existing custom initiative definitions currently existing in the scope, use the -DeleteIfMarkedForDeletion switch." -ErrorAction Stop
}
elseif ($policySets.Count -lt 1 -and $DeleteIfMarkedForDeletion.IsPresent) {
    Write-Warning ""
    Write-Warning "There aren't any JSON files in the folder provided ($InitiativeDefinitionRootFolder)!"
    Write-Warning "Deleting all custom policy definitions in scope..."
    Write-Warning ""
}
else {
    Write-Verbose  "The following $($policySets.count) Initiative definition JSON files were found:" -Verbose

    foreach ($policySet in $policySets) {
        Write-Verbose  "    $($policySet.Name)" -Verbose
    }

    Write-Verbose  "" -Verbose
    Write-Verbose  "" -Verbose
}

# Getting PolicySet definitions from the JSON files
Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose
Write-Verbose  "Reading Initiative definitions from the JSON files" -Verbose
Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose

$policySetObjects = @()
$uniquePolicySets = @{ }

foreach ($policySet in $policySets) {

    # Check if the policySet definition JSON file is a valid JSON
    $Json = Get-Content -Path $policySet.VersionInfo.FileName -Raw -ErrorAction Stop

    Write-Verbose  "    $($policySet.Name) - $($policySet.VersionInfo.FileName)" -Verbose

    try {
        $Json | Test-Json -ErrorAction Stop | Out-Null
        Write-Verbose  "        The JSON file is valid." -Verbose
    }
    catch {
        Write-Error "The JSON file is not valid." -ErrorAction Stop
    }

    $Json | Test-Json -Schema $Schema -ErrorAction Stop | Out-Null
    Write-Verbose  "        The JSON is compliant with the schema." -Verbose

    Write-Verbose  "        Parsing Initiative definition..." -Verbose

    $policySetObj = $Json | ConvertFrom-Json
    $policySetObjects += $policySetObj

    if ($uniquePolicySets.Keys -notcontains $policySetObj.name ) {
        $uniquePolicySets.Add($policySetObj.name, $policySet.VersionInfo.FileName)
    }
    else {
        $policySetInQuestion = $policySetObj.name
        $conflictingPolicyPath = $uniquePolicySets.$policySetInQuestion

        Write-Error "There is more than one Initiative definition JSON that contains this definition set: ""$($policySetObj.name)"". To proceed, resolve this conflict in the following files and run this configuration script again! File1: ""$conflictingPolicyPath"", File2: ""$($policySet.VersionInfo.FileName)""" -ErrorAction Stop
    }

    Write-Verbose  "" -Verbose

}
Write-Verbose  "" -Verbose

#endregion


#region Check permissions

# Input RBAC role name(s) to be checked

$requiredRoleNames = @(
    "Resource Policy Contributor"
    "Owner"
)

Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose
Write-Verbose  "Getting the Object ID of the User / Service Principal..." -Verbose
Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose


$Context = Get-AzContext
$account = $Context.Account

if ($account.Type -eq "User") {
    # Standard user
    $User = Get-AzADUser -UserPrincipalName $account.Id
    if ($User) {
        $objId = $User.Id
    }
    # Guest user
    else {
        $UPN = $account.Id.Replace("@", "_") + "#EXT#@" + $AadTenantFqdn
        $objId = (Get-AzADUser -UserPrincipalName $UPN).Id
    }

    Write-Verbose  "    The script is running on behalf of this User (Object ID): $objId" -Verbose
}
elseif ($account.Type -eq "ServicePrincipal") {
    $objId = (Get-AzADServicePrincipal -ApplicationId $account.Id).Id
    Write-Verbose  "    The script is running on behalf of this Service Principal (Object ID): $objId" -Verbose
}
else {
    Write-Error "Unknown/Unsupported type of the principal: $($account.Type), aborting the script !" -ErrorAction Stop
}

if ($CheckRbacPermissions -eq $true) {
    Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose
    Write-Verbose  "Validating if the User / Service Principal has the required permissions to author Policies (incl. Initiatives)" -Verbose
    Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose
    # Getting RBAC assignments on the specified scope

    Write-Verbose  "    Getting RBAC assignments on the specified scope..." -Verbose

    if ( $PSBoundParameters.ContainsKey("ManagementGroupName") ) {
        $roleAssignments = Get-AzRoleAssignment -Scope "/providers/Microsoft.Management/managementGroups/$ManagementGroupName" -ErrorAction SilentlyContinue | Where-Object { $requiredRoleNames -contains $_.RoleDefinitionName }
    }
    elseif ( $PSBoundParameters.ContainsKey("SubscriptionId") ) {
        $roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId" -ErrorAction SilentlyContinue | Where-Object { $requiredRoleNames -contains $_.RoleDefinitionName }
    }


    # Checking the User/Service Principal authorization

    Write-Verbose  "    Checking the User/Service Principal authorization..." -Verbose

    $returnStatus = $false

    foreach ($assignment in $roleAssignments) {
        if ($objId -eq $assignment.ObjectId) {
            $returnStatus = $true
            break
        }

        if ($assignment.ObjectType -eq "Group") {
            $groupMembers = Get-AzADGroupMember -GroupObjectId $assignment.ObjectId
            if ($groupMembers.Id -contains $objId) {
                $returnStatus = $true
                break
            }
        }
    }


    # Output result $true/$false

    if ($returnStatus) {
        Write-Verbose  "    The User/Service Principal $($account.Id) has been authorized" -Verbose
        Write-Verbose  "" -Verbose
        Write-Verbose  "" -Verbose
    }
    else {
        Write-Error "The User/Service Principal $($account.Id) is not assigned to any of the required roles, aborting the script !" -ErrorAction Stop
    }

}    
#endregion



#region Check existing policy definitions

# Getting Policy Definitions in the chosen scope of Azure
$params = @{ }
if ( $PSBoundParameters.ContainsKey("ManagementGroupName") ) {
    $params.Add("ManagementGroupName", $ManagementGroupName)
    Write-Verbose  "-----------------------------------------------------------------------------------------------------------------------------" -Verbose
    Write-Verbose  "Fetching existing custom Azure Initiative and Policy Definitions from management group ""$ManagementGroupName""" -Verbose
    Write-Verbose  "-----------------------------------------------------------------------------------------------------------------------------" -Verbose
    $existingCustomDefinitions = Get-AzPolicySetDefinition @params -WarningAction SilentlyContinue | Where-Object { $_.Properties.policyType -eq "Custom" -and $_.ResourceId -like "*/providers/Microsoft.Management/managementGroups/$ManagementGroupName/providers/Microsoft.Authorization/policySetDefinitions/*" }
    $existingPolicyDefinitions = Get-AzPolicyDefinition @params -WarningAction SilentlyContinue

}
elseif ( $PSBoundParameters.ContainsKey("SubscriptionId") ) {
    $params.Add("SubscriptionId", $SubscriptionId)
    $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId -WarningAction SilentlyContinue
    Write-Verbose  "-----------------------------------------------------------------------------------------------------------------------------" -Verbose
    Write-Verbose  "Fetching existing custom Azure Initiatives and Policy Definitions from subscription $($subscription.Name) ($SubscriptionId)" -Verbose
    Write-Verbose  "-----------------------------------------------------------------------------------------------------------------------------" -Verbose
    $existingCustomDefinitions = Get-AzPolicySetDefinition @params -WarningAction SilentlyContinue | Where-Object { $_.Properties.policyType -eq "Custom" -and $_.ResourceType -eq "Microsoft.Authorization/policySetDefinitions" -and $_.ResourceId -like "*/subscriptions/$SubscriptionId/providers/Microsoft.Authorization/policySetDefinitions*" }
    $existingPolicyDefinitions = Get-AzPolicyDefinition @params -WarningAction SilentlyContinue
}

# Checking if any of the existing custom policySet definitions have to be deleted
if ($null -ne $existingCustomDefinitions) {
    Write-Verbose  "$($existingCustomDefinitions.count) custom Initiative definitions found in the chosen scope:" -Verbose
    Write-Verbose  "" -Verbose

    $definitionSetsToDelete = @()
    foreach ($item in $existingCustomDefinitions) {
        if ($policySetObjects.Name -notcontains $item.Name) {
            Write-Warning "Marked for deletion (not defined in JSON): $($item.Properties.displayName) - ($($item.ResourceId)"
            $definitionSetsToDelete += $item
        }
        else {
            Write-Verbose  "    $($item.Properties.displayName) - ($($item.ResourceId)" -Verbose
        }
    }
}
else {
    Write-Verbose  "There are no custom Initiative definitions deployed in the selected scope in Azure." -Verbose
}

#endregion


#region Create/update policySet definitions

# Create/update policySet definitions
Write-Verbose  "" -Verbose
Write-Verbose  "" -Verbose
Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose
Write-Verbose  "Creating / updating Initiative definitions" -Verbose
Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose

foreach ($policySetObject in $policySetObjects) {

    # Constructing policySet definitions parameters for splatting

    # preserver array also when just 1 item
    if ( (($policySetObject.policyDefinitions).Length) -eq 1) {
        # if array lenght is 1 ConvertTo-Json removes array brackets []
        $PolicyDefinitionBody = "[" + ($policySetObject.policyDefinitions | ConvertTo-Json -Depth 100) + "]"
    }
    else {
        $PolicyDefinitionBody = ($policySetObject.policyDefinitions | ConvertTo-Json -Depth 100)
    }


    ######## validating policyDefinitionID existence ###########
    if (-not $SkipPolicyDefinitionIdVerification.IsPresent) {
        Write-Verbose  "" -Verbose
        Write-Verbose  "    Check existence of referenced policyDefinitionIDs..." -Verbose

        foreach ($policyDefinition in $policySetObject.policyDefinitions) {
            if ( -not ($existingPolicyDefinitions | Where-Object { $_.PolicyDefinitionID -eq $policyDefinition.policyDefinitionId })) {
                Write-Error "The referenced policyDefinitionID ""$($policyDefinition.policyDefinitionId)"" doesn't exist at the specified scope" -ErrorAction Stop
            }
        }
        Write-Verbose  "    All referenced policyDefinitionIDs exist in Azure" -Verbose
    }

    $policySetDefinitionConfig = @{
        Name             = $policySetObject.name
        DisplayName      = $policySetObject.displayName
        PolicyDefinition = $PolicyDefinitionBody
        Parameter        = ($policySetObject.parameters | ConvertTo-Json -Depth 100)
    }

    # Adding SubscriptionId or ManagementGroupName value (depending on the parameter set in use)
    $policySetDefinitionConfig += $params

    # Add policySet description if it's present in the definition file
    if ($policySetObject.description) {
        $policySetDefinitionConfig.Add("Description", $policySetObject.description)
    }

    #Add policySet metadata if it's present in the definition file
    if ($policySetObject.metadata) {
        $policySetDefinitionConfig.Add("Metadata", ($policySetObject.metadata | ConvertTo-Json -Depth 100))
    }


    # Create/update policySet definition with the above parameters

    # Creation scenario
    if ( -not ($existingCustomDefinitions | Where-Object { $_.Name -eq $policySetDefinitionConfig.Name })) {
        Write-Verbose  "" -Verbose
        Write-Verbose  "    Creating Initiative definition ""$($policySetDefinitionConfig.Name)"" - ($($policySetDefinitionConfig.DisplayName))" -Verbose

        if ($PSCmdlet.ShouldProcess(("Policy definition [{0}]" -f $policySetDefinitionConfig.Name), "Create")) {
            $newPolicySet = New-AzPolicySetDefinition @policySetDefinitionConfig -ErrorAction Stop -WarningAction SilentlyContinue

            # Check success
            if ($newPolicySet.Name -eq $policySetDefinitionConfig.Name) {
                Write-Verbose  "" -Verbose
                Write-Verbose  "    Initiative definition successfully created." -Verbose
                Write-Verbose  "__________________________________________________________" -Verbose
                $noOfPolicySetsCreated++

            }
            $newPolicySet = $null
        }
    }
    # Update scenario
    else {
        Write-Verbose  "" -Verbose
        Write-Verbose  "    ""$($policySetDefinitionConfig.Name)"" - ($($policySetDefinitionConfig.DisplayName)) already exists in Azure." -Verbose
        Write-Verbose  "    Comparing attributes..." -Verbose
        # Check if policySet definition in Azure is the same as in the JSON file
        $matchingCustomDefinitionInAzure = $existingCustomDefinitions | Where-Object { $_.Name -eq $policySetDefinitionConfig.Name }

        # check if policy definitions matches - compare for each definition existence(ID) and the parameters
        $policyDefinitionsMatches = $true
        foreach ($policyDefinition in ($policySetDefinitionConfig.PolicyDefinition | ConvertFrom-Json)) {
            #check if policyDefinition is part of the defined definitions in Azure
            $existingDefinition = ($matchingCustomDefinitionInAzure.Properties.policyDefinitions | Where-Object { $_.policyDefinitionId -eq $policyDefinition.policyDefinitionId })
            if ($null -eq $existingDefinition -or '' -eq $existingDefinition) {
                Write-Verbose  "        The policyDefinitionId" -Verbose
                Write-Verbose  "            ""$($policyDefinition.policyDefinitionId)""" -Verbose
                Write-Verbose  "        exists in JSON Initiative definition but it doesn't exist in the Azure Initiative definition." -Verbose
                $policyDefinitionsMatches = $false
            }
            elseif (($existingDefinition.parameters | ConvertTo-Json) -ne ($policyDefinition.parameters | ConvertTo-Json)) {
                # policyDefinitionID in the policySet exists in both JSON and Azure - compare parameters
                Write-Verbose  "        The policyDefinitionId" -Verbose
                Write-Verbose  "            ""$($policyDefinition.policyDefinitionId)""" -Verbose
                Write-Verbose  "        exists in JSON Initiative definition and Azure Initiative definition, but it has different parameters defined." -Verbose
                $policyDefinitionsMatches = $false
            }
        }
        # iterate vice versa to check if in Azure there is a definitionID used, that is not in the JSON file
        foreach ($existingDefinition in $matchingCustomDefinitionInAzure.Properties.policyDefinitions) {
            if ($policySetDefinitionConfig.PolicyDefinition.definitionId -notcontains $existingDefinition.definitionId) {
                Write-Verbose  "        The policyDefinitionId" -Verbose
                Write-Verbose  "            ""$($policyDefinition.policyDefinitionId)""" -Verbose
                Write-Verbose  "        exists in Azure Initiative definition, but is not defined in JSON Initiative definition" -Verbose
                $policyDefinitionsMatches = $false
            }
        }

        $displayNameMatches = $matchingCustomDefinitionInAzure.Properties.DisplayName -eq $policySetDefinitionConfig.DisplayName
        $metadataMatches = ($matchingCustomDefinitionInAzure.Properties.metadata.category ) -eq (($policySetDefinitionConfig.metadata | ConvertFrom-Json).category)
        $descriptionMatches = $matchingCustomDefinitionInAzure.Properties.description -eq $policySetDefinitionConfig.description
        $parameterMatches = ($matchingCustomDefinitionInAzure.Properties.parameters | ConvertTo-Json -Depth 100) -eq $policySetDefinitionConfig.Parameter
        if (-not $parameterMatches) {
            Write-Verbose  "        The policyDefinitionId" -Verbose
            Write-Verbose  "            ""$($policyDefinition.policyDefinitionId)""" -Verbose
            Write-Verbose  "        exists in Azure Initiative definition, but the parameters are different" -Verbose

        }
        # Update policy definition in Azure if necessary
        if ( $displayNameMatches -and $policyDefinitionsMatches -and $parameterMatches -and $metadataMatches -and $descriptionMatches) {
            Write-Verbose  "        No changes are required" -Verbose
            Write-Verbose  "__________________________________________________________" -Verbose
        }
        else {
            Write-Verbose  "        The Initiative definition JSON file does not match the Initiative definition in Azure." -Verbose
            Write-Verbose  "           Updating the following value(s):" -Verbose
            Write-Verbose  "            - displayName :        $(-not $displayNameMatches)" -Verbose
            Write-Verbose  "            - description :        $(-not $descriptionMatches)" -Verbose
            Write-Verbose  "            - metadata :           $(-not $metadataMatches)" -Verbose
            Write-Verbose  "            - parameters :         $(-not $parameterMatches)" -Verbose
            Write-Verbose  "            - policyDefinitions :  $(-not $policyDefinitionsMatches)" -Verbose

            Write-Verbose  "        Updating Initiative definition..." -Verbose

            if ($PSCmdlet.ShouldProcess(("Policy definition [{0}]" -f $policySetDefinitionConfig.Name), "Update")) {
                $updatedPolicySet = Set-AzPolicySetDefinition @policySetDefinitionConfig -WarningAction SilentlyContinue -ErrorAction Stop

                # Check success
                if ($updatedPolicySet) {
                    Write-Verbose  "" -Verbose
                    Write-Verbose  "        Initiative definition successfully updated." -Verbose
                    Write-Verbose  "__________________________________________________________" -Verbose
                    $noOfPolicySetsModified++
                }
                $updatedPolicySet = $null
            }
        }
    }

    Write-Verbose  "" -Verbose

}
Write-Verbose  "" -Verbose

#endregion

# Summary (stats)
Write-Verbose  "-------------------------------------------------" -Verbose
Write-Verbose  "Statistics:" -Verbose
Write-Verbose  "-------------------------------------------------" -Verbose
Write-Verbose  "Number of Initiative definitions created       : $noOfPolicySetsCreated" -Verbose
Write-Verbose  "Number of Initiative definitions updated       : $noOfPolicySetsModified" -Verbose
Write-Verbose  "Number of Initiative definitions to be deleted : $($definitionSetsToDelete.count)" -Verbose
Write-Verbose  "Number of Initiative definitions deleted       : $noOfPolicySetsDeleted" -Verbose
Write-Verbose  "" -Verbose