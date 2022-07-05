# Machine Learnning 0.1

- [Machine Learnning 0.1](#machine-learning-10)
  - [Release Notes](#release-notes)
  - [Pre-Requisites](#pre-requisites)
  - [Component Design](#component-design)
  - [Operations](#operations)
    - [Deployment](#deployment)
      - [Parameters](#parameters)
      - [Outputs](#outputs)
      - [Secrets](#secrets)
      - [YAML Pipeline deployment](#yaml-pipeline-deployment)
  - [Security Framework Controls](#security-framework-controls)
  - [Policies](#policies)

## Release Notes

### **[Future releases expected features]**

> - Addition of Workspace Computes during template deployment
> - Addition of [policies](#policies)
> - Creation of [custom RBAC Roles](https://docs.microsoft.com/en-us/azure/machine-learning/how-to-assign-roles#create-custom-role)
> - Creation of alerts for policies that cannot be enforced / audited using Azure policies

### **[2021.02.15-MVP1]**

> - Initial version of Machine Learning component with the following parameters enabled:
>   - **workspaceName**. Required. Name of the Machine Learning workspace.
>   - **location**. Optional. Optional. Location for the Machine Learning Workspace. Defaults to West Europe.
>   - **workspaceSku**. Optional. Specifies the sku, also referred as 'edition' of the Machine Learning workspace. Defaults to **basic**. Enterprise edition has been deprecated early 2021.
>   - **storageAccountName**. Required. The name of a pre-provisioned StorageAccount to be used by the Machine Learning workspace.
>   - **keyVaultName**. Required. The name of a pre-provisioned KeyVault to be used by the Machine Learning workspace.
>   - **appInsightName**. Required. The name of a pre-provisioned Application Insight to be used by the Machine Learning workspace.
>   - **containerRegistryName**. Required. The name of a pre-provisioned Container Registry to be used by the Machine Learning workspace.
>   - **tags**. Required. Resource tags

## Pre-Requisites

Machine Learning is a PaaS service that requires below components to be deployed together with the Machine Learning service itself. Please note **those components are bound to the Machine Learning instance and should not be used nor shared in any case for other purposes**. Upon removal of the Machine Leaning instance, you manually need to remove the dependent components or script the removal in a DevOps pipeline.

- Key Vault
- Storage Account (requires StorageV2)
- Application Insight
- Container Registtry

Those components can be either provisioned automatically during the Machine Learning deployment, either **pre-provisioned** and specified in the Machine Learning deployment template. In order to ensure resusability of Certified Products, we prefer this later option.

> Please note the required use of a StorageV2 StorageAccount. Upon initialization, Machine Learning will create in the StorageV2 both a blob storage (temporary and uploaded files) and a file storage (notebooks).

## Component Design

The Design can be found in the [Product Catalogue](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/446/Product-Catalog) - [Machine Learning 1.0](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/461/Machine-Learning)

## Operations

### Deployment

#### Parameters

The following JSON serves as an example for the parameters

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "workspaceName": {
            "value": "pxs-mls-wb-demo-04"
        },
        "location": {
            "value": "West Europe"
        },
        "workspaceSku":{
            "value": "basic"
        },
        "storageAccountName": {
            "value": "pxsmlsstordemo04"
        },
        "keyVaultName": {
            "value": "pxs-mls-kv-demo-04"
        },
        "appInsightName": {
            "value": "pxs-mls-appi-demo-04"
        },
        "containerRegistryName": {
            "value": "pxsmlsacrdemo04"
        },
        "tags": {
            "value": {
                "platform-id": "bdp",
                "application-id": "plt",
                "cost-center": "508107",
                "deployment-id": "mls@1",
                "environment": "s"
            }
        }
    }
}
```

#### Outputs

Following outputs are provided upon Machine Learning deployment
| Name | Type | Value |
| ---- | ---- | ----- |
| MlWorkspaceId | string | [resourceId('Microsoft.MachineLearningServices/workspaces', parameters('workspaceName'))] |
| MlWorkspaceResourceGroup | string | [resourceGroup().name] |
| MlWorkspaceName | string | [parameters('workspaceName')] |

#### Secrets

Azure Machine Learning stores secrets that are used by compute targets and other sensitive information that's needed by the workspace in the associated KeyVault specified as part of the template deployment (*keyVaultName* parameter). Those secrets are solely managed by the Machine Learning service itself and should never be modified nor deleted.  

Upon deployment of the Machine Learning service, Azure Resouce Manager will create a Managed Identity for the workspace and grants various RBAC roles on the dependent resources. Those role assignments are documented [here](https://docs.microsoft.com/en-us/azure/machine-learning/concept-enterprise-security#restrict-access-to-resources-and-operations). During the workspace deployment, the Managed Identity will grab various access keys (StorageAccount, Container Registry and ApplicationInsights) and store those in the workspace's KeyVault.

In case of forced rotation of AccessKeys for StorageAccounts used by a Machine Learning workpace, the secrets for those StorageAccounts stored in the associated KeyVault can be [resynced](https://docs.microsoft.com/en-us/azure/machine-learning/how-to-change-storage-access-key) with the workspace.

#### YAML Pipeline deployment

The following [YAML pipeline stage](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/stages?view=azure-devops&tabs=yaml) can be used as a reference to deploy the Machine Learning. Please note the dependent resources as described in the [Pre-Requisites](#pre-requisites) must have been deployed prior to Machine Learning service deployment:

```yml
- stage: machineLearningDeployment
  jobs:
  - template: /cicd/templates/pipeline.jobs.deploy.yml@IaC
    parameters:
      moduleName: machinelearning
      modulePath: $(modulesPath)/machinelearning/1.0
      displayName: Deploy_machinelearning
      deploymentBlocks:
      - path: {path_to_configuration_file}
      checkoutRepositories:
      - IaC
```

## Security Framework Controls

TO BE ELABORATED. Copied from KeyVault certified product, probably not enough for Machine Learning service certification.

See Security Framework in article [Cloud Native Security](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/413/Cloud-Native-Security)

| SCF # | Category | What | How | Category |
| - | - | - | - | - | -
| SCF-IAM-01 | RBAC access control | IAM on all resources | tbd. Custom Roles will be required.
| SCF-TVI-07 | Azure Defender for Machine Learning | Virus and malware protection | tbd
| SCF-TVI-03 | Resource Audit Logs | tbd

## Policies

MVP1 do not deploy any Policies. (see article [Foundation Design](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/410/Foundation-Design) > [Governance](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/496/Governance) in Wiki to learn more about Policies)

Candidate policies to evaluate are:

| Policy type | Policy id | Policy Display Name | Policy description | Allowed values | Effect |
| - | - | - | - | - | - |
| custom | `tbd` | Restrict allowed SKUs for MachineLearning | This policy restrict the SKUs you can specify when deploying MachineLearning. [Enterprise Edition deprecation notice.](https://docs.microsoft.com/en-us/azure/machine-learning/concept-workspace#what-happened-to-enterprise-edition) |  `"basic"` | Deny
| custom | `tbd` | tbd | Production environment must only support **batch** workspaces for technical users (Service Principals) [2.3 Management Plane](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/1085/Machine-Learning?anchor=2.3.-management-plane) |  tbd | tbd |
| custom | `tbd` | tbd | Non-Production **interactive** environment must only support Data Scientists user credentials authentication [2.3 Management Plane](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/1085/Machine-Learning?anchor=2.3.-management-plane) |  tbd | tbd |
| custom | `tbd` | tbd | All ComputeInstances and Clusters must be deployed with a Managed Identity | tbd | tbd |
| custom | `tbd` | tbd | All workspaces RBAC roles must be one of the allowed values. Default Owner, Contributor and Reader Roles cannot be assigned. See [CN-SR-08](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/1085/Machine-Learning?anchor=5.-security-controls) | tbd | tbd |
| custom | `tbd` | tbd | All workspaces activities must be logged. See [CN-SR-10, 11, 12 and 13](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/1085/Machine-Learning?anchor=5.-security-controls) | tbd | tbd |
| custom | `tbd` | tbd | SSH is allowed in interactive non-production workspaces, but disallowed in all batch workspaces. See [CN-SR-21](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/1085/Machine-Learning?anchor=5.-security-controls) | tbd | tbd |
| custom | `tbd` | tbd | All ML workspaces datasets must be registered with mandatory [tags](https://docs.microsoft.com/en-us/python/api/azureml-core/azureml.data.abstract_dataset.abstractdataset?view=azure-ml-py#add-tags-tags-none-). See [CN-SR-04](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/1085/Machine-Learning?anchor=5.-security-controls) | tbd | tbd |
| custom | `tbd` | tbd | All ML workspaces models must be registered with mandatory [tags](https://docs.microsoft.com/en-us/python/api/azureml-core/azureml.core.model.model?view=azure-ml-py). See [CN-SR-04](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/1085/Machine-Learning?anchor=5.-security-controls) | tbd | tbd |

plus 8 built-in policies, for which 6 are in preview
