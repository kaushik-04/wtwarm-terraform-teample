[[_TOC_]]

# Policy Definitions

This chapter describes how Policy Definitions are handled by the Policy-as-Code framework.

## How to use the component

To use this component, use the pipeline template file located `.\pipeline\pipeline.jobs.deploy.yml`.

The template yml has the following parameters:

| Parameter                       | datatype      | allowed values                                                                                                               | default value                        | Description                                                       |
| ------------------------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ----------------------------------------------------------------- |
| serviceConnection               | string        | *                                                                                                                            | '$(serviceConnection)'               | Name of the ARM service connection that the deployment will use   |
| managementGroupId               | string        | *                                                                                                                            | '$(managementGroupId)'               | Name of management group to target for the deployment             |
| poolName                        | string        | *                                                                                                                            | '$(poolName)'                        | Name of the self hosted pool to run this job in                   |
| vmImage                         | string        | [Microsoft-hosted agents](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops&tabs=yaml) | '$(vmImage)'                         | Name of the VM image in the Microsoft-hosted pool you want to use |
| moduleName                      | string        | *                                                                                                                            | 'policyDefinition'                   | Name of the component                                             |
| moduleVersion                   | string        | *                                                                                                                            | '1.1'                                | Version of the component                                          |
| policyDefinitionsPath           | string        | *                                                                                                                            | ''                                   | Path to the folder containing initiative definitions              |
| defaultJobTimeoutInMinutes      | number        | *                                                                                                                            | 120                                  | How long to run the job before automatically cancelling           |
| checkoutRepositories            | list(strings) | *                                                                                                                            | ''                                   | Name of additional repos to checkout/download in the pipeline     |
| dependsOn                       | list(strings) | *                                                                                                                            | []                                   | A list of stages/jobs to run before this                          |
| parametersRepository            | string        | *                                                                                                                            | '$(Build.Repository.Name)'           | The repository that holds parameters for the deployment           |
| azurePowerShellVersion          | string        | 'latestVersion', 'otherVersion'                                                                                              | '$(azurePowerShellVersion)'          | Powershell version to run this tasks on                           |
| preferredAzurePowerShellVersion | string        | * [more info](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/azure-powershell?view=azure-devops)       | '$(preferredAzurePowerShellVersion)' | Specify if azurePowerShellVersion is 'otherVersion'               |

This is an example of how to use the deploy template for policyDefinition from the IaC repo.

```yml
stages:
- stage: Deploy
  jobs:
  - template: /modules/policyDefinition/1.1/pipeline/pipeline.jobs.deploy.yml
    parameters:
      serviceConnection: "pxs-cloudnative-mg"
      managementGroupId: "pxs-cn-s-mg"
      policyDefinitionsPath: "$(parametersPath)/policyDefinition"
```

This is an example of how to use the deploy template for policyDefinition from the Platform repo.

```yml
stages:
- stage: Deploy
  jobs:
  - template: /modules/policyDefinition/1.1/pipeline/pipeline.jobs.deploy.yml@IaC
    parameters:
      serviceConnection: "pxs-cloudnative-mg"
      managementGroupId: "pxs-cn-s-mg"
      policyDefinitionsPath: "$(parametersPath)/policyDefinition"
      checkoutRepository:
      - IaC
```

## Template for policyDefinition json

This is an example of how to format the json file that is put in the parameter folder.

```json
{
   "properties": {
      "name": "pxs-cn-s-validationPolicy-pd",
      "displayName": "pxs-cn-s-validationPolicy-pd",
      "description": "Audit delegation of scopes to a managing tenant via Azure Lighthouse.",
      "policyType": "Custom",
      "mode": "All",
      "metadata": {
         "version": "1.0.0",
         "category": "Lighthouse"
      },
      "parameters": {
         "effect": {
            "type": "string",
            "defaultValue": "Audit",
            "allowedValues": [
               "Audit",
               "Disabled"
            ],
            "metadata": {
               "displayName": "Effect",
               "description": "Enable or disable the execution of the policy"
            }
         }
      },
      "policyRule": {
         "if": {
            "allOf": [
               {
                  "field": "type",
                  "equals": "Microsoft.ManagedServices/registrationAssignments"
               },
               {
                  "value": "true",
                  "equals": "true"
               }
            ]
         },
         "then": {
            "effect": "[parameters('effect')]"
         }
      }
   },
   "id": "/providers/Microsoft.Authorization/policyDefinitions/76bed37b-484f-430f-a009-fd7592dff818",
   "name": "76bed37b-484f-430f-a009-fd7592dff818"
}
```

## Component details

The components required for **creating / updating / deleting Policy definitions** are the following:

| Component                                  | What is it used for?                                                                                                                                                                                                                        | Where can it be found?                                                                                                                                  |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Policy Definition configuration script** | This script is used for creating / updating / deleting Policy definitions in Azure. These definitions are registered in the chosen scope.                                                                                                   | `/modules/policyDefinitions/1.0/Set-PolicyDefinitions.ps1`                                                                                              |
| **Policy Definition Schema**               | This schema defines the structure of the policy definitions files. These are tested against the schema when the configuration script is run.                                                                                                | `/modules/policyDefinitions/1.0/policyDefinitionSchema.json`                                                                                            |
| **Policy Definition JSON files**           | Policy definitions files define what a custom Policy is able to do, what its name is, and more.                                                                                                                                             | In any subfolder for the parameter repositories which consume this component. An example can be found under `/modules/policyDefinitions/1.0/Parameters` |
| **Deployment Pipeline**                    | The pipeline invokes the configuration script that registers custom policy definitions in the scope provided. For validation purposes, the pipeline file in this component is set to trigger on any changes of the PolicyDefinition folder. | In any subfolder for the parameter repositories which consume this component. An example can be found under `/modules/policyDefinitions/1.0/Pipeline`.  |

> **NOTE**:
> When authoring policy/initiative definitions, check out the [Maximum count of Azure Policy objects](https://docs.microsoft.com/en-us/azure/governance/policy/overview#maximum-count-of-azure-policy-objects)

## Policy Definition JSON files and Schema

The Policy files are structured based on the official [Azure Policy definition structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure) published by Microsoft. There are numerous definition samples available on Microsoft's [GitHub repository for azure-policy](https://github.com/Azure/azure-policy).

The schema implemented in the solution has been defined based on sample Policy definitions, using the [JSONschema.net](https://www.jsonschema.net/home) online tool.

As long as all definition JSON files are compliant with the schema, the script should be able to register all Policy definitions based on these files.

The names of the definition JSON files do not matter, the Policy definitions are registered based on the `name` attribute defined in the JSON's `properties`.

## Policy definition configuration scripts

The `Set-PolicyDefinitions.ps1` script configures Azure Policy definitions.

The script is **declarative** and **idempotent**: this means, that regardless how many times it is run, it always push all changes that were implemented in the JSON files to the Azure environment, i.e. if a JSON file is newly created/updated/deleted, the pipeline will create/update/delete the Policy definition in Azure. If there are no changes, the pipeline can be run any number of times, as it won't make any changes to Azure.

With other words, **the Policy definition JSON files within the parameter repository is the 'single source of truth'** for Policy Definitions.

> **NOTE**:
> Deletion of a definition is not possible if the Policy is assigned to any Management Groups / Subscriptions / Resource groups.

## Definitions pipeline

To use the script in a pipeline deployment, configure steps to run the Policy definitions configuration script (`Set-PolicyDefinitions.ps1`) with the below parameters.

The pipeline runs on behalf of a Service Principal that has **Owner** permissions on the applicable scope. This is required as the policy assignments pipeline is running under the same SPN, and for DeployIfNotExists and Modify policies it has to be able to configure RBAC assignments on the scope the policy is assigned to (to allow the MSI to interact with Azure).

> **NOTE**: Alternatively, the _Resource Policy Contributor_ role could also be used for the definitions pipeline if wasn't sharing the same SPN with the assignments pipeline.

### Policy definition task parameters

| Parameter                        | Value                                                                                | Explanation                                                                                                  |
| -------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| `ManagementGroupName`            | \$(managementGroupId)                                                                | Defines where the policy definitions are defined.                                                            |
| `PolicyDefinitionRootFolder`     | \$(Build.Repository.LocalPath)/\$(PolicyDefinitionsParameterPath)                    | All the policy definitions can be found in any subfolders of this root directory.                            |
| `PolicyDefinitionSchemaFilePath` | \$(Build.Repository.LocalPath)/\$(PolicyDefinitionsPath)/policyDefinitionSchema.json | The policy definition JSON schema's file path.                                                               |
| `DeleteIfMarkedForDeletion`      | \<isPresent\>                                                                        | This makes sure that all those policy definitions are deleted that are not defined in any of the JSON files. |

## Tested scenarios / Error handling

### Policy definition tests

| #   | Test scenario                                                                            | Outcome                                                                         |
| --- | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| 1.  | No JSON files in Definitions folder                                                      | Error thrown, as expected.                                                      |
| 2.  | Invalid JSON file ('{' removed from the first line)                                      | Error thrown, as expected.                                                      |
| 3.  | JSON file is not compliant with the schema (name removed)                                | Error thrown, as expected.                                                      |
| 4.  | Creation of two new definitions                                                          | Definitions registered successfully.                                            |
| 5.  | Updated the description field of one definition                                          | Definition updated successfully.                                                |
| 6.  | Delete one of the definitions                                                            | Definition deleted successfully.                                                |
| 7.  | Change 'name' attribute within the definition                                            | Results the deletion of existing, creation of new definition as expected.       |
| 8.  | Multiple JSON files containing the same definition name                                  | Error thrown, as expected. The user will have to manually resolve the conflict. |
| 9.  | Deleting a definition that is assigned.                                                  | Error thrown, as expected. All assignments have to be removed first.            |
| 10. | Add additional parameter for an already assigned policy definition without default value | Error thrown, as expected                                                       |
| 11. | Add additional parameter for an already assigned policy definition with default value    | Definition updated successfully                                                 |
| 12. | Delete parameter for an already assigned policy definition                               | Error thrown, as expected                                                       |
| 13. | Updating existing parameters in the definition that is assigned.                         | Definition updated successfully                                                 |
