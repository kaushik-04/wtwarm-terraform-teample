[[_TOC_]]

# Policy Assignments

This page describes how **Policy** and **Initiative Assignments** are handled by the Policy-as-Code framework.

> **WARNING**: Be aware, that **built-in initiatives can be modified** anytime by Microsoft. This is out of your control. So, policies might get added, removed or modified in an existing initiative. This will have direct impact on your assignments. Especially, if modify or deployIfNotExists policies are added, this could break your environment.
> Therefore, if you would like to avoid any undesired effects, **clone built-in initiatives** before assigning them.

Watch changes of built-in initiatives and update your clones accordingly using tools like [AzPolicyAdvertizer](https://www.azadvertizer.net/azpolicyadvertizer_history.html) (by Julian Hayward)

> **NOTE**: While the Azure portal groups Policies to '_Initiatives_', the APIs refer to the same concept by using the '_PolicySet_' terminology. **Initiatives and PolicySets are the same thing.**

The components required for **creating / updating / deleting Policy assignments and Policy set (initiative) assignments** are the followings:

| Component | What is it used for? | Where can it be found? |
|--|--|--|
| **Assignment configuration script** | This script is used for creating / updating / deleting Policy and Initiative assignments in Azure. These assignments can be defined with the scope of a Management Group / Subscription / Resource Group. | `/Policy/PolicyAssignments/1.0.0/Set-PolicyAssignments.ps1` |
| **Assignment Schema** | This schema defines the structure of the assignments JSON file. The assignment file is tested against the schema when the configuration script is run. | `/Policy/PolicyAssignments/1.0.0/assignmentSchema.json` |
| **Assignment JSON file** | The assignments JSON file follows the management group hierarchy (optionally including subscriptions and resource groups) and defines all policy and initiative assignments on these scopes. | A JSON file located in the parameter repositories which consume this component. An example can be found here `/Policy/PolicyAssignments/1.0.0/Parameters/` |
| **Assignments Pipeline** | The pipeline invokes the assignment configuration script that assigns pre-staged (built-in or custom) policy and initiative definitions to the scopes provided. For validation purposes, the pipeline file in this component is set to trigger on any changes of the PolicyAssignments folder. | In any subfolder for the parameter repositories which consume this component. An example can be found under `/Policy/PolicyAssignments/1.0.0/Pipeline`. |

## Scenarios

The Policy-as-Code framework supports the following Policy and Initiative assignment scenarios:

- **Centralized approach**: One centralized team manages all policy and initiative assignments in the Azure organization, at all levels (Management Group, Subscription, Resource Group).
- **Distributed approach**: Multiple teams can also manage policy and initiative assignments in a distributed manner if there's a parallel set Management Group hierarchies defined. In this case individual teams can have their own top level Management group (and corresponding Management Groups hierarchy with Subscriptions and Resource Groups below), but assignments must not be made on the Tenant Root Group level.
  > **NOTE**: Distributed teams must only include those scopes in their version of the assignments.json that is not covered by another team.
- **Mixed approach**: A centralized team manages policy and initiative assignments to a certain level (top-down approach), e.g. on the Tenant Root Group level, and top level Management group, and all assignments on lower levels (i.e. lower level Management Groups, Subscriptions and Resource Groups) are managed by multiple teams, in a distributed manner.

  > **NOTE**: When using the mixed approach, scopes that will not be managed by the central team should be excluded from (not mentioned in) the assignments JSON file - therefore the assignment configuration script will ignore these scopes (it won't add/remove/update anything in there). At the same time, the distributed teams must only include those scopes in their version of the assignments.json that is not covered by the central team.

## Assignment JSON file structure

``` json
{
    "root": {
        "scope": "/providers/Microsoft.Management/managementGroups/<tenantRootGroup>",
        "policyAssignments": [],
        "policySetAssignments": [],
        "children": [
            {
                "scope": "/providers/Microsoft.Management/managementGroups/<managementGroup1>",
                "policyAssignments": [],
                "policySetAssignments": [],
                "children": []
            },
            {
                "scope": "/providers/Microsoft.Management/managementGroups/<managementGroup2>",
                "policyAssignments": [],
                "policySetAssignments": [],
                "children": [
                    {
                        "scope": "/providers/Microsoft.Management/managementGroups/<managementGroup2A>",
                        "policyAssignments": [],
                        "policySetAssignments": [],
                        "children": [
                            {
                                "scope": "/subscriptions/<subscriptionId>",
                                "policyAssignments": [],
                                "policySetAssignments": [],
                                "children": []
                            }
                        ]
                    },
                    {
                        "scope": "/providers/Microsoft.Management/managementGroups/<managementGroup1B>",
                        "policyAssignments": [],
                        "policySetAssignments": [],
                        "children": []
                    }
                ]
            }
        ]
    }
}
```

### Structural rules

- The assignments JSON file has to have a `root` element.
- In every single level of the assignments JSON, the following 4 elements have to be present: `[string]scope`, `[array]policyAssignments`, `[array]policySetAssignments`, `[array]children` .
- Scopes can be nested, by using the `children` element. Nested scopes have to contain the above listed 4 elements recursively. The schema doesn't constrain any limitations on depth, but Management groups can only be nested up to 6 levels (+ subscription + resource group level) - therefore there's a 'natural' limit of maximum 8 levels.
- The `policyAssignments` and `policySetAssignments` elements share identical schema - see below.

### Scope and notScope (exclusion) examples

| Scope | Usage | Example |
|--|--|--|
| Management group | `scope` / `notScope` | `/providers/Microsoft.Management/managementGroups/<managementGroupId>` |
| Subscription | `scope` / `notScope` | `/subscriptions/<subscriptionId>` |
| Resource Group | `scope` / `notScope` | `/subscriptions/<subscriptionId>/resourceGroups/<resourceGroupName>` |
| Resource | `notScope` | `/subscriptions/<subscriptionId>/resourceGroups/<resourceGroupName>/providers/Microsoft.KeyVault/vaults/<resourceName>` |

### Policy and Initiative (Policy Set) assignment schema

> **NOTE**: The schema for policyAssignments and policySetAssignments is the same.

```json
"policyAssignments": [
    {
        "name": "AuditKeyVaultLocation",
        "displayName": "Audit Key Vault Location",
        "description": "Audit Key Vault Location",
        "definitionId": "/providers/Microsoft.Management/managementGroups/<tenantRootGroupId>/providers/Microsoft.Authorization/policyDefinitions/AuditKeyVaultLocation",
        "definitionDisplayName": "Audit Key Vault Location",
        "notScopes": [
            "/subscriptions/<subscriptionId>/resourceGroups/<resourceGroupName>/providers/providers/Microsoft.KeyVault/vaults/<resourceName>"
        ],
        "enforcementMode": "Default",
        "parameters": {
            "allowedLocation": [
                "westeurope",
                "northeurope"
            ]
        },
        "managedIdentity": {
            "assignIdentity": false,
            "location": ""
        }
    }
],
"policySetAssignments": []
```

## Assignment configuration script

The `Set-PolicyAssignments.ps1` script creates / updates / deletes Policy and Initiative assignments in Azure.

This script is **declarative** and **idempotent**: this means, that regardless how many times it is run, it always pushes all changes from the assignments JSON file to the Azure environment, i.e. if an element in the JSON file is newly created/updated/deleted, the pipeline will create/update/delete the Policy/Initiative assignment in Azure. If there are no changes, the pipeline can be run any number of times, as it won't make any changes to Azure.

With other words, **the assignments JSON file within the parameter repository is the 'single source of truth'** for Policy and Initiative Assignments.

## Assignments pipeline

To use the script in a pipeline deployment, configure steps to run the Policy/Initiative Assignments configuration script (`Set-PolicyAssignments.ps1`) with the below parameters.

The pipeline runs on behalf of a Service Principal that has **Owner** permissions on the applicable scope.

> **NOTE**: Alternatively, '_Resource Policy Contributor_' permissions could be enough if Policies with DeployIfNotExists or Modify action wouldn't be used.

| Parameter | Value | Explanation |
|--|--|--|
| `AssignmentFilePath` | \$(Build.Repository.LocalPath)/\$(PolicyAssignmentsParameterPath)/assignments.json | Path to the assignments JSON file. |
| `AssignmentSchemaPath` | \$(Build.Repository.LocalPath)/\$(PolicyAssignmentsPath)/assignmentSchema.json | Path to the assignments JSON schema. |
| `DeleteIfMarkedForDeletion` | \<isPresent\> | When this switch is used, RBAC permissions are checked for all scopes. When not in use, only the root scope is checked. |

## Known issues, limitations

- The script doesn't handle modification of the DefinitionId attribute (doesn't react on the DefinitionId changed).
- The assignments JSON has one root, therefore if you had 2 subscriptions to manage (e.g. distributed management scenario), you would need to have 2 assignments files and a 2 step pipeline defined.
- In case of DeployIfNotExists or Modify scenarios, having only the assignIdentity set to true, won't do anything - you must provide the location for the managed service identity (MSI) as well.
- Once a policy with an assigned identity has been assigned, the assigned identity can only be deleted, when the assignment is deleted.

## Tested scenarios / Error handling

| # | Category | Test scenario | Outcome |
|----|----|----|----|
| 1 | JSON | JSON file is present | Error thrown, as expected. |
| 2 | JSON | Invalid JSON file ('{' removed from the first line) | Error thrown, as expected. |
| 3 | JSON | JSON file is compliant with the schema - removed some mandatory elements | Error thrown, as expected. |
| 4 | RBAC | Validate RBAC permissions on various scopes | Error thrown, as expected. For the final full assignments file it takes ~5 minutes to validate all RBAC permissions. To speed up the script, the 'SkipRbacValidation' parameter can be used to skip the RBAC tests. |
| 5 | Create assignment | Creation of new assignment with notScopes, parameters | Assignment created successfully. |
| 6 | Create assignment | Bulk add assignments | Assignments successfully added. |
| 7 | Update assignment | Name | Assignment removed and a new one created with the name name as expected. |
| 8 | Update assignment | DisplayName | Assignment displayName updated successfully. |
| 9 | Update assignment | Description | Assignment description updated successfully. |
| 10 | Update assignment | DefinitionId | Unexpected behavior, the script doesn't handle this scenario (doesn't react on the definitionId changed). |
| 11 | Update assignment | Add/remove notScopes | Assignment notScope updated successfully in both cases. |
| 12 | Update assignment | EnforcementMode | Assignment EnforcementMode updated successfully. |
| 13 | Update assignment | ManagedIdentity | Managed identity can be added after deployment, but cannot be removed (as expected). |
| 14 | Update assignment | Bulk modify assignments | Multiple assignments can be successfully modified as expected. |
| 15 | Remove assignment | Remove assignment from scope | Assignment removed as expected. |
| 16 | Remove assignment | Bulk remove assignments from scope | Assignments successfully removed. |
| 17 | Parameters | Define/modify/remove string parameter | Adding/modifying/removing the effect parameter value was successful. |
| 18 | Parameters | Define/modify/remove array parameter | Adding/modifying/removing the allowedLocation parameter value was successful. |
| 19 | Parameters | Define/modify/remove integer parameter | Adding/modifying/removing the myInteger parameter value was successful. |
| 20 | Parameters | Define/modify/remove object parameter | Adding/modifying/removing the myObject parameter value was successful. |
| 21 | Parameters | Define/modify/remove boolean parameter | Adding/modifying/removing the myBoolean parameter value was successful. |
| 22 | Parameters | Define/modify/remove datetime parameter | Adding/modifying/removing the myDatetime parameter value was successful. |
| 23 | Parameters | Define/modify/remove string attribute in object | Adding/modifying/removing string attribute value in the object parameter was successful. |
| 24 | Parameters | Define/modify/remove array attribute in object | Adding/modifying/removing array attribute value in the object parameter was successful. |
| 25 | Parameters | Define/modify/remove integer attribute in object | Adding/modifying/removing integer attribute value in the object parameter was successful. |
| 26 | Parameters | Define/modify/remove object attribute in object | Adding/modifying/removing object attribute value in the object parameter was successful. |
| 27 | Parameters | Define/modify/remove boolean attribute in object | Adding/modifying/removing boolean attribute value in the object parameter was successful. |
| 28 | Parameters | Define/modify/remove datetime attribute in object | Adding/modifying/removing datetime attribute value in the object parameter was successful. |
| 29 | Parameters | Missing parameter values when the definitions doesn't have a default value | Error thrown, as expected. |
| 30 | Parameters | Bulk adding/modifying/removing multiple parameters at a time | Works as expected: multiple parameters can be successfully modified. |
| 31 | Child scopes | Add child scope with assignment | Works as expected: creates assignment. |
| 32 | Child scopes | Add assignment to child scope | Works as expected: creates assignment. |
| 33 | Child scopes | Remove assignment from child scope | Works as expected: deletes assignment. |
| 34 | Child scopes | Removing child scope | Works as expected: doesn't have any impact, the removed scope is ignored by the script. |
| 35 | Child scopes | Add/update/remove subscription scope with assignment | Works as expected. |
| 36 | Child scopes | Add/update/remove resource group scope with assignment | Works as expected. |
| 37 | Modify Effect| Create policy assignment with "modify" effect having RBAC assignment | assignment (incl RBAC) creation worked |
| 38 | Modify Effect| Delete policy assignment with "modify" effect having RBAC assignment | assignment (incl RBAC) removal worked |
| 39 | deployIfNotExist | Create policy assignment with deployIfNotExist | Works as expected: creates assignment |
| 40 | deployIfNotExist | Update policy assignment with deployIfNotExist | Works as expected: updates assignment |
| 41 | deployIfNotExist | Delete policy assignment with deployIfNotExist | Works as expected: creates assignment |
| 42 | Modify Effect | Create initiative with 2 policies having each 1 role definition and assign it | Works as expected: creates assignment |
| 43 | deployIfNotExist | Update policy assignment with deployIfNotExist using different role definition (also tested with custom role definitions) | Works as expected: assignment updated. |
| 44 | Modify Effect | Create policy with 2 role definitions and assign it | Works as expected: assignment (incl RBAC) created |
| 45 | Modify Effect | Update policy with 2 role definitions by removing 1 role definition | Works as expected: assignment (incl RBAC removal) updated |
| 46 | Modify Effect | Update policy with 1 role definitions by adding another role definition | Works as expected: assignment (incl added RBAC ) updated |
| 47 | deployIfNotExist | Create policy with 2 role definitions and assign it | Works as expected: assignment (incl RBAC) created |
| 48 | deployIfNotExist | Update policy with 2 role definitions by removing 1 role definition | Works as expected: assignment (incl RBAC removal) updated |
| 49 | deployIfNotExist | Update policy with 1 role definitions by adding another role definition | Works as expected: assignment (incl added RBAC ) updated |

> **NOTES**

- All tests have been executed for assignments (policies) and assignmentSets (initiatives)
- Idempotency has been tested, i.e. not changing any values results no changes (= the script can be run unlimited number of times).
- Changes of definitions that are already assigned have been tested and documented on the definitions page

## Policy Assignment polling script - Get-StructuredPolicyAssignments.ps1

When setting up the Policy-as-Code environment, based on this framework, you may find yourself in a situation, that you have a complex management group / subscription hierarchy that already has a lot of assigned policies and initiatives. In this case you can run the `Get-StructuredPolicyAssignments.ps1` script to have the existing assignments fetched, and saved to the `assignments.json` file, which you can use as a starting point to feed this framework. (This file will be produced in the format the frameworks needs it in.)

To use this script, navigate to the `Assignments` folder of the `Policies` repository, and run the `Get-StructuredPolicyAssignments.ps1` script.

> **NOTE**:
>
> If you run the script without any parameters provided, it will collect all the policy and initiative assignment all the way from the Tenant Root Group, to the subscription level.
>
>To find more information about the available parameters run the following command: `Get-Help .\Get-StructuredPolicyAssignments.ps1 -Full`
