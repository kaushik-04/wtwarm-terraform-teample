- [StorageAccount 1.0](#storageaccount-10)
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

# Storage Account 1.0

## Release Notes

**[2021.02.23]**
This version commited with policies on SKU, InfraStructureEnryption, PublicAccess, HTTPS-only, Minimum-TLS, SoftDelete.
The audit for allowing Shared Key Access has been postponed until that property [allowSharedKeyAccess], although already deployed, becomes GA.
> 
> + The following Azure Policies have been published:
>       - **Cloud-Native management group**.
>       - **pxs-cn-sa-encryption-pd** Audit whether Infrastructure Encryption on storageAccount has been enabled
>       - **pxs-cn-sa-allowpublicaccess-pd** Audit whether the storageAccount has public access
>       - **pxs-cn-sa-tls-pd** Audit the Minimum Tls Version requirement of TLS1_2
>       - **pxs-cn-sa-softdelete-pd** Audit whether for Blob kind of storage account the Soft Delete is enabled
>       - **allowedSKUs** [Built In] This policy restrict the SKUs you can specify when deploying storageAccounts
>       - **HttpsTrafficOnlyEffect** [Built In] Policy to audit whether Https is the only allowed transfer technology

        - **pxs-cn-sa-sharedkeyaccess-pd** Audit whether the storageAccount allowes Shared Key Access
                >>> will be deployed when General Available <<<


  Note: PolicyAssignment scopes: pxs-cn-s-mg, pxs-cn-p-mg (sandbox and production environment)

> + Initial version of stroageAccount component with the following parameters enabled: 
>   - **storageAccountName**. Required.  The name for the storageAccount.
>   - **location**. Required. Set the locaction for the storageAccount.
           Currently the location will be locked into 'West Europe'.
>   - **accountType**. Optional. Specifies the SKU for the storageAccount. Default= Standard_LRS.
           Allowed values: [ Standard_LRS, Standard_GRS, Standard_ZRS, Premium_LRS]
>   - **kind**. Optional. Specify the kind of storageAccount. 
           It allows for StorageV2 or BlobStorage kinds. Default= StorageV2
>   - **allowBlobPublicAccess**. Optional. Allow or Disallow public access to this Blob. Default= false.
>   - **enableHnS**. Optional. Enable Hierarchic name Space on storageAccount. Default= false.
           This parameter is accessible in case the 'kind' is of 'Blobstorage' (no HnS available).
>   - **allowSharedKeyAccess**. False (enforced - Preview) . Disable the use of Shared Key Access.
>   - **tags**. Optional. Resource tags.


## Component Design

The Design can be found in the [Product Catalogue](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/446/Product-Catalog) - [storageaccount 1.0](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/477/Storage-Account)

## Operations

### Deployment

#### Parameters

The following JSON serves as an example for the parameters

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "location": {
            "value": "West Europe"
        },
        "storageAccountName": {
            "value": "pxssptssa6"
        },
        "accountType": {
            "value": "Standard_LRS"
        },
        "kind": {
            "value": "StorageV2"
        },
        "tags": {
            "value": {
                "application-id": "spt",
                "cost-center": "unknown",
                "deployment-id": "d",
                "environment": "s"
            }
        },
        "allowBlobPublicAccess": {
            "value": false
        },
        "enableHnS": {
            "value": true
        }
    }
}
```
#### Outputs

The deployment of storageAccount outputs the ID of the storageAccount created:
 
   **storageAccountResourceId**

#### Secrets

No Secrets will be created during the provisioning for this version of the Component

#### YAML Pipeline deployment

The following [YAML pipeline stage](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/stages?view=azure-devops&tabs=yaml) can be used as a reference to deploy the storageAccount:

```yml
- stage: storageAccountDeployment
  jobs:
  - template: /cicd/templates/pipeline.jobs.deploy.yml@IaC
    parameters:
      moduleName: storageaccount
      modulePath: $(modulesPath)/storageaccount/1.0
      displayName: Deploy_storageAccount
      deploymentBlocks:
      - path: {path_to_configuration_file}
      checkoutRepositories:
      - IaC
```

## Security Framework Controls

See Security Framework in article [Cloud Native Security](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/413/Cloud-Native-Security)



## Policies

The following Policies are in place (see article [Foundation Design](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/410/Foundation-Design) > [Governance](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/496/Governance) in Wiki to learn more about Policies)

| Policy type | Policy id | Policy Display Name | Policy description | Allowed values | Effect
| - | - | - | - | - | -
| custom | `pxs-cn-sa-encryption-pd` | Enable or Disable Audit on InfraStructure Encryption of storageAccounts | This policy audits/disables the use of Infrastructure Encryption in storageAccounts | Audit, Deny, Disabled | auditInfrastructureEncryptionEffect
| custom | `pxs-cn-sa-allowpublicaccess-pd` | Enable or Disable Audit on Allowing Public access on Blob storageAccount | This policy audits the property which controls the public access | Audit, Disabled | auditAllowPublicAccessEffect
| custom | `pxs-cn-sa-tls-pd` | Restrict minimumTls version to 1_2 for any StorageAccount | This policy audits the Transport Layer Security version for TLS1_2 | Audit, Deny, Disabled | MinimumTlsVersion
| custom | `pxs-cn-sa-softdelete-pd` | Enable or Disable Audit on Soft Delete Blob storageAccount | This policy audits/disables the usage of private endpoint for storageAccounts | Audit, Deny, Disabled | auditSoftDelete
| BuiltIn | `allowedSKUs` | Allowed storage account SKUs | This policy audits/disables the Soft Delete setting for Blob kind of storageAccounts | Audit, Disabled | Deny
| BuiltIn | `HttpsTrafficOnlyEffect` | Secure transfer to storage accounts should be enabled | Policy to audit whether Https is the only allowed transfer technology | Audit, Deny, Disabled | HttpsTrafficOnlyEffect
