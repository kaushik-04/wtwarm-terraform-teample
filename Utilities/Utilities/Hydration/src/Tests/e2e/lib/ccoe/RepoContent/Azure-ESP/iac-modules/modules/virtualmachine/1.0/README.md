- [Virtual Machine 1.0](#virtual-machine-10)
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

# Virtual Machine 1.0



**[2021.02.04]**

> + Initial version of Virtual Machine component with the following parameters enabled: 
>   - **location**. Required, Location for the Azure Virtual Machine.
>   - **networkInterfaceName** Required. Name of the NIC linked to the Azure Virtual Machine.
>   - **subnetName** Required. Name of the subnet in the Vnet linked to the Azure Virtual Machine.
>   - **virtualNetworkId** Required. ID of the Vnet linked to the Azure Virtual Machine.
>   - **virtualMachineName** Required. Name of the Azure Virtual Machine,
>   - **virtualMachineComputerName** Required. Computername of the Azure Virtual Machine.
>   - **virtualMachineRG** Required. Resource group of the Azure Virtual Machine.
>   - **osDiskType** Required. Type of the disk used in the Azure Virtual Machine.
>   - **virtualMachineSize** Required. The size (RAM, CPU...) of the Azure Virtual Machine.
>   - **adminUsername** Required. Username of the admin of the Azure Virtual Machine.
>   - **adminPassword** Required. ID of the Key Vault where the admin password is stored for the Azure Virtual Machine.
>   - **patchMode** Optional. The way of how the Azure Virtual Machine is patched.
>   - **imageReference** Required. The image used for the Azure Virtual Machine.
>   - **tags** Required. Resource tags.
>   - **storageAccountName** Required. Name of the storage account used for the diagnostic settings.
>   - **storageAccountId** Required. ID of the storage account used for the diagnostic settings.

## Component Design

The Design can be found in the [Product Catalogue](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/446/Product-Catalog) - [Virtual Machine 1.0](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/463/Virtual-Machine)

## Design

Prerequisites

The following prerequisites need to be in place before this Component can be provisioned:

- Azure Key Vault with admin password in secret
- Azure Virtual Network with subnet
- Azure Storage Account for the Diagnostics Settings
- Azure Log Analytics Workspace


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
            "value": "westeurope"
        },
        "networkInterfaceName": {
            "value": "pxs-vm-s-ccoe-vmdemo-ni"
        },
        "subnetName": {
            "value": "default"
        },
        "virtualNetworkId": {
            "value": "/subscriptions/b9bc4b81-2c1d-46bb-a1d6-6e0970f05f3c/resourceGroups/pxs-cn-s-ccoe-vmdemo-rg/providers/Microsoft.Network/virtualNetworks/pxs-cn-s-ccoe-vmdemo-vnet"
        },
        "virtualMachineName": {
            "value": "PxsCcoeVmDemo"
        },
        "virtualMachineComputerName": {
            "value": "PxsCcoeVmDemopc"
        },
        "virtualMachineRG": {
            "value": "pxs-cn-s-ccoe-vmdemo-rg"
        },
        "osDiskType": {
            "value": "StandardSSD_LRS"
        },
        "virtualMachineSize": {
            "value": "Standard_D2s_v3"
        },
        "adminUsername": {
            "value": "VMdemoAdmin"
        },
        "adminPassword": {
            "reference": {
                "keyVault": {
                    "id": "/subscriptions/b9bc4b81-2c1d-46bb-a1d6-6e0970f05f3c/resourceGroups/pxs-cn-s-ccoe-vmdemo-rg/providers/Microsoft.KeyVault/vaults/pxs-cn-s-ccoe-vmdemo-kvt"
                },
                "secretName": "DefaultAdminPasswordSecret"
            }
        },
        "patchMode": {
            "value": "AutomaticByOS"
        },
        "imageReference": {
            "value": {
                "publisher": "MicrosoftWindowsServer",
                "offer": "WindowsServer",
                "sku": "2019-datacenter-gensecond",
                "version": "latest"
            }
        },
        "tags": {
            "value": {
                "environment": "s",
                "cost-center": "azure",
                "application-id": "azure",
                "deployment-id": "test"
            }
        },
        "storageAccountName": {
            "value": "pxscnsccoevmdemostg"
        },
        "storageAccountId": {
            "value": "/subscriptions/b9bc4b81-2c1d-46bb-a1d6-6e0970f05f3c/resourceGroups/pxs-cn-s-ccoe-vmdemo-rg/providers/Microsoft.Storage/storageAccounts/pxscnsccoevmdemostg"
        }
    }
}
```
#### Outputs

No Outputs will be created as a result of the provisioning for this version  of the Component

#### Secrets

No Secrets will be created during the provisioning for this version of the Component

#### YAML Pipeline deployment

The following [YAML pipeline stage](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/stages?view=azure-devops&tabs=yaml) can be used as a reference to deploy the Virtual Machine:

```yml
- stage: virtualMachineDeployment
    dependsOn: Policy_Assignment_Deployment
    jobs:
      - template: /cicd/templates/pipeline.jobs.deploy.yml@IaC
        parameters:
          removeDeployment: "${{ parameters.removeDeployment }}"
            moduleName: virtualmachine
            modulePath: $(modulesPath)/virtualmachine/1.0
            displayName: Deploy_virtualmachine
            deploymentBlocks:
            - path: {path_to_configuration_file}
            checkoutRepositories:
            - IaC
```
<!-- Everything below this still needs to be revision!!!
## Security Framework Controls

See Security Framework in article [Cloud Native Security](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/413/Cloud-Native-Security)

| SCF # | Category | What | How | Category |
| - | - | - | - | - |
| SCF-IAM-01 | RBAC access control | IAM on all resources | A list of Service Principals object Ids can be provided as input to give them the role definition of 'Key Vault Administrator' or 'Key Vault Reader'
| SCF-TVI-07 | Azure Defender for Key Vault | Virus and malware protection | At subscription level -> delivered by Foundation Team
| SCF-TVI-03 | Resource Audit Logs | tbd -->

## Policies

The following Policies are in place (see article [Foundation Design](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/410/Foundation-Design) > [Governance](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/496/Governance) in Wiki to learn more about Policies)

| Policy type | Policy id | Policy Display Name | Policy description | Allowed values | Effect |
| - | - | - | - | - | - |
| custom | `pxs-cn-vm-antimalware-pd` | Microsoft Antimalware protection signatures configuration | This policy audits any Windows virtual machines not configured with automatic update of Microsoft Antimalware protection signatures |  | Audit |
| custom | `pxs-cn-vm-bootdiagnostics-pd` | Boot diagnostics for Virtual Machines should be enabled | This policy enforce to enable boot diagnostics for Virtual Machines |  | Audit |
| custom | `pxs-cn-vm-dependency-pd` | Dependency agent should be installed on Virtual Machines | This policy audits any Windows/Linux Virtual Machines if the Dependency agent is not installed | | AuditIfNotExists |
| custom | `pxs-cn-vm-extensions-pd` | Only approved VM extensions should be installed for Virtual Machines | This policy governs the virtual machines extensions that are not approved |  | Audit |
| custom | `pxs-cn-vm-os-restriction-pd` | OS Restriction for the creation Virtual Machine | This policy enforce the use of specific SKU images for the creation of Virtual Machine |  | Audit |
| built-in | `pxs-cn-vm-os-update-pd` | Audit if Guest operating system updates is enabled on virtual machine scale set | This policy governs the virtual machine extensions that are not approved |  | Audit|