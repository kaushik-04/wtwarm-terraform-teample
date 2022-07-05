# Requires -PSEdition Core

<#
.SYNOPSIS
    This script creates/updates/deletes Policy and Policy Set (Initiative) assignments in management groups, subscriptions or resource groups, based on the provided assignment.json file.
.DESCRIPTION
    The script supports assigning policy definitions anywhere in the management group hierarchy, directly in the subscriptions or resource gruops.

    Tests whether a User/ServicePrincipal executing this script has the given RBAC role(s) assigned on the Management Group level or Subscription level.
    In case of RBAC roles assigned to AAD Groups, the function does not check nested AAD Groups, only direct Group members are considered
    Role Limitations: The code checks only the specific given RBAC role(s), and ignores whether higher role is assigned (Contributor, Owner, or custom role)
.PARAMETER ParametersFilePath
    Path to the assignments JSON file.
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

function Set-PolicyAssignments {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true,
            HelpMessage = "Path to the assignments JSON file.")]
        [string]$ParametersFilePath,

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

    $AssignmentSchemaPath = "$PSScriptRoot/assignmentSchema.json"

    # Load the policy definition schema
    $Schema = Get-Content -Path $AssignmentSchemaPath -Raw -ErrorAction Stop

    # Reading Policy definitions from JSON files
    $assignmentFile = Get-Item -Path $ParametersFilePath

    #region Get/check JSON files

    Write-Output "-------------------------------------------------------------------------------------------------------------------"
    Write-Output "Looking for the Assignment JSON file ($($assignmentFile.Name))"
    Write-Output "-------------------------------------------------------------------------------------------------------------------"


    # Check if the JSON file has content
    $Json = Get-Content -Path $assignmentFile.VersionInfo.FileName -Raw -ErrorAction Stop

    Write-Output "    $($assignmentFile.Name) - $($assignmentFile.VersionInfo.FileName)"

    try {
        $Json | Test-Json -ErrorAction Stop
        Write-Output "        The JSON file is valid."
    }
    catch {
        Write-Error "The JSON file is not valid." -ErrorAction Stop
    }

    $jsonParameters = ($Json | ConvertFrom-Json).parameters

    try {
        $jsonParameters | ConvertTo-Json -Depth 100 | Test-Json -Schema $Schema -ErrorAction Stop
        Write-Output "        The JSON file is compliant with the schema."
    }
    catch {
        Write-Warning $_
        Write-Error "The JSON file is not compliant with the schema." -ErrorAction Stop
    }

    $assignmentScope = $jsonParameters.scope.value
    $assignmentProperties = $jsonParameters.properties.value

    if ($assignmentScope -like "*managementGroups*") {
        $ManagementGroupName = ($assignmentScope -split "/")[-1]
        $scopeDisplayName = $ManagementGroupName
        $DefinitionsInScope = Get-AzPolicyDefinition -ManagementGroupName $ManagementGroupName
        $DefinitionsInScope += Get-AzPolicySetDefinition -ManagementGroupName $ManagementGroupName
    }
    elseif ($assignmentScope -like "*subscriptions*") {
        $SubscriptionId = ($assignmentScope -split "/")[-1]
        $Subscription = Get-AzSubscription -SubscriptionId $SubscriptionId
        $scopeDisplayName = $Subscription.Name
        $DefinitionsInScope = Get-AzPolicyDefinition -SubscriptionId $SubscriptionId
        $DefinitionsInScope += Get-AzPolicySetDefinition -SubscriptionId $SubscriptionId
    }

    #region Process assignments JSON

    # Getting
    $Identity = Get-Identity

    # Checking RBAC permissions
    if (-not $SkipRbacValidation.IsPresent) {
        Test-RbacPermissions -Identity $Identity -AssignmentObject $jsonParameters -CheckRbacPermissionsForAllScopes $CheckRbacPermissionsForAllScopes
    }

    Write-Output ""
    Write-Output ""
    Write-Output "-------------------------------------------------------------------------------------------------------------------"
    Write-Output "Processing assignments in the JSON file"
    Write-Output "-------------------------------------------------------------------------------------------------------------------"
    Write-Output "        $assignmentScope"
    Write-Output ""
    Write-Output ""

    # PROCESSING assignments JSON
    if ($jsonParameters) {
        Set-AssignmentsInJson -InputObject $jsonParameters
    }

    # Summary (stats)
    # Write-Output "======================================================================================================================="
    # Write-Output "Statistics:"
    # Write-Output "======================================================================================================================="
    # Write-Output "Number of assignments created       : $noOfAssignmentsCreated"
    # Write-Output "Number of assignments updated       : $noOfAssignmentsUpdated"
    # Write-Output "Number of assignments to be deleted : $noOfAssignmentsToDelete"
    # Write-Output "Number of assignments deleted       : $noOfAssignmentsDeleted"
    # Write-Output ""
    # Write-Output "Number of _RBAC role assignments created_ for new policy/initative assignments      : $noOfRoleAssignmentsCreated"
    # Write-Output "Number of _RBAC role assignments changed_ for existing policy/initative assignments : $noOfRoleAssignmentsChanged"
    # Write-Output "Number of _RBAC role assignments deleted_ for existing policy/initative assignments : $noOfRoleAssignmentsRemoved"
    # Write-Output ""
    # Write-Output "Tip: if you want to find where the above changes have happened, search for the highlighted words between the '_' signes in this log - e.g. 'RBAC role assignments deleted'"
    # Write-Output ""
    #endregion Process assignments JSON
}