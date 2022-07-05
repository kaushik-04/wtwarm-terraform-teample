<#
.SYNOPSIS
    This script creates structured JSON file - assignments.json of Azure Policy(set) Assignments assigned on the given (Root) Management Group scope and below groups and subscriptions.
.DESCRIPTION
    This script creates structured JSON file - assignments.json of Azure Policy(set) Assignments assigned on the given (Root) Management Group scope and below groups and subscriptions.
    The script does NOT capture Policy Assignments on Resource Group level, if any are assigned.
    The script requires at least reader permissions on the selected scope (tenant Root group).
    The script requires and active Azure context (you need to be logged in to an Azure environment to be able to run it).
.PARAMETER OutputFilePath
    Path to the output file (assignments JSON file).
.PARAMETER RootManagementGroupName
    The ID of the AAD Tenant (GUID format). If not provided, the script will get it from the AZ context.
.PARAMETER SubscriptionDisplayNamesToExclude
    List of subscription display names that will be excluded from the resulted file.
.EXAMPLE
    .\Get-StructuredPolicyAssignments.ps1 -OutputFilePath './assignments.json'
.EXAMPLE
    .\Get-StructuredPolicyAssignments.ps1 -OutputFilePath './assignments.json' -RootManagementGroupName 12345678-1234-1234-1234-123456789012
.INPUTS
   <none>
.OUTPUTS
   <none>
.NOTES
    This script is designed to be run in Azure DevOps pipelines.
    Version:        1.0
    Creation Date:  2020-04-29
#>

param (

    [Parameter(Mandatory = $false,
        HelpMessage = "Path to the output file (assignments JSON file).")]
    [ValidatePattern("[.]json$", ErrorMessage = "Specify a valid json file path (must end with '.json')")]
    [string]$OutputFilePath = "./assignments.json",

    [Parameter(Mandatory = $false,
        HelpMessage = "The ID of the AAD Tenant (GUID format). If not provided, the script will get it from the AZ context.")]
    [string]$RootManagementGroupName,

    [Parameter(Mandatory = $false,
        HelpMessage = "List of subscription display names that will be excluded from the resulted file.")]
    [array]$SubscriptionDisplayNamesToExclude = @("Zugriff auf Azure Active Directory", "Kostenlose Testversion", "Azure Pass - Sponsorship")

)


#region Functions
#-------------------------------------------------------------------------------

function Get-UniquePolicyAssignmentsOnScope
{ 
    Param ( 
        [Parameter(Mandatory = $true)][String]$Scope
    )

    $policyAssignments = @()
    $policySetAssignments = @()

    Write-Host "Fetching policy assignments for scope $Scope"
    $policyAssignmentObjects = Get-AzPolicyAssignment -Scope $Scope -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Where-Object { $_.Properties.scope -eq "$Scope" }

    if (-not $policyAssignmentObjects)
    {
        # NOTE: Write-Output can not be used, because its output is then returned in the function Return variable
        Write-Host "    No explicitly assigned policies were found on the scope: $Scope"
        Write-Host ""
    }
    else
    {
        Write-Host "    Fetching details..."
        Write-Host ""
        foreach ($object in $policyAssignmentObjects)
        {

            $description = ""
            if ($object.Properties.description)
            {
                $description = $object.Properties.description
            }

            $notScopes = @()
            if ($object.Properties.notScopes)
            {
                $notScopes = $object.Properties.notScopes
            }

            $parameters = @{ }
            $parameterNames = @()
            if ($object.Properties.parameters)
            {
                $parameterNames = ($object.Properties.parameters | Get-Member | Where-Object { $_.MemberType -eq "NoteProperty" }).Name
            }
            
            foreach ($parameterName in $parameterNames)
            {
                $parameters.$parameterName = $object.Properties.parameters.$parameterName.value
            }
            

            $managedIdentity = [ordered]@{
                assignIdentity = $false
                location       = ""
            }
            if ($object.Identity)
            {

                $managedIdentity.assignIdentity = $true
                $managedIdentity.location = $object.Location
            }


            $policyAssignment = [ordered]@{
                
                name                  = $object.Name
                displayName           = $object.Properties.displayName
                description           = $description
                definitionId          = $object.Properties.policyDefinitionId
                definitionDisplayName = ""
                notScopes             = $notScopes
                enforcementMode       = $object.Properties.enforcementMode
                parameters            = $parameters
                managedIdentity       = $managedIdentity

            } 
            
            if ($policyAssignment.definitionId.Split('/') -contains "policyDefinitions")
            {
                $policyAssignment.definitionDisplayName = (Get-AzPolicyDefinition -Id $object.Properties.policyDefinitionId -WarningAction SilentlyContinue).Properties.displayName
                $policyAssignments = $policyAssignments + $policyAssignment
            }
            elseif ($policyAssignment.definitionId.Split('/') -contains "policySetDefinitions")
            {
                $policyAssignment.definitionDisplayName = (Get-AzPolicySetDefinition -Id $object.Properties.policyDefinitionId -WarningAction SilentlyContinue).Properties.displayName
                $policySetAssignments = $policySetAssignments + $policyAssignment
            }
            
        }

    }

    return @{

        policyAssignments    = $policyAssignments
        policySetAssignments = $policySetAssignments

    }
    
}


function Get-StructuredPolicyAssignments
{
    param (
        [Parameter(Mandatory = $true)][String]$RootGroupName
    )

    $managementGroup = Get-AzManagementGroup -GroupName $RootGroupName -expand -ErrorAction SilentlyContinue

    if (-not $managementGroup)
    {
        Write-Error "The Management Group $RootGroupName was not found or access to the scope is not provided !" -ErrorAction Stop
    }

    $scopeDisplayName = $managementGroup.DisplayName
    
    $policies = Get-UniquePolicyAssignmentsOnScope -Scope $managementGroup.Id

    if ($policies.policyAssignments)
    {
        $policyAssignments = $policies.policyAssignments
    }
    else
    {
        $policyAssignments = @()
    }


    if ($policies.policySetAssignments)
    {
        $policySetAssignments = $policies.policySetAssignments
    }
    else
    {
        $policySetAssignments = @()
    }


    $structureObject = [ordered]@{
        scope                = $managementGroup.Id
        scopeDisplayName     = $scopeDisplayName
        policyAssignments    = $policyAssignments
        policySetAssignments = $policySetAssignments
        children             = @()
    }

    
    if ($managementGroup.Children)
    {
        foreach ($child in $managementGroup.Children)
        {
            if ($child.Type -eq "/providers/Microsoft.Management/managementGroups")
            {
                $structureObject.children = $structureObject.children + (Get-StructuredPolicyAssignments -RootGroupName $child.Name)
            }
            elseif ($child.Type -eq "/subscriptions")
            {

                $scopeDisplayName = $child.DisplayName

                if ($scopeDisplayName -in $SubscriptionDisplayNamesToExclude)
                {
                    # This is to skip to process AAD Related Subscriptions, or other exceptions
                    Continue
                }

                $policies = Get-UniquePolicyAssignmentsOnScope -Scope $child.Id

                if ($policies.policyAssignments)
                {
                    $policyAssignments = $policies.policyAssignments
                }
                else
                {
                    $policyAssignments = @()
                }


                if ($policies.policySetAssignments)
                {
                    $policySetAssignments = $policies.policySetAssignments
                }
                else
                {
                    $policySetAssignments = @()
                }

                $structureObject.children = $structureObject.children + [ordered]@{
                    scope                = $child.Id
                    scopeDisplayName     = $scopeDisplayName
                    policyAssignments    = $policyAssignments
                    policySetAssignments = $policySetAssignments
                    children             = @()
                }
                
            }
             
        }

    }
    
    return $structureObject

}

#-------------------------------------------------------------------------------
#endregion Functions



#region Main
#-------------------------------------------------------------------------------

if ($RootManagementGroupName)
{
    $rootGroupName = $RootManagementGroupName
}
else
{
    $rootGroupName = (Get-AzContext).Tenant.Id    
}

$policyAssignmentsStructureObject = [ordered]@{

    root = @{ }
}

$policyAssignmentsStructureObject.root = Get-StructuredPolicyAssignments -RootGroupName $rootGroupName

Write-Host ""
Write-Host "Writing results to ""$OutputFilePath"""

$policyAssignmentsStructureObject | ConvertTo-Json -Depth 100 | Out-File $OutputFilePath

#-------------------------------------------------------------------------------
#endregion Main