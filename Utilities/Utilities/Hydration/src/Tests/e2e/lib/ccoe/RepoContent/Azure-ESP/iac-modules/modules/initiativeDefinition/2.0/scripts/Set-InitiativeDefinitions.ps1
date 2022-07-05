#Requires -PSEdition Core

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

.PARAMETER DeleteIfMarkedForDeletion
    Optional. When using this switch, the script deletes all PolicySet definitions from Azure that are not included somewhere within the PolicySet definition root folder.

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

function Set-InitiativeDefinitions {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (

        [Parameter(Mandatory = $true,
            HelpMessage = "Path to the initiative definition file.")]
        [string]$ParameterFilePath

    )

    # Initialize counters
    $noOfPolicySetCreated = 0
    $noOfPolicySetModified = 0

    $InitiativeDefinitionSchemaFilePath = "$PSScriptRoot/initiativeDefinitionSchema.json"

    #region Get/check JSON files

    # Load the PolicySet definition schema
    $Schema = Get-Content -Path $InitiativeDefinitionSchemaFilePath -Raw -ErrorAction Stop

    # Reading PolicySet definitions from JSON files
    $policySet = Get-Item -Path $ParameterFilePath

    # Check if the root folder contains JSON files
    Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose
    Write-Verbose  "Looking for initiative definition in the JSON provided ($($policySet.Name))." -Verbose
    Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose

    Write-Verbose "" -Verbose
    Write-Verbose "" -Verbose

    # Getting PolicySet definitions from the JSON files
    Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose
    Write-Verbose  "Reading Initiative definitions from the JSON file" -Verbose
    Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose

    # Check if the policySet definition JSON file is a valid JSON
    $Json = Get-Content -Path $policySet.VersionInfo.FileName -Raw -ErrorAction Stop

    Write-Verbose  "    $($policySet.Name) - $($policySet.VersionInfo.FileName)" -Verbose

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
    Write-Verbose  "        Parsing Initiative definition..." -Verbose

    $policyScope = $jsonParameters.scope.value
    $policySetObject = $jsonParameters.properties.value


    #endregion


    #region Check permissions

    #region Check existing policy definitions

    #region Create/update policySet definitions

    # Create/update policySet definitions
    Write-Verbose  "" -Verbose
    Write-Verbose  "" -Verbose
    Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose
    Write-Verbose  "Creating / updating Initiative definitions" -Verbose
    Write-Verbose  "-------------------------------------------------------------------------------------------------------------------" -Verbose

    $params = @{ }
    if ( $policyScope -match "/providers/Microsoft.Management/managementGroups/" ) {
        $ManagementGroupName = $policyScope.split("/")[-1]
        $params.Add("ManagementGroupName", $ManagementGroupName)
        $existingCustomDefinitions = Get-AzPolicySetDefinition @params -WarningAction SilentlyContinue | Where-Object { $_.Properties.policyType -eq "Custom" -and $_.ResourceId -like "*/providers/Microsoft.Management/managementGroups/$ManagementGroupName/providers/Microsoft.Authorization/policySetDefinitions/*" }
        $existingPolicyDefinitions = Get-AzPolicyDefinition @params -WarningAction SilentlyContinue

    }
    elseif ( $policyScope -match "/subscriptions/" ) {
        $params.Add("SubscriptionId", $SubscriptionId)
        $SubscriptionId = $policyScope.split("/")[-1]
        $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId -WarningAction SilentlyContinue
        $existingCustomDefinitions = Get-AzPolicySetDefinition @params -WarningAction SilentlyContinue | Where-Object { $_.Properties.policyType -eq "Custom" -and $_.ResourceType -eq "Microsoft.Authorization/policySetDefinitions" -and $_.ResourceId -like "*/subscriptions/$SubscriptionId/providers/Microsoft.Authorization/policySetDefinitions*" }
        $existingPolicyDefinitions = Get-AzPolicyDefinition @params -WarningAction SilentlyContinue
    }
    

    # Constructing policySet definitions parameters for splatting

    # preserver array also when just 1 item
    if ( (($policySetObject.policyDefinitions).Length) -eq 1) {
        # if array lenght is 1 ConvertTo-Json removes array brackets []
        $PolicyDefinitionBody = "[" + ($policySetObject.policyDefinitions | ConvertTo-Json -Depth 100) + "]"
    }
    else {
        $PolicyDefinitionBody = ($policySetObject.policyDefinitions | ConvertTo-Json -Depth 100)
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
                $noOfPolicySetCreated++
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
                    $noOfpolicySetModified++
                }
                $updatedPolicySet = $null
            }
        }
    }

    Write-Verbose  "" -Verbose


    Write-Verbose  "" -Verbose

    #endregion


    # Summary (stats)
    Write-Verbose  "-------------------------------------------------" -Verbose
    Write-Verbose  "Statistics:" -Verbose
    Write-Verbose  "-------------------------------------------------" -Verbose
    Write-Verbose  "Number of Initiative definitions created       : $noOfpolicySetCreated" -Verbose
    Write-Verbose  "Number of Initiative definitions updated       : $noOfpolicySetModified" -Verbose
    Write-Verbose  "" -Verbose
}
