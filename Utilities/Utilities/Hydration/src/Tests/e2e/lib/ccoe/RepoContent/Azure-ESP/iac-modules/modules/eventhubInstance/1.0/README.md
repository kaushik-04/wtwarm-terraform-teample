- [Event Hub Instance 0.1](#Event-Hub-Instance-01)
  - [Release Notes](#release-notes)
  - [Operations](#operations)
    - [Deployment](#deployment)
      - [Parameters](#parameters)
      - [YAML Pipeline deployment](#yaml-pipeline-deployment)

# Event Hub Instance 0.1

## Release Notes

**[2021.02.08]**

> + EventHub Instance:
>   - Component specifically configured to be used in the logging subscription
>   - Depends on the Event Hub Namespace to be deployed
> + EventHub parameters
>    - **name**, name of the event hub namespace
>    - **namespace_name**, namespace to assign the instance too
>    - **tags**, required tags

## Operations

### Deployment

#### Parameters

The following JSON serves as an example for the parameters

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "name": {
            "value": "test"
        },
        "namespace_name": {
            "value": "pxs-azure-nonprod-ehn-testtemp1"
        },
        "tags": {
			"value": {
				"environment": "s",
				"cost-center": "azure",
				"application-id": "azure",
				"deployment-id": "test"
			}
        }               
    }
}
```
#### Outputs

No Outputs will be created as a result of the provisioning for this version  of the Component

#### Secrets

No Secrets will be created during the provisioning for this version of the Component

#### YAML Pipeline deployment

The following [YAML pipeline stage](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/stages?view=azure-devops&tabs=yaml) can be used as a reference to deploy the Key Vault:

```yml
- stage: EventhubNameSpaceDeployment
  jobs:
  - template: /cicd/templates/pipeline.jobs.deploy.yml@IaC
    parameters:
      moduleName: eventhubInstance
      modulePath: $(modulesPath)/eventhubInstance/1.0
      deploymentBlocks:
      - path: $(parametersPath)/eventhubInstance/pxs-azure-nonprod-keyvault-ehi.json
      - path: {path_to_configuration_file}
      checkoutRepositories:
      - IaC
```

## Policies

Not implemented as this is not a certified component. 