- [Event Hub 0.1](#Event-Hub-01)
  - [Release Notes](#release-notes)
  - [Operations](#operations)
    - [Deployment](#deployment)
      - [Parameters](#parameters)
      - [YAML Pipeline deployment](#yaml-pipeline-deployment)

# Event Hub 0.1

## Release Notes

**[2021.02.08]**

> + EventHub Namespace:
>   - Component specifically configured to be used in the logging subscription
> + EventHub parameters
>    - **name**, name of the event hub namespace
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
            "value": "pxs-azure-prod-ehn"
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
        moduleName: eventhub
        modulePath: $(modulesPath)/eventhub/1.0
        deploymentBlocks:
        - path: {path_to_configuration_file}
          jobName: {jobname}
        checkoutRepositories:
        - IaC
```

## Policies

Not implemented as this is not a certified component. 