[[_TOC_]]

# Secrets Management

## Integrate Key Vault in ARM templates

ARM Templates can [retrieve values from secrets stored in an Azure Key Vault](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-keyvault-parameter) during a deployment. This ability will enable 2 scenarios for secret management when implementing ARM templates

### Using secrets stored in a Key Vault

When a deployment needs a secret stored in a Key Vault, such as an admin password, we can use the parameters file to reference the secret in the key vault by passing the resource identifier of the key vault and the name of the secret:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
      "adminLogin": {
        "value": "exampleadmin"
      },
      "adminPassword": {
        "reference": {
          "keyVault": {
          "id": "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.KeyVault/vaults/<vault-name>"
          },
          "secretName": "ExamplePassword"
        }
      },
      "sqlServerName": {
        "value": "<your-server-name>"
      }
  }
}
```

For this approach to work, we need the following prerequisites in the Key Vault.
- The user who deploys the template must have the [`Microsoft.KeyVault/vaults/deploy/action`](https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsoftkeyvault) permission for the scope of the [resource group and key vault](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/key-vault-parameter?tabs=azure-cli#grant-access-to-the-secrets).

### Storing secrets in a Key Vault during deployment

Not only retrieving secrets is possible, we can also store secrets in Key Vaults during a deployment. This will enable scenarios in which some modules will generate secrets as part of their deployment that can then be referenced by other modules. Then the secret will only live in the Key Vault and will never be part of the repository.

Resources of type [`Microsoft.KeyVault vaults/secrets`](https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets) can be added to any template to create a Key Vault secret during the deployment.

E.g. The template below will store the storage account endpoints as secrets of a Key Vault

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "type": "string",
      "metadata": {
        "description": "Specifies the name of the storage account."
      }
    },
    "keyVaultName": {
      "type": "string",
      "metadata": {
        "description": "Specifies the name of the key vault."
      }
    },
    "secretName": {
      "type": "string",
      "metadata": {
        "description": "Specifies the name of the secret that you want to create."
      }
    }
  },
  "resources": [
    {
        "type": "Microsoft.Storage/storageAccounts",
        "apiVersion": "2019-04-01",
        "name": "[parameters('storageAccountName')]",
        "location": "[resourceGroup().location]",
        "sku": {
            "name": "Standard_LRS"
        },
        "kind": "Storage",
        "properties": {}
    },
    {
      "type": "Microsoft.KeyVault/vaults/secrets",
      "name": "[concat(parameters('keyVaultName'), '/', parameters('secretName'))]",
      "apiVersion": "2018-02-14",
      "location": "[resourceGroup().location]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]"
      ],
      "properties": {
        "value": "[reference(parameters('storageAccountName')).primaryEndpoints.blob]"
      }
    }
  ]
}
```

## Integrate Key Vault with Azure DevOps

Key Vaults can be linked to an [Azure DevOps variable group](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups) so that secrets in this Key Vault can be reused in the Azure DevOps pipelines.

![Link Azure Key Vault to an Azure DevOps variable group](/.attachments/images/Learning-resources/Infrastructure-as-Code/link-azure-key-vault-variable-group.png)

For this scenario, we must consider:

- Only the secret names are mapped to the variable group, not the secret values. The latest version of the value of each secret is fetched from the vault and used in the pipeline linked to the variable group during the run.
- Any changes made to existing secrets in the key vault, such as a change in the value of a secret, will be made available automatically to all the pipelines in which the variable group is used.
- When new secrets are added to the vault, or a secret is deleted from the vault, the associated variable groups are not updated automatically. The secrets included in the variable group must be explicitly updated in order for the pipelines using the variable group to execute correctly.
- Azure Key Vault supports storing and managing cryptographic keys and secrets in Azure. Currently, Azure Pipelines variable group integration supports mapping only secrets from the Azure key vault. Cryptographic keys and certificates are not supported.

Linking Key Vault to Azure DevOps will allow scenarios in which [deployments will update secrets in Key Vaults](#storing-secrets-in-a-key-vault-during-deployment) that will be later used in Azure DevOps pipelines to avoid hardcoded secrets in the repository

## Integrate Key Vault in the module deployment logic

Same as with ARM Templates, the [module deployment logic](/Certified-Components/Design-principles.md) can implement secret management logic leveraging the [Az.KeyVault](https://docs.microsoft.com/en-us/powershell/module/Az.KeyVault/) module.

## Avoid credentials management by using Managed Identities

[Managed identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview) for Azure resources is a feature of [Azure Active Directory](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-whatis) designed to keep the credentials secure by automatically managing identity in Azure AD without any credentials in your code.

With Managed Identities, credential rotation is controlled by the resource provider that hosts the Azure resource. The following diagram shows how managed service identities work with Azure virtual machines (VMs):

![Credential rotation in Managed Identities](/.attachments/images/Learning-resources/Infrastructure-as-Code/managed-identity-credential-rotation.png)

Managed identities for Azure resources can be used to authenticate to services that support Azure AD authentication. For a list of Azure services that support the managed identities for Azure resources feature, see [Services that support managed identities for Azure resources](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/services-support-managed-identities).

# Learning Resources

1. [Implementing Managed Identities for Microsoft Azure Resources | Pluralsight](https://www.pluralsight.com/courses/microsoft-azure-resources-managed-identities-implementing)

# References

1. [Use Azure Key Vault to pass secure parameter value during deployment | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/key-vault-parameter?tabs=azure-cli)
2. [Azure resource providers operations | Microsoft Docs](https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations)
3. [Use Azure Key Vault to pass secure parameter value during deployment | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/key-vault-parameter?tabs=azure-cli)
4. [Microsoft.KeyVault vaults/secrets template reference | Microsoft Docs](https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/secrets)
5. [Add & use variable groups | Microsoft Docs](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml)
6. [Az.KeyVault | Microsoft Docs](https://docs.microsoft.com/en-us/powershell/module/Az.KeyVault/?view=azps-4.4.0)
7. [What are managed identities for Azure resources? | Microsoft Docs](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)
8. [What is Azure Active Directory? | Microsoft Docs](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-whatis)
9. [Services that support managed identities for Azure resources | Microsoft Docs](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/services-support-managed-identities)