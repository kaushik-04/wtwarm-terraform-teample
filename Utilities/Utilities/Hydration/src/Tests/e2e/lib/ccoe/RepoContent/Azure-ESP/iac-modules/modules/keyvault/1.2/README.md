- [Key Vault 1.0](#key-vault-10)
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

# Key Vault 1.0

## Release Notes

**[2021.01.28]**

> + Key Vault updated with the following parameters:
>   - **storageAccountId**. Removed
>   - **workspaceId**. Required. Log Analytics workspace ID to be configured as part of the diagnostic settings
>   - **eventHubAuthorizationRuleId**. Required. EventHub Authorization Rule ID to be configured as part of the diagnostic settings
>   - **eventHubName**. Required. EventHub ID to be configured as part of the diagnostic settings
>   - **softDeleteRetentionInDays**. Required. The amount of days that the KeyVault will remain recoverable after deletion
>   - **enableRbacAuthorization**. Required. The data plane management model which uses Access Policies or RBAC to manage the Keys, Secrets and Certificates
> 
> + The following Azure Policies have been published:
>   - **Cloud-Native management group**.
>       - **pxs-cn-kvt-private-endpoint-pd**. This policy audits/disables the usage of private endpoint for KeyVaults
>       - **pxs-cn-kvt-purge-pd**. This policy restricts the KeyVaults to only be deployed if the have the purge feature enabled
>       - **pxs-cn-kvt-rbac-pd**. Disable RBAC authorization on Data Plane to manage Keys, Secrets and Certificates
>       - **pxs-cn-kvt-sku-pd**. This policy restrict the SKUs you can specify when deploying KeyVaults
>       - **1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d**. Key vaults should have soft delete enabled. Deleting a key vault without soft delete enabled permanently deletes all secrets, keys, and certificates stored in the key vault. Accidental deletion of a key vault can lead to permanent data loss. Soft delete allows you to recover an accidentally deleted key vault for a configurable retention period.

**[2020.12.17]**

> + Initial version of Key Vault component with the following parameters enabled: 
>   - **keyVaultName**. Required. Name of the Azure Key Vault
>   - **location**. Optional. Location for the Azure Key Vault
>   - **vaultSku**. Optional. Specifies the SKU for the vault
>   - **enableSoftDelete**. Optional. Switch to enable/disable Key Vault's soft delete feature.
>   - **softDeleteRetentionInDays**. Optional. Set to 90 days by default.
>   - **accessPolicies**. Optional. Array of access policies object
>   - **enableVaultForDeployment**. Optional. Enable advanced policy for Virtual Machines Certificates deployment
>   - **enableVaultForTemplateDeployment**. Optional. Enable advanced policy  for ARM Template deployments
>   - **enablePurgeProtection**. Optional. Provide 'true' to enable Key Vault's purge protection feature
>   - **keyVaultAdministratorAssignments**. Optional. List of Object Ids to be given the Key Vault Administrator Role
>   - **keyVaultReaderAssignments**. Optional. List of Object Ids to be given the Key Vault Reader Role
>   - **tags**. Optional. Resource tags
>   - **diagnosticSettingsName**. Optional. The name for the Diagnostic Setting to be configured in the Key Vault
>   - **storageAccountId**. Optional. Storage Account ID to be configured as part of the diagnostic settings

## Component Design

The Design can be found in the [Product Catalogue](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/446/Product-Catalog) - [Key Vault 1.0](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/448/KeyVault)

## Operations

### Deployment

#### Parameters

The following JSON serves as an example for the parameters

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "keyVaultName": {
            "value": "kvt-cc-DEMO2"
        },
        "location": {
            "value": "West Europe"
        },
        "accessPolicies": {
            "value": [
                {
                    "tenantId": "e7ab81b2-1e84-4bf7-9dcb-b6fec01ed138",
                    "objectId": "ac225f13-0ad3-4871-9e63-0efbd1e0e48e",
                    "permissions": {
                        "certificates": [
                            "get"
                        ],
                        "keys": [
                            "get"
                        ],
                        "secrets": [
                            "get"
                        ],
                        "storage": [
                            "get"
                        ]
                    }
                }
            ]
        },
        "softDeleteRetentionInDays": {
            "value": 90
        },
        "enableVaultForDeployment": {
            "value": false
        },
        "enableVaultForTemplateDeployment": {
            "value": false
        },
        "enablePurgeProtection": {
            "value": false
        },
        "diagnosticSettingsName": {
            "value": "DiagnosticSettingsEventHub-Workspace-Demo"
        },
        "tags": {
            "value": {
                "application-id": "Application-id-tag",
                "cost-center": "cost-center-tag",
                "deployment-id": "deployment-id-tag",
                "environment": "d",
                "platform-id": "platform-id-tag"
            }
        },
        "workspaceId": {
            "value": "/subscriptions/1969b336-8177-4aea-97ac-21b9d2c230fc/resourcegroups/test-keyvault/providers/microsoft.operationalinsights/workspaces/test-keyvault-workspace"
        },
        "eventHubAuthorizationRuleId": {
            "value": "/subscriptions/1969b336-8177-4aea-97ac-21b9d2c230fc/resourceGroups/Test-KeyVault/providers/Microsoft.EventHub/namespaces/Test-KeyVault-Eventhub/authorizationrules/RootManageSharedAccessKey"
        },
        "eventHubName": {
            "value": "Test-KeyVault-Eventhub"
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
- stage: keyVaultDeployment
  jobs:
  - template: /cicd/templates/pipeline.jobs.deploy.yml@IaC
    parameters:
      moduleName: keyvault
      moduleVersion: '1.0'
      displayName: Deploy_keyVault
      deploymentBlocks:
      - path: {path_to_configuration_file}
      checkoutRepositories:
      - IaC
```

## Security Framework Controls

See Security Framework in article [Cloud Native Security](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/413/Cloud-Native-Security)

| SCF # | Category | What | How | Category |
| - | - | - | - | - | -
| SCF-IAM-01 | RBAC access control | IAM on all resources | A list of Service Principals object Ids can be provided as input to give them the role definition of 'Key Vault Administrator' or 'Key Vault Reader'
| SCF-TVI-07 | Azure Defender for Key Vault | Virus and malware protection | At subscription level -> delivered by Foundation Team
| SCF-TVI-03 | Resource Audit Logs | tbd

## Policies

The following Policies are in place (see article [Foundation Design](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/410/Foundation-Design) > [Governance](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/496/Governance) in Wiki to learn more about Policies)

| Policy type | Policy id | Policy Display Name | Policy description | Allowed values | Effect
| - | - | - | - | -
| custom | `pxs-cn-kvt-sku-pd` | Restrict allowed SKUs for KeyVault | This policy restrict the SKUs you can specify when deploying KeyVaults |  `"Standard"`, `"Premium"` | Deny
| custom | `pxs-cn-kvt-purge-pd` | Only deploy Keyvaults with purge enabled | This policy restricts the KeyVaults to only be deployed if the have the purge feature enabled | n/a | Audit
| custom | `pxs-cn-kvt-private-endpoint-pd` | Audit private endpoint usage | This policy audits/disables the usage of private endpoint for KeyVaults
| custom | `pxs-cn-kvt-rbac-pd` | Disable RBAC authorization on Data Plane | Disable RBAC authorization on Data Plane to manage Keys, Secrets and Certificates
| custom | `pxs-cn-kvt-sku-pd` | Restrict allowed SKUs for KeyVault | This policy restrict the SKUs you can specify when deploying KeyVaults
| built-in | `1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d` | [Key vault should have soft delete enabled](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d) | Deleting a key vault without soft delete enabled permanently deletes all secrets, keys, and certificates stored in the key vault. Accidental deletion of a key vault can lead to permanent data loss. Soft delete allows you to recover an accidentally deleted key vault for a configurable retention period. | n/a | Audit