#Requires -PSEdition Core

<#
.SYNOPSIS
    This script creates/updates/deletes Policy definitions in the management group or subscription it is running against.

    .DESCRIPTION
    The script supports creating policy definitions anywhere in the management group hierarchy and directly in the subscription.
    It dynamically handles "mode" and "description" attributes depending on their presence in the definition JSON.
    Tests whether a User/ServicePrincipal executing this script has the given RBAC role(s) assigned on the Management Group level or Subscription level.
    In case of RBAC roles assigned to AAD Groups, the function does not check nested AAD Groups, only direct Group members are considered
    Role Limitations: The code checks only the specific given RBAC role(s), and ignores whether higher role is assigned (Contributor, Owner, or custom role)

    .PARAMETER ManagementGroupName
    Name of the management group to create the policy definitions in.

    .PARAMETER SubscriptionId
    ID of the subscription to create the policy definitions in.

    .PARAMETER PolicyDefinitionRootFolder
    Path of the root folder containing the policy definitions.

    .PARAMETER DeleteIfMarkedForDeletion
    When using this switch, the script deletes all policy definitions from Azure that are not included somewhere within the policy definition root folder.

    .PARAMETER PolicyDefinitionSchemaFilePath
    Path to the policy definition JSON schema.

    .PARAMETER AadTenantFqdn
    FQDN of the AAD tenant, e.g. <your company>.onmicrosoft.com .  It is mandatory, if the script runs on behalf of a guest user.

    .PARAMETER CheckRbacPermissions
    When this switch is used, RBAC permissions are checked before acting on definitions. To perfom this check, the running user needs Graph API permissions.

    .EXAMPLE
    .\Set-PolicyDefinitions.ps1 -ManagementGroupName "DefaultManagementGroup"

    Create/Update/Delete policy definitions in the ManagementGroup "DefaultManagementGroup"

    .EXAMPLE
    .\Set-PolicyDefinitions.ps1 -SubscriptionId 123456789-1234-1234-1234-12345678abcd

    Create/Update/Delete policy definitions in the SubscriptionId 123456789-1234-1234-1234-12345678abcd

    .EXAMPLE
    .\Set-PolicyDefinitions.ps1 -SubscriptionId 123456789-1234-1234-1234-12345678abcd -DeleteIfMarkedForDeletion

    Create/Update/Delete policy definitions in the SubscriptionId 123456789-1234-1234-1234-12345678abcd while deleting all policy definitions not included in the policy definition definition root folder

    .EXAMPLE
    .\Set-PolicyDefinitions.ps1 -SubscriptionId 123456789-1234-1234-1234-12345678abcd -PolicyDefinitionRootFolder "./PolicyDefinitions" -DeleteIfMarkedForDeletion -PolicyDefinitionSchemaFilePath ".\policyDefinitionSchema.json"

    Create/Update/Delete policy definitions in the SubscriptionId 123456789-1234-1234-1234-12345678abcd while deleting all policy definitions not included in the policy definition definition root folder. The root folder is set to "./PolicyDefinitions" and schema path ".\policyDefinitionSchema"

.NOTES
    This script is designed to be run in Azure DevOps pipelines.
    Version:        1.1
    Creation Date:  2020-06-29
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true,
        ParameterSetName = "mg",
        HelpMessage = "Name of the management group to create the policy definitions in.")]
    [string]$ManagementGroupName,

    [Parameter(Mandatory = $true,
        ParameterSetName = "sub",
        HelpMessage = "ID of the subscription to create the policy definitions in.")]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false,
        HelpMessage = "Path of the root folder containing the policy definitions.")]
    [string]$PolicyDefinitionRootFolder = "./PolicyDefinitions",

    [Parameter(Mandatory = $false,
        HelpMessage = "When using this switch, the script deletes all policy definitions from Azure that are not included somewhere within the policy definition root folder.")]
    [switch]$DeleteIfMarkedForDeletion,

    [Parameter(Mandatory = $false,
        HelpMessage = "Path to the policy definition JSON schema.")]
    [string]$PolicyDefinitionSchemaFilePath = "$PSScriptRoot/policyDefinitionSchema.json",

    [Parameter(Mandatory = $false,
        HelpMessage = "FQDN of the AAD tenant, e.g. <your company>.onmicrosoft.com .  It is mandatory, if the script runs on behalf of a guest user.")]
    [string]$AadTenantFqdn = "company.onmicrosoft.com",

    [Parameter(Mandatory = $false,
        HelpMessage = "When this switch is used, RBAC permissions are checked before trying any activity on the definitions. This requires Graph API permissions.")]
    [switch]$CheckRbacPermissions = $false
)

# Initialize counters
$noOfDefinitionsCreated = 0
$noOfDefinitionsModified = 0
$noOfDefinitionsDeleted = 0

#region Get/check JSON files

# Load the policy definition schema
$Schema = Get-Content -Path $PolicyDefinitionSchemaFilePath -Raw -ErrorAction Stop

# Reading Policy definitions from JSON files
$policies = Get-ChildItem -Path $PolicyDefinitionRootFolder -Recurse -File -Filter "*.json"

# Check if the root folder contains JSON files
Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
Write-Verbose "Looking for JSON files in the folder provided ($PolicyDefinitionRootFolder)." -Verbose
Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose

if ($policies.Count -lt 1 -and (-not $DeleteIfMarkedForDeletion.IsPresent)) {
    Write-Error "There aren't any JSON files in the folder provided ($PolicyDefinitionRootFolder)!"
    Write-Error "Make sure you provided the correct folder path in the -PolicyDefinitionRootFolder parameter!"
    Write-Error "If you want to delete all the existing custom policy definitions currently existing in the scope, use the -DeleteIfMarkedForDeletion switch." -ErrorAction Stop
} elseif ($policies.Count -lt 1 -and $DeleteIfMarkedForDeletion.IsPresent) {
    Write-Warning ""
    Write-Warning "There aren't any JSON files in the folder provided ($PolicyDefinitionRootFolder)!"
    Write-Warning "Deleting all custom policy definitions in scope..."
    Write-Warning ""
} else {
    Write-Verbose "The following $($policies.count) policy definition JSON files were found:" -Verbose

    foreach ($policy in $policies) {
        Write-Verbose "    $($policy.Name)" -Verbose
    }

    Write-Verbose "" -Verbose
    Write-Verbose "" -Verbose
}

# Getting Policy definitions from the JSON files
Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
Write-Verbose "Reading Policy definitions from the JSON files" -Verbose
Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose

$policyObjects = @()
$uniquePolicies = @{}

foreach ($policy in $policies) {

    # Check if the policy definition JSON file is a valid JSON
    $Json = Get-Content -Path $policy.VersionInfo.FileName -Raw -ErrorAction Stop

    Write-Verbose "    $($policy.Name) - $($policy.VersionInfo.FileName)" -Verbose

    try {
        $Json | Test-Json -ErrorAction Stop # | Out-Null
        Write-Verbose "        The JSON file is valid." -Verbose
    } catch {
        Write-Error "The JSON file is not valid." -ErrorAction Stop
    }

    try {
        $Json | Test-Json -Schema $Schema -ErrorAction Stop # | Out-Null
        Write-Verbose "        The JSON file is compliant with the schema." -Verbose
    } catch {
        Write-Warning $_
        Write-Error "The JSON file is not compliant with the schema." -ErrorAction Stop
    }
    Write-Verbose "        Parsing policy definition..." -Verbose

    $policyProperties = $Json | ConvertFrom-Json | Select-Object -ExpandProperty properties
    if ($policyProperties.policyType -ne "Custom") {
        Write-Error "The 'policyType' attribute of the definition ""$($policyProperties.name)"" in the ""$($policy.VersionInfo.FileName)"" file must be 'Custom'. To proceed change the 'policyType' to 'Custom'!"
    }
    $policyObjects += $policyProperties

    if ($uniquePolicies.Keys -notcontains $policyProperties.name ) {
        $uniquePolicies.Add($policyProperties.name, $policy.VersionInfo.FileName)
    } else {
        $policyInQuestion = $policyProperties.name
        $conflictingPolicyPath = $uniquePolicies.$policyInQuestion
        Write-Error "There is more than one policy definition JSON that contains this definition: ""$($policyProperties.name)"". To proceed, resolve this conflict in the following files and run this configuration script again! File1: ""$conflictingPolicyPath"", File2: ""$($policy.VersionInfo.FileName)""" -ErrorAction Stop
    }

    Write-Verbose "" -Verbose

}
Write-Verbose "" -Verbose

#endregion


#region Check permissions

# Input RBAC role name(s) to be checked

$requiredRoleNames = @(
    "Resource Policy Contributor"
    "Owner"
)

Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
Write-Verbose "Getting the Object ID of the User / Service Principal..." -Verbose
Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose

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

    Write-Verbose "    The script is running on behalf of this User (Object ID): $objId"     -Verbose
} elseif ($account.Type -eq "ServicePrincipal") {
    $objId = (Get-AzADServicePrincipal -ApplicationId $account.Id).Id
    Write-Verbose "    The script is running on behalf of this Service Principal (Object ID): $objId" -Verbose
} else {
    Write-Error "Unknown/Unsupported type of the principal: $($account.Type), aborting the script !" -ErrorAction Stop
}

if ($CheckRbacPermissions -eq $true) {
    # Getting RBAC assignments on the specified scope
    Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
    Write-Verbose "Validating if the User / Service Principal has the required permissions to author Policies" -Verbose
    Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose

    Write-Verbose "    Getting RBAC assignments on the specified scope..." -Verbose

    if ( $PSBoundParameters.ContainsKey("ManagementGroupName") ) {
        $roleAssignments = Get-AzRoleAssignment -Scope "/providers/Microsoft.Management/managementGroups/$ManagementGroupName" -ErrorAction SilentlyContinue | Where-Object { $requiredRoleNames -contains $_.RoleDefinitionName }
    } elseif ( $PSBoundParameters.ContainsKey("SubscriptionId") ) {
        $roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId" -ErrorAction SilentlyContinue | Where-Object { $requiredRoleNames -contains $_.RoleDefinitionName }
    }


    # Checking the User/Service Principal authorization

    Write-Verbose "    Checking the User/Service Principal authorization..." -Verbose

    $returnStatus = $false

    foreach ($assignment in $roleAssignments) {
        if ($assignment.ObjectId -eq $objId) {
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
        Write-Verbose "    The User/Service Principal $($account.Id) is authorized to perform the required actions." -Verbose
        Write-Verbose "" -Verbose
        Write-Verbose "" -Verbose
    } else {
        Write-Error "The User/Service Principal $($account.Id) is not assigned to any of the required roles, aborting the script !" -ErrorAction Stop
    }

}
#endregion


#region Check existing policy definitions

# Getting Policy Definitions in the chosen scope of Azure
$params = @{ }
if ( $PSBoundParameters.ContainsKey("ManagementGroupName") ) {
    $params.Add("ManagementGroupName", $ManagementGroupName)
    Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
    Write-Verbose "Fetching existing custom Azure Policy Definitions from management group ""$ManagementGroupName""" -Verbose
    Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
    $existingCustomDefinitions = Get-AzPolicyDefinition @params -WarningAction SilentlyContinue | Where-Object { $_.Properties.policyType -eq "Custom" -and $_.ResourceId -like "*/providers/Microsoft.Management/managementGroups/$ManagementGroupName/providers/Microsoft.Authorization/policyDefinitions/*" }

} elseif ( $PSBoundParameters.ContainsKey("SubscriptionId") ) {
    $params.Add("SubscriptionId", $SubscriptionId)
    $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId -WarningAction SilentlyContinue
    Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
    Write-Verbose "Fetching existing custom Azure Policy Definitions from subscription $($subscription.Name) ($SubscriptionId)" -Verbose
    Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
    $existingCustomDefinitions = Get-AzPolicyDefinition @params -WarningAction SilentlyContinue | Where-Object { $_.Properties.policyType -eq "Custom" -and $_.ResourceType -eq "Microsoft.Authorization/policyDefinitions" -and $_.ResourceId -like "*/subscriptions/$SubscriptionId/providers/Microsoft.Authorization/policyDefinitions*" }
}

# Checking if any of the existing custom policy definitions have to be deleted
if ($null -ne $existingCustomDefinitions) {
    Write-Verbose "$($existingCustomDefinitions.count) custom policy definitions found in the chosen scope:" -Verbose
    Write-Verbose "" -Verbose

    $definitionsToDelete = @()
    foreach ($item in $existingCustomDefinitions) {
        if ($policyObjects.Name -notcontains $item.Name) {
            Write-Warning "Marked for deletion (not defined in JSON): $($item.Properties.displayName) - ($($item.PolicyDefinitionId)"
            $definitionsToDelete += $item
        } else {
            Write-Verbose "    $($item.Properties.displayName) - ($($item.PolicyDefinitionId)" -Verbose
        }
    }
} else {
    Write-Verbose "There are no custom policy definitions deployed in the selected scope in Azure." -Verbose
}

#endregion


#region Create/update policy definitions

# Create/update policy definitions
Write-Verbose "" -Verbose
Write-Verbose "" -Verbose
Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
Write-Verbose "Creating / updating policy definitions" -Verbose
Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose

foreach ($policyObject in $policyObjects) {

    # If policy mode was not defined, it should be defaulted to "All"
    if (-not $policyObject.mode) {
        $Mode = "All"
    } else {
        $Mode = $policyObject.mode
    }

    # Constructing policy definitions parameters for splatting
    $policyDefinitionConfig = @{
        Name        = $policyObject.name
        DisplayName = $policyObject.displayName
        Policy      = $policyObject.policyRule | ConvertTo-Json -Depth 100
        Parameter   = $policyObject.parameters | ConvertTo-Json -Depth 100
        Metadata    = $policyObject.metadata | ConvertTo-Json -Depth 100
        Mode        = $Mode
    }

    # Adding SubscriptionId or ManagementGroupName value (depending on the parameter set in use)
    $policyDefinitionConfig += $params

    # Add policy description if it's present in the definition file
    if ($policyObject.description) {
        $policyDefinitionConfig.Add("Description", $policyObject.description)
    }

    # Create/update policy definition with the above parameters

    # Creation scenario
    if (-not ($existingCustomDefinitions | Where-Object { $_.Name -eq $policyDefinitionConfig.Name })) {
        Write-Verbose "Creating policy definition ""$($policyDefinitionConfig.Name)"" - ($($policyDefinitionConfig.DisplayName))" -Verbose

        if ($PSCmdlet.ShouldProcess(("Policy definition [{0}]" -f $policyDefinitionConfig.Name), "New")) {
            $newPolicy = New-AzPolicyDefinition @policyDefinitionConfig -WarningAction SilentlyContinue

            # Check success
            if ($newPolicy.Name -eq $policyDefinitionConfig.Name) {
                Write-Verbose "" -Verbose
                Write-Verbose "    Policy definition successfully created." -Verbose
                Write-Verbose "__________________________________________________________" -Verbose
                $noOfDefinitionsCreated++

            }
            $newPolicy = $null
        }
    }
    # Update scenario
    else {
        Write-Verbose """$($policyDefinitionConfig.Name)"" - ($($policyDefinitionConfig.DisplayName)) already exists in Azure." -Verbose

        # Check if policy definition in Azure is the same as in the JSON file
        $matchingCustomDefinition = $existingCustomDefinitions | Where-Object { $_.Name -eq $policyDefinitionConfig.Name }
        $displayNameMatches = $matchingCustomDefinition.Properties.DisplayName -eq $policyDefinitionConfig.DisplayName
        $policyRuleMatches = ($matchingCustomDefinition.Properties.policyRule | ConvertTo-Json -Depth 100) -eq $policyDefinitionConfig.Policy
        $parameterMatches = ($matchingCustomDefinition.Properties.parameters | ConvertTo-Json -Depth 100) -eq $policyDefinitionConfig.Parameter
        $metadataMatches = ($matchingCustomDefinition.Properties.metadata | ConvertTo-Json -Depth 100).category -eq $policyDefinitionConfig.Metadata.category
        $modeMatches = $matchingCustomDefinition.Properties.Mode -eq $policyDefinitionConfig.Mode
        $descriptionMatches = $matchingCustomDefinition.Properties.description -eq $policyDefinitionConfig.description

        # Update policy definition in Azure if necessary
        if ( $displayNameMatches -and $policyRuleMatches -and $parameterMatches -and $metadataMatches -and $modeMatches -and $descriptionMatches) {
            Write-Verbose "    No changes are required" -Verbose
            Write-Verbose "__________________________________________________________" -Verbose
        } else {
            Write-Verbose "        The policy definition JSON file does not match the policy definition in Azure." -Verbose
            Write-Verbose "        Updating definition..." -Verbose

            if ($PSCmdlet.ShouldProcess(("Policy definition [{0}]" -f $policyDefinitionConfig.Name), "Update")) {
                $updatedPolicy = Set-AzPolicyDefinition @policyDefinitionConfig -WarningAction SilentlyContinue

                # Check success
                if ($updatedPolicy) {
                    Write-Verbose "" -Verbose
                    Write-Verbose "    Policy definition successfully updated." -Verbose
                    Write-Verbose "__________________________________________________________" -Verbose
                    $noOfDefinitionsModified++
                }
                $updatedPolicy = $null
            }
        }
    }

    Write-Verbose "" -Verbose

}
Write-Verbose "" -Verbose

#endregion


<#
#region Delete policy definitions

# Delete policy definitions that are not defined in any files within the policy definition root folder
if ($definitionsToDelete.count -gt 0) {
    if ($DeleteIfMarkedForDeletion.IsPresent) {
        Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
        Write-Verbose "Deleting policy definitions" -Verbose
        Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose

        foreach ($item in $definitionsToDelete) {
            Write-Warning "Deleting policy definition: $($item.Properties.displayName) - $($item.PolicyDefinitionId)"

            if ($PSCmdlet.ShouldProcess(("Policy definition [{0}]" -f $item.Properties.displayName), "Remove")) {
                $itemDeleted = Remove-AzPolicyDefinition -Id $item.PolicyDefinitionId -Force -Confirm:$false -WarningAction SilentlyContinue
                if ($itemDeleted) {
                    $noOfDefinitionsDeleted++
                    Write-Verbose "" -Verbose
                    Write-Verbose "        Policy definition successfully deleted from Azure." -Verbose
                    Write-Verbose "__________________________________________________________" -Verbose
                }
                Write-Verbose "" -Verbose
                $itemDeleted = $null
            }
        }
    } else {
        Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
        Write-Verbose "Policies marked for deletion" -Verbose
        Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
        Write-Warning "    The following policy definitions are not defined in any JSON files within the policy definitions folder provided. These should be deleted by running this script, using the ""-DeleteIfMarkedForDeletion"" switch."
        foreach ($item in $definitionsToDelete) {
            Write-Verbose "    $($item.Properties.displayName) - $($item.PolicyDefinitionId)" -Verbose
        }
        Write-Verbose "" -Verbose
    }
    Write-Verbose "" -Verbose
}

#endregion
#>

# Summary (stats)
Write-Verbose "-------------------------------------------------" -Verbose
Write-Verbose "Statistics:" -Verbose
Write-Verbose "-------------------------------------------------" -Verbose
Write-Verbose "Number of policy definitions created       : $noOfDefinitionsCreated" -Verbose
Write-Verbose "Number of policy definitions updated       : $noOfDefinitionsModified" -Verbose
Write-Verbose "Number of policy definitions to be deleted : $($definitionsToDelete.count)" -Verbose
Write-Verbose "Number of policy definitions deleted       : $noOfDefinitionsDeleted" -Verbose
Write-Verbose "" -Verbose