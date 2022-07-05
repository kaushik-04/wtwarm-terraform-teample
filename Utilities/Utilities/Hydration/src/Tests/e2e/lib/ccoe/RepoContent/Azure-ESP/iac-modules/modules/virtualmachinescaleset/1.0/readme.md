- [Virtual Machine Scale Set 1.0](#virtual-machine-scale-set-10)
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

# Virtual Machine Scale Set 1.0

## Release Notes

**[2021.01.31]**
> + Virtual Machine Scale Set updated with the following parameters:
>   - **key Vault id**. get administrator password from keyvault
>   - **workspaceId**. Required. Log Analytics workspace ID to be configured as part of the diagnostic settings
> 
> + The following Azure Policies have been published:
>   - **Cloud-Native management group**.
>       - **7c1b1214-f927-48bf-8882-84f0af6588b1**.  It is recommended to enable Logs so that activity trail can be recreated when investigations are required in the event of an incident or a compromise. 
>       - **efbde977-ba53-4479-b8e9-10b957924fbf**.  This policy audits any Windows/Linux Virtual Machine Scale Sets if the Log Analytics agent is not installed.
>       - **2c89a2e5-7285-40fe-afe0-ae8654b92fb2**.  This policy audits any unattached disk without encryption enabled.
>       - **4da35fc9-c9e7-4960-aec9-797fe7d9051d**.  Azure Defender for servers provides real-time threat protection for server workloads and generates hardening recommendations as well as alerts about suspicious activities.
>       - **c3f317a7-a95c-4547-b7e7-11017ebdf2fe**.  Audit whether there are any missing system security updates and critical updates that should be installed to ensure that your Windows and Linux virtual machine scale sets are secure.
>       - **3c735d8a-a4ba-4a3a-b7cf-db7754cf57f4**.  Audit the OS vulnerabilities on your virtual machine scale sets to protect them from attacks.
>       - **pxs-cn-vmss-antimalware-pd**.  This policy audits any Windows virtual machine Scale Set not configured with automatic update of Microsoft Antimalware protection signatures.
>       - **pxs-cn-vmss-bootdiagnostics-pd**.  This policy enforce to enable boot diagnostics for Virtual Machine Scale Sets. 
>       - **pxs-cn-vmss-dependcy-pd**.  This policy audits any Windows/Linux Virtual Machine Scale Sets if the Dependency agent is not installed.
>       - **pxs-cn-vmss-managed-disk-pd**.  This policy enforces VMs scale sets to use managed disks
>       - **pxs-cn-vmss-os-restriction-pd**.  This policy enforce the use of specific SKU imgages for the creation of Virtual Machine Scale Set
>       - **pxs-cn-vmss-os-update-pd**.  This policy audit if Guest operating system updates is enabled on virtual machine scale set

## Component Design

The Design can be found in the [Product Catalogue](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/446/Product-Catalog) - [Key Vault 1.0](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/448/KeyVault)

## Operations

### Deployment

#### Parameters

The following JSON serves as an example for the parameters

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "vmssName": {
            "value": "pxsvmss"
        },
        "instanceCount": {
            "value": 2
        },
        "vmSku": {
            "value": "Standard_DS1_v2"
        },
        "windowsOSVersion": {
            "value": "2019-Datacenter"
        },
        "osDiskType": {
            "value": "StandardSSD_LRS"
        },
        "OSInGuestUpdate": {
            "value": true
        },
        "resourcegroupvirtualnetwork": {
            "value": "pxs-cn-mtonneau-d-shared-rg"
        },
        "virtualnetwork": {
            "value": "pxs-cn-mtonneau-d-shared-vnet"
        },
        "subnet": {
            "value": "Default"
        },
        "adminUsername": {
            "value": "win-admin"
        },
        "adminPassword": {
            "reference":  {
                "keyVault":  {
                  "id":  "/subscriptions/28f0dade-b402-41df-b95f-d0d785721d24/resourceGroups/pxs-cn-mtonneau-d-vmss-rg/providers/Microsoft.KeyVault/vaults/pxs-cn-mtonneau-d-kv"
                  },
                "secretName":  "win-password"
             }
        },
        "loganalyticsworkspaceid": {
            "value": "/subscriptions/28f0dade-b402-41df-b95f-d0d785721d24/resourcegroups/pxs-cn-mtonneau-d-shared-rg/providers/microsoft.operationalinsights/workspaces/pxs-cn-mtonneau-d-shared-la"
        }
    }
}
```
#### Outputs

No Outputs will be created as a result of the provisioning for this version of the Component

#### Secrets

No Secrets will be created during the provisioning for this version of the Component

#### YAML Pipeline deployment

The following [YAML pipeline stage](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/stages?view=azure-devops&tabs=yaml) can be used as a reference to deploy the Virtual Machine Scale Set:

```yml
- stage: keyVaultDeployment
  jobs:
  - template: /cicd/templates/pipeline.jobs.deploy.yml@IaC
    parameters:
      moduleName: keyvault
      moduleVersion: 1.0
      displayName: Deploy_vmss
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
| - | - | - | - | - | - |
| built-in | `7c1b1214-f927-48bf-8882-84f0af6588b1` | Diagnostic logs in Virtual Machine Scale Sets should be enabled | It is recommended to enable Logs so that activity trail can be recreated when investigations are required in the event of an incident or a compromise.| `"AuditIfNotExists"`, `"Disabled"` | AuditIfNotExists
| built-in | `efbde977-ba53-4479-b8e9-10b957924fbf` | The Log Analytics agent should be installed on Virtual Machine Scale Sets | This policy audits any Windows/Linux Virtual Machine Scale Sets if the Log Analytics agent is not installed. | `"AuditIfNotExists"`, `"Disabled"` | AuditIfNotExists
| built-in | `2c89a2e5-7285-40fe-afe0-ae8654b92fb2` | Unattached disks should be encrypted | This policy audits any unattached disk without encryption enabled. | `"Audit"`, `"Disabled"` | Audit
| built-in | `4da35fc9-c9e7-4960-aec9-797fe7d9051d` | Azure Defender for servers should be enabled | Azure Defender for servers provides real-time threat protection for server workloads and generates hardening recommendations as well as alerts about suspicious activities. | `"AuditIfNotExists"`, `"Disabled"` | AuditIfNotExists
| built-in | `c3f317a7-a95c-4547-b7e7-11017ebdf2fe` | System updates on virtual machine scale sets should be installed | Audit whether there are any missing system security updates and critical updates that should be installed to ensure that your Windows and Linux virtual machine scale sets are secure. | `"AuditIfNotExists"`, `"Disabled"` | AuditIfNotExists
| built-in | `3c735d8a-a4ba-4a3a-b7cf-db7754cf57f4` | Vulnerabilities in security configuration on your virtual machine scale sets should be remediated | Audit the OS vulnerabilities on your virtual machine scale sets to protect them from attacks. | `"AuditIfNotExists"`, `"Disabled"` | AuditIfNotExists
| custom | `pxs-cn-vmss-antimalware-pd` | "Microsoft Antimalware for Azure should be configured to automatically update protection signatures. (Virtaul Machine Scale Set)" | This policy audits any Windows virtual machine Scale Set not configured with automatic update of Microsoft Antimalware protection signatures. | `"AuditIfNotExists"`, `"Disabled"` | AuditIfNotExists
| custom | `pxs-cn-vmss-bootdiagnostics-pd` | Guest OS updates enabled on virtual machine scale set | This policy enforce to enable boot diagnostics for Virtual Machine Scale Sets. | `"Audit", "Deny", "Disabled"` | AuditIfNotExists
| custom | `pxs-cn-vmss-dependcy-pd` | The Dependency agent should be installed on Virtual Machine Scale Sets | This policy audits any Windows/Linux Virtual Machine Scale Sets if the Dependency agent is not installed. | `"AuditIfNotExists"`, `"Disabled"` | AuditIfNotExists
| custom | `pxs-cn-vmss-extensions-pd` | Only approved VM extensions should be installed for Virtual Machine Scale Set | This policy governs the virtual machine scale set extensions that are not approved. | `"Audit", "Deny", "Disabled"` | AuditIfNotExists
| custom | `pxs-cn-vmss-managed-disk-pd` | Enforce VM scale sets to use managed disks | This policy enforces VMs scale sets to use managed disks | `"Audit", "Deny", "Disabled"` | AuditIfNotExists
| custom | `pxs-cn-vmss-os-restriction-pd` | OS Restriction for the creation Virtual Machine Scale Set | This policy enforce the use of specific SKU imgages for the creation of Virtual Machine Scale Set |  `"Audit", "Deny", "Disabled"` | AuditIfNotExists
| custom | `pxs-cn-vmss-os-update-pd` | Audit if Guest operating system updates is enabled on virtual machine scale set | This policy governs the virtual machine scale setextensions that are not approved. | `"Audit", "Deny", "Disabled"` | AuditIfNotExists

