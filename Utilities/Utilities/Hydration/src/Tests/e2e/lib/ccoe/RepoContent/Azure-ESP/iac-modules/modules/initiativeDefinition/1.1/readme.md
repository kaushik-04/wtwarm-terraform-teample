[[_TOC_]]

# Initiative Definitions

This page describes how Initiative Definitions are handled by the Policy-as-Code framework.

## How to use the component

To use this component, use the pipeline template file located `.\pipeline\pipeline.jobs.deploy.yml`.

The template yml has the following parameters:

| Parameter                       | datatype      | allowed values                                                                                                               | default value                        | Description                                                       |
| ------------------------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ----------------------------------------------------------------- |
| serviceConnection               | string        | *                                                                                                                            | '$(serviceConnection)'               | Name of the ARM service connection that the deployment will use   |
| managementGroupId               | string        | *                                                                                                                            | '$(managementGroupId)'               | Name of management group to target for the deployment             |
| poolName                        | string        | *                                                                                                                            | '$(poolName)'                        | Name of the self hosted pool to run this job in                   |
| vmImage                         | string        | [Microsoft-hosted agents](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops&tabs=yaml) | '$(vmImage)'                         | Name of the VM image in the Microsoft-hosted pool you want to use |
| moduleName                      | string        | *                                                                                                                            | 'initiativeDefinition'               | Name of the component                                             |
| moduleVersion                   | string        | *                                                                                                                            | '1.1'                                | Version of the component                                          |
| initiativeDefinitionsPath       | string        | *                                                                                                                            | ''                                   | Path to the folder containing initiative definitions              |
| defaultJobTimeoutInMinutes      | number        | *                                                                                                                            | 120                                  | How long to run the job before automatically cancelling           |
| checkoutRepositories            | list(strings) | *                                                                                                                            | ''                                   | Name of additional repos to checkout/download in the pipeline     |
| dependsOn                       | list(strings) | *                                                                                                                            | []                                   | A list of stages/jobs to run before this                          |
| parametersRepository            | string        | *                                                                                                                            | '$(Build.Repository.Name)'           | The repository that holds parameters for the deployment           |
| azurePowerShellVersion          | string        | 'latestVersion', 'otherVersion'                                                                                              | '$(azurePowerShellVersion)'          | Powershell version to run this tasks on                           |
| preferredAzurePowerShellVersion | string        | * [more info](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/azure-powershell?view=azure-devops)       | '$(preferredAzurePowerShellVersion)' | Specify if azurePowerShellVersion is 'otherVersion'               |

This is an example of how to use the deploy template for initiativeDefinition from the IaC repo.

```yml
stages:
- stage: Deploy
  jobs:
  - template: /modules/initiativeDefinition/1.1/pipeline/pipeline.jobs.deploy.yml
    parameters:
      serviceConnection: "pxs-cloudnative-mg"
      managementGroupId: "pxs-cn-s-mg"
      initiativeDefinitionsPath: "$(parametersPath)/initiativeDefinition"
```

This is an example of how to use the deploy template for initiativeDefinition from the Platform repo.

```yml
stages:
- stage: Deploy
  jobs:
  - template: /modules/initiativeDefinition/1.1/pipeline/pipeline.jobs.deploy.yml@IaC
    parameters:
      serviceConnection: "pxs-cloudnative-mg"
      managementGroupId: "pxs-cn-s-mg"
      initiativeDefinitionsPath: "$(parametersPath)/initiativeDefinition"
      checkoutRepository:
      - IaC
```

## Template for InitiativeDefinition json

This is an example of how to format the json file that is put in the parameter folder.

```json
{
    "name": "pxs-cn-samplekvt-pi",
    "displayName": "pxs-cn-samplekvt-pi",
    "description": "This initiative restrics the configuration of any deployed keyvault that differs from the compliant.",
    "metadata": {
        "category": "Security"
    },
    "policyDefinitions": [
        {
            "policyDefinitionId": "/providers/Microsoft.Management/managementGroups/pxs-cloudnative-mg/providers/Microsoft.Authorization/policyDefinitions/pxs-cn-kvt-sku-pd",
            "parameters": {
                "allowedSKUs": {
                    "value": "[parameters('allowedSKUs')]"
                }
            }
        }
    ],
    "parameters": {
        "allowedSKUs": {
            "type": "array",
            "metadata": {
                "displayName": "allowedSKUs",
                "description": "List of locations allowed SKUs for the Key Vault resource type."
            }
        }
    }
}
```

## Component details

The components required for **creating / updating / deleting Initiative definitions** are the following:

| Component                                      | What is it used for?                                                                                                                                                                                                                                 | Where can it be found?                                                                                                                                      |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Initiative Definition configuration script** | This script is used for creating / updating / deleting Initiative definitions in Azure. These definitions are registered in the chosen scope.                                                                                                        | `/modules/initiativeDefinitions/1.0/Set-InitiativeDefinitions.ps1`                                                                                          |
| **Initiative Definition Schema**               | This schema defines the structure of the initiative definitions files. These are tested against the schema when the configuration script is run.                                                                                                     | `/modules/initiativeDefinitions/1.0/initiativeDefinitionSchema.json`                                                                                        |
| **Initiative Definition JSON files**           | Initiative definitions files define what a custom Initiative is able to do, what its name is, and more.                                                                                                                                              | In any subfolder for the parameter repositories which consume this component. An example can be found under `/modules/initiativeDefinitions/1.0/Parameters` |
| **Definitions Pipeline**                       | The pipeline invokes the configuration script that registers custom initiative definitions in the scope provided. For validation purposes, the pipeline file in this component is set to trigger on any changes of the InitiativeDefinitions folder. | In any subfolder for the parameter repositories which consume this component. An example can be found under `/modules/initiativeDefinitions/1.0/Pipeline`.  |

> **NOTE**:
> When authoring policy/initiative definitions, check out the [Maximum count of Azure Policy objects](https://docs.microsoft.com/en-us/azure/governance/policy/overview#maximum-count-of-azure-policy-objects)

## Initiative Definition JSON files and Schema

The Initiative definition files are structured based on the official [Azure Policy initiative definition structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/initiative-definition-structure) published by Microsoft. There are numerous definition samples available on Microsoft's [GitHub repository for azure-policy](https://github.com/Azure/azure-policy).

The schema implemented in the solution has been defined based on sample Initiative definitions, using the [JSONschema.net](https://www.jsonschema.net/home) online tool.

As long as all definition JSON files are compliant with the schema, the script should be able to register all Initiative definitions based on these files.

The names of the definition JSON files do not matter, the Initiative definitions are registered based on the `name` attribute defined in the JSON's `properties`.

## Initiative definition configuration scripts

The `Set-InitiativeDefinitions.ps1` script is used to configure Initiatives.

The script is **declarative** and **idempotent**: this means, that regardless how many times it is run, it always push all changes that were implemented in the JSON files to the Azure environment, i.e. if a JSON file is newly created/updated/deleted, the pipeline will create/update/delete the Initiative definition in Azure. If there are no changes, the pipeline can be run any number of times, as it won't make any changes to Azure.

With other words, **the Initiative definition JSON files within the parameter repository is the 'single source of truth'** for Initiative Definitions.

> **NOTE**:
> Deletion of a definition is not possible if the Initiative is assigned to any Management Groups / Subscriptions / Resource groups.

## Definitions pipeline

To use the script in a pipeline deployment, configure steps to run the Initiative definitions configuration script (`Set-InitiativeDefinitions.ps1`) with the below parameters.

The pipeline runs on behalf of a Service Principal that has **Owner** permissions on the applicable scope. This is required as the Initiative assignments pipeline is running under the same SPN, and for DeployIfNotExists and Modify policies it has to be able to configure RBAC assignments on the scope the policy in the initiative is assigned to (to allow the MSI to interact with Azure).

> **NOTE**: Alternatively, the _Resource Policy Contributor_ role could also be used for the definitions pipeline if wasn't sharing the same SPN with the assignments pipeline.

### Initiative definition task parameters

| Parameter                            | Value                                                                                        | Explanation                                                                                                      |
| ------------------------------------ | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `ManagementGroupName`                | \$(managementGroupId)                                                                        | Defines where the Initiative definitions are defined.                                                            |
| `InitiativeDefinitionRootFolder`     | \$(Build.Repository.LocalPath)/\$(InitiativeDefinitionsParameterPath)                        | All the initiative definitions can be found in any subfolders of this root directory.                            |
| `InitiativeDefinitionSchemaFilePath` | \$(Build.Repository.LocalPath)/\$(InitiativeDefinitionsPath)/initiativeDefinitionSchema.json | The initiative definition JSON schema's file path.                                                               |
| `DeleteIfMarkedForDeletion`          | \<isPresent\>                                                                                | This makes sure that all those initiative definitions are deleted that are not defined in any of the JSON files. |

## Tested scenarios / Error handling

### Initiative definitions tests

| #   | Test scenario                                                                                                                     | Outcome                                                                                                                                            |
| --- | --------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.  | No JSON files in Initiatives folder                                                                                               | Error thrown, as expected.                                                                                                                         |
| 2.  | Invalid JSON file ('{' removed from the first line)                                                                               | Error thrown, as expected.                                                                                                                         |
| 3.  | JSON file is not compliant with the schema (name removed)                                                                         | Error thrown, as expected.                                                                                                                         |
| 4.  | Creation of two new initiatives                                                                                                   | Initiatives registered successfully.                                                                                                               |
| 5.  | Updated the description field of one initiative                                                                                   | Initiative updated successfully.                                                                                                                   |
| 6.  | Delete one initiative                                                                                                             | Initiative deleted successfully.                                                                                                                   |
| 7.  | Change Initiative category                                                                                                        | Initiative updated successfully.                                                                                                                   |
| 8.  | Change 'name' attribute within the initiative                                                                                     | Results the deletion of existing, creation of new initiative as expected.                                                                          |
| 9.  | Multiple JSON files containing the same initiative name                                                                           | Error thrown, as expected. The user will have to manually resolve the conflict.                                                                    |
| 10. | Add additional initiative parameter for an existing initiative without default value                                              | Error thrown, as expected.                                                                                                                         |
| 11. | Add additional initiative parameter for an existing initiative with default value                                                 | Initiative updated successfully.                                                                                                                   |
| 12. | Remove an initiative parameter for an existing initiative                                                                         | Error thrown, as expected.                                                                                                                         |
| 13. | Reference a not defined policyDefinitionID (at that scope) in the initiative                                                      | Error thrown, as expected.                                                                                                                         |
| 14. | Reference an parameter in a policyDefinition, that is not defined in the policyDefinition                                         | Error thrown, as expected.                                                                                                                         |
| 15. | Define a parameter at the initiative, that is not used in any policyDefinition parameters                                         | Error thrown, as expected.                                                                                                                         |
| 16. | Don't use a parameter from an existing initiative definition anymore in any policyDefinition parameters                           | Initiative updated successfully.                                                                                                                   |
| 17. | Use undefined parameter in any of the referenced policyDefinitions                                                                | Error thrown, as expected.                                                                                                                         |
| 18. | Use wrong parameter type (str,int,bool,array,obj) or invalid value in direct assignment to a policyDefinition parameter           | Error thrown, as expected.                                                                                                                         |
| 19. | Specify only a subset of parameters for a referenced policyDefinition, while it has default values defined for missing parameters | Initiative created successfully.                                                                                                                   |
| 20. | Do not specify all parameters for referenced policyDefinitions, when they all have a default value                                | Initiative created successfully.                                                                                                                   |
| 21. | Do not specify all parameters for referenced policyDefinitions, when they don't have a default value                              | Error thrown, as expected.                                                                                                                         |
| 22. | Add a parameter in a referenced policyDefinitions, which has a default value                                                      | Initiative updated successfully.                                                                                                                   |
| 23. | Update parameter value within a policyDefinition for an existing Initiative                                                       | Initiative updated successfully.                                                                                                                   |
| 24. | Deleting an initiative that is assigned.                                                                                          | Error thrown, as expected. All assignments have to be removed first.                                                                               |
| 25. | Add initiative parameter to assigned initiative                                                                                   | Initiative updated successfully - assignment doesn't reflect new parameter, however, new parameters need to have a default value that is used then |
| 26. | Add policy to already assigned Initiative                                                                                         | Initiative updated successfully - policies and their parameters within assigned initiatives are evaluated during policy engine execution           |
