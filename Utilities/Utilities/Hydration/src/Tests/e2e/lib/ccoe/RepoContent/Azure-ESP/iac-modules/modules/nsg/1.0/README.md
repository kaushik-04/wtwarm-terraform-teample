- [nsg 1.0](#nsg-10)
  - [Release Notes](#release-notes)
  - [Component Design](#component-design)
  - [Operations](#operations)
    - [Deployment](#deployment)
      - [Parameters](#parameters)
      - [Outputs](#outputs)
      - [Secrets](#secrets)
      - [YAML Pipeline deployment](#yaml-pipeline-deployment)
  - [Security Framework Controls](#security-framework-controls)
  - [Policies](#policies)

# Network Security Group 1.0

## Release Notes

**[2021.02.16]**

> + Initial version of stroageAccount component with the following parameters enabled: 
>   - **networkSecurityGroupName**. Required.  The name for the nsg.
>   - **location**. Required. Set the locaction for the nsg.
           Currently the location will be locked into 'West Europe'.
>   - **accountType**. Optional. Specifies the SKU for the nsg. Default= Standard_LRS.
           Allowed values: [ Standard_LRS, Standard_GRS, Standard_ZRS, Premium_LRS]



## Component Design

The Design can be found in the [Product Catalogue](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/446/Product-Catalog) - [nsg 1.0](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/477/Storage-Account)

## Operations

### Deployment

#### Parameters

The following JSON serves as an example for the parameters

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "networkSecurityGroupName": {
            "value": "pxsnsgsvnetnsg"
        },
        "location": {
            "value": "westeurope"
        }
    }
}
```
#### Outputs

The deployment of nsg outputs the ID of the nsg created:
 
   **nsgResourceId**

#### Secrets

No Secrets will be created during the provisioning for this version of the Component

#### YAML Pipeline deployment

The following [YAML pipeline stage](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/stages?view=azure-devops&tabs=yaml) can be used as a reference to deploy the nsg:

```yml
- stage: nsgDeployment
  jobs:
  - template: /cicd/templates/pipeline.jobs.deploy.yml@IaC
    parameters:
      moduleName: nsg
      modulePath: $(modulesPath)/nsg/1.0
      displayName: Deploy_nsg
      deploymentBlocks:
      - path: {path_to_configuration_file}
      checkoutRepositories:
      - IaC
```

## Security Framework Controls

See Security Framework in article [Cloud Native Security](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/413/Cloud-Native-Security)



## Policies