# Requires -PSEdition Core

<#
.SYNOPSIS
    This script creates/updates/deletes Policy definitions in the management group or subscription it is running against.

    .DESCRIPTION
    The script supports creating policy definitions anywhere in the management group hierarchy and directly in the subscription.
    It dynamically handles "mode" and "description" attributes depending on their presence in the definition JSON.
    Tests whether a User/ServicePrincipal executing this script has the given RBAC role(s) assigned on the Management Group level or Subscription level.
    In case of RBAC roles assigned to AAD Groups, the function does not check nested AAD Groups, only direct Group members are considered
    Role Limitations: The code checks only the specific given RBAC role(s), and ignores whether higher role is assigned (Contributor, Owner, or custom role)

    .PARAMETER PolicyDefinitionRootFolder
    Path of the root folder containing the policy definitions.

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

function Set-PolicyDefinitions { 

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (

        [Parameter(Mandatory = $true,
            HelpMessage = "Path of the parameters file.")]
        [string]$ParametersFilePath
    )

    $noOfpolicyDefinitionCreated = 0
    $noOfpolicyDefinitionModified = 0

    $PolicyDefinitionSchemaFilePath = "$PSScriptRoot/policyDefinitionSchema.json"

    # Load the policy definition schema
    $Schema = Get-Content -Path $PolicyDefinitionSchemaFilePath -Raw -ErrorAction Stop

    # Reading Policy definitions from JSON files
    $policyFile = Get-Item -Path $ParametersFilePath

    # Check if the root folder contains JSON files
    Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
    Write-Verbose "Looking for policy definition in the JSON provided ($($policyFile.Name))." -Verbose
    Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
    
    Write-Verbose "" -Verbose
    Write-Verbose "" -Verbose

    # Getting Policy definitions from the JSON files
    Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
    Write-Verbose "Reading Policy definition from the JSON file" -Verbose
    Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose

    # Check if the policy definition JSON file is a valid JSON
    $Json = Get-Content -Path $policyFile.VersionInfo.FileName -Raw -ErrorAction Stop

    Write-Verbose "    $($policyFile.Name) - $($policyFile.VersionInfo.FileName)" -Verbose

    try {
        $Json | Test-Json -ErrorAction Stop # | Out-Null
        Write-Verbose "        The JSON file is valid." -Verbose
    }
    catch {
        Write-Error "The JSON file is not valid." -ErrorAction Stop
    }

    $jsonParameters = ($Json | ConvertFrom-Json).parameters

    try {
        $jsonParameters | ConvertTo-Json -Depth 100 | Test-Json -Schema $Schema -ErrorAction Stop # | Out-Null
        Write-Verbose "        The JSON file is compliant with the schema." -Verbose
    }
    catch {
        Write-Warning $_
        Write-Error "The JSON file is not compliant with the schema." -ErrorAction Stop
    }
    Write-Verbose "        Parsing policy definition..." -Verbose

    $policyScope = $jsonParameters.scope.value
    $policyProperties = $jsonParameters.properties.value
    if ($policyProperties.policyType -ne "Custom") {
        Write-Error "The 'policyType' attribute of the definition ""$($policyProperties.name)"" in the ""$($policyFile.VersionInfo.FileName)"" file must be 'Custom'. To proceed change the 'policyType' to 'Custom'!"
    }

    Write-Verbose "" -Verbose

    #endregion

    #region Create/update policy definitions

    # Create/update policy definitions
    Write-Verbose "" -Verbose
    Write-Verbose "" -Verbose
    Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose
    Write-Verbose "Creating / updating policy definitions" -Verbose
    Write-Verbose "-------------------------------------------------------------------------------------------------------------------" -Verbose

    $params = @{ }
    if ( $policyScope -match "/providers/Microsoft.Management/managementGroups/" ) {
        $ManagementGroupName = $policyScope.split("/")[-1]
        $params.Add("ManagementGroupName", $ManagementGroupName)
        $existingCustomDefinitions = Get-AzPolicyDefinition @params -WarningAction SilentlyContinue | Where-Object { $_.Properties.policyType -eq "Custom" -and $_.ResourceId -like "*/providers/Microsoft.Management/managementGroups/$ManagementGroupName/providers/Microsoft.Authorization/policyDefinitions/*" }
    }
    elseif ( $policyScope -match "/subscriptions/" ) {
        $SubscriptionId = $policyScope.split("/")[-1]
        $params.Add("SubscriptionId", $SubscriptionId)
        $existingCustomDefinitions = Get-AzPolicyDefinition @params -WarningAction SilentlyContinue | Where-Object { $_.Properties.policyType -eq "Custom" -and $_.ResourceType -eq "Microsoft.Authorization/policyDefinitions" -and $_.ResourceId -like "*/subscriptions/$SubscriptionId/providers/Microsoft.Authorization/policyDefinitions*" }
    }

    # If policy mode was not defined, it should be defaulted to "All"
    if (-not $policyProperties.mode) {
        $Mode = "All"
    }
    else {
        $Mode = $policyProperties.mode
    }

    # Constructing policy definitions parameters for splatting
    $policyDefinitionConfig = @{
        Name        = $policyProperties.name
        DisplayName = $policyProperties.displayName
        Policy      = $policyProperties.policyRule | ConvertTo-Json -Depth 100
        Parameter   = $policyProperties.parameters | ConvertTo-Json -Depth 100
        Metadata    = $policyProperties.metadata | ConvertTo-Json -Depth 100
        Mode        = $Mode
    }

    # Adding SubscriptionId or ManagementGroupName value (depending on the parameter set in use)
    $policyDefinitionConfig += $params

    # Add policy description if it's present in the definition file
    if ($policyProperties.description) {
        $policyDefinitionConfig.Add("Description", $policyProperties.description)
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
                $noOfpolicytionsCreated++

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
        }
        else {
            Write-Verbose "        The policy definition JSON file does not match the policy definition in Azure." -Verbose
            Write-Verbose "        Updating definition..." -Verbose

            if ($PSCmdlet.ShouldProcess(("Policy definition [{0}]" -f $policyDefinitionConfig.Name), "Update")) {
                $updatedPolicy = Set-AzPolicyDefinition @policyDefinitionConfig -WarningAction SilentlyContinue

                # Check success
                if ($updatedPolicy) {
                    Write-Verbose "" -Verbose
                    Write-Verbose "    Policy definition successfully updated." -Verbose
                    Write-Verbose "__________________________________________________________" -Verbose
                    $noOfpolicyDefinitionModified++
                }
                $updatedPolicy = $null
            }
        }
    }

    Write-Verbose "" -Verbose

    Write-Verbose "" -Verbose

    #endregion

    # Summary (stats)
    Write-Verbose  "-------------------------------------------------" -Verbose
    Write-Verbose  "Statistics:" -Verbose
    Write-Verbose  "-------------------------------------------------" -Verbose
    Write-Verbose  "Number of Initiative definitions created       : $noOfpolicyDefinitionCreated" -Verbose
    Write-Verbose  "Number of Initiative definitions updated       : $noOfpolicyDefinitionModified" -Verbose
    Write-Verbose  "" -Verbose
}