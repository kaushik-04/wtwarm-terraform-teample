# Virtual Machine 1.0

| **Status** | <span style="color:orange">**DRAFT**</span> |
|--|--|
| **Version** | v0.2 |
| **Edited By** | Gerbaud Desmet, Zandro Wallaert |
| **Date** | 16/02/2021  |
| **Approvers** | Peter Theuns, Frederik de Ryck  |
| **Deployment documentation** | <link to GIT Module missing> |
| **To Do** |  |

[[_TOC_]]

## 1. Introduction

### 1.1. Service Description
This section provides guidance and some capabilities to enable customers to implement their own virtual machine components for both Windows and Linux. However, some specific features required (specific machine configuration, additional OS images or custom behaviors) **will be  responsibility of each Platform team**.

[Azure Virtual Machines](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/overview) (VM) is one of several types of [on-demand, scalable computing resources](https://docs.microsoft.com/en-us/azure/architecture/guide/technology-choices/compute-decision-tree) that Azure offers. Typically, you choose a VM when you need more control over the computing environment than the other choices offer.

An Azure VM gives you the flexibility of virtualization without having to buy and maintain the physical hardware that runs it. However, you still need to maintain the VM by performing tasks, such as configuring, patching, and installing the software that runs on it.

Azure virtual machines can be used in various ways. Some examples are:

- Development and test – Azure VMs offer a quick and easy way to create a computer with specific configurations required to code and test an application.
- Applications in the cloud – Because demand for your application can fluctuate, it might make economic sense to run it on a VM in Azure. You pay for extra VMs when you need them and shut them down when you don’t.
- Extended datacenter – Virtual machines in an Azure virtual network can easily be connected to your organization’s network.
The number of VMs that your application uses can scale up and out to whatever is required to meet your needs.

### 1.2. Shared Image Gallery
During the creation of an Azure VM, an image is used when the instances are deployed.  The [Azure Shared Image Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries) service simplifies custom image sharing across your organization. Custom images can be used to bootstrap configurations such as preloading applications, application configurations, and other OS configurations.

The Shared Image Gallery lets you share your custom VM images with others in your organization, within or across regions, within an AAD tenant. Choose which images you want to share, which regions you want to make them available in, and who you want to share them with. You can create multiple galleries so that you can logically group shared images.

The gallery is a top-level resource that provides full Azure role-based access control (Azure RBAC). Images can be versioned, and you can choose to replicate each image version to a different set of Azure regions. The gallery only works with Managed Images.

Shared Image Gallery is a service that helps you build structure and organization around your images. The Azure service provide the following features:

+ Global replication of images.
+ Versioning and grouping of images for easier management.
+ Highly available images with Zone Redundant Storage (ZRS) accounts in regions that support Availability Zones. ZRS offers better resilience against zonal failures.
+ Premium storage support (Premium_LRS).
+ Sharing across subscriptions, and even between Active Directory (AD) tenants, using RBAC.
+ Scaling your deployments with image replicas in each region.
+ Using a Shared Image Gallery you can share your images to different users, service principals, or AD groups within your organization. Shared images can be replicated to multiple regions, for quicker scaling of your deployments.

The Shared Image Gallery feature has multiple resource types:
| Resource | Description | 
| -- | -- | 
|Image source | This is a resource that can be used to create an image version in an image gallery. An image source can be an existing Azure VM that is either generalized or specialized, a managed image, a snapshot, a VHD or an image version in another image gallery. | 
| Image gallery | Like the Azure Marketplace, an image gallery is a repository for managing and sharing images, but you control who has access. | 
Image definition | Image definitions are created within a gallery and carry information about the image and requirements for using it internally. This includes whether the image is Windows or Linux, release notes, and minimum and maximum memory requirements. It is a definition of a type of image. |
| Image version | An image version is what you use to create a VM when using a gallery. You can have multiple versions of an image as needed for your environment. Like a managed image, when you use an image version to create a VM, the image version is used to create new disks for the VM. Image versions can be used multiple times. |

## 2. Architecture

### 2.1. High Level Design

![Virtual Machine Architecture](/.attachments/Vm-architecture-diagram.png =700x)

### 2.2. Availability

[Availability zones](https://docs.microsoft.com/en-us/azure/availability-zones/az-overview) expand the level of control you have to maintain the availability of the applications and data on your VMs. An Availability Zone is a physically separate zone, within an Azure region. There are three Availability Zones per supported Azure region.

Each Availability Zone has a distinct power source, network, and cooling. By architecting your solutions to use replicated VMs in zones, you can protect your apps and data from the loss of a datacenter. If one zone is compromised, then replicated apps and data are instantly available in another zone.

No availability will be configured as part of this component. If any availability wants to be provided, then [Virtual Machine Scale Sets](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/465/Virtual-Machine-Scale-Set) can be deployed and configured for such purpose.

### 2.3. Generation 2 Virtual Machines

Generation 2 VMs support key features that aren't supported in generation 1 VMs. These features include increased memory, Intel Software Guard Extensions (Intel SGX), and virtualized persistent memory (vPMEM). Generation 2 VMs running on-premises, have some features that aren't supported in Azure yet. For more information, see the [Features and capabilities section](https://docs.microsoft.com/en-us/azure/virtual-machines/generation-2#features-and-capabilities).

Generation 2 VMs use the new UEFI-based boot architecture rather than the BIOS-based architecture used by generation 1 VMs. Compared to generation 1 VMs, generation 2 VMs might have improved boot and installation times. For the scope of this component, only Standard_D2s size will be deployed, according to the environment. For more information on general VM sizes supported in Azure, please [check here](https://docs.microsoft.com/en-us/azure/virtual-machines/generation-2).

### 2.4. Managed Disks

[Azure managed disks](https://docs.microsoft.com/en-us/azure/virtual-machines/managed-disks-overview?toc=/azure/virtual-machines/linux/toc.json&bc=/azure/virtual-machines/linux/breadcrumb/toc.json) are block-level storage volumes that are managed by Azure and used with Azure Virtual Machines. Managed disks are like a physical disk in an on-premises server but, virtualized. With managed disks, all you have to do is specify the disk size, the disk type, and provision the disk. Once you provisioned the disk, Azure handles the rest.

### 2.5. Security

#### 2.5.1 Just In Time Access

Lock down inbound traffic to your Azure Virtual Machines with Azure Security Center's [just-in-time (JIT)](https://docs.microsoft.com/en-us/azure/security-center/just-in-time-explained) virtual machine (VM) access feature. This reduces exposure to attacks while providing easy access when you need to connect to a VM.

#### 2.5.2 Azure Bastion

*Azure Bastion* is a PaaS service provisioned inside the Virtual Network and provide a secure way to connect to Virtual Machines through RDP/SSH, whitout needing a Public IP address.  The use of Azure Bastion will be investigated in a later release

#### 2.5.3 windows update

Windows update are installed through Automatic VM guest patching.  This feature has the following characteristics:  

+ Patches classified as Critical or Security are automatically downloaded and applied on the VM.
+ Patches are applied during off-peak hours in the VM's time zone.
+ Patch orchestration is managed by Azure and patches are applied following availability-first principles.
+ Virtual machine health, as determined through platform health signals, is monitored to detect patching failures.
+ Works for all VM sizes.

#### 2.5.3.1 prerequisites

Feature needs to be activated on the subscription before it can be used during the deployment of Virtual Machines:

1. Use the Register-AzProviderFeature cmdlet to enable the preview for your subscription: <br>
`Register-AzProviderFeature -FeatureName InGuestAutoPatchVMPreview -ProviderNamespace Microsoft.Compute`
2. Feature registration can take up to 15 minutes. To check the registration status: <br> 
`Get-AzProviderFeature -FeatureName InGuestAutoPatchVMPreview -ProviderNamespace Microsoft.Compute`
3. Once the feature is registered for your subscription, complete the opt-in process by propagating the change into the Compute resource provider: <br> `Register-AzResourceProvider -ProviderNamespace Microsoft.Compute`

#### 2.5.3.2 ARM template

To enable automatic VM Guest patching, API version must be 2020-06-01 or higher and the following property has to be added in the ARM template of the Virtual Machine. The [Azure VM Agent](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/agent-windows) must be installed on the Virtual Machine.

```
{
    "properties": {
        "osProfile": {
            "windowsConfiguration": {
                "provisionVMAgent": true,
                "enableAutomaticUpdates": true,
                "patchSettings": {
                    "patchMode": "AutomaticByPlatform"
                }
            }
        }
    }
}
```

#### 2.5.3.3 Supported OS images

the following OS images are currently supported for Automatic VM Guest patching:
| Publisher  | OS Offer  | Sku
| -- | -- | -- |
| MicrosoftWindowsServer | WindowsServer | 2012-R2-Datacenter
| MicrosoftWindowsServer | WindowsServer | 2016-Datacenter
| MicrosoftWindowsServer | WindowsServer | 2016-Datacenter-Server-Core
| MicrosoftWindowsServer | WindowsServer | 2019-Datacenter
| MicrosoftWindowsServer | WindowsServer | 2019-Datacenter-Core

#### 2.5.4 Backup

The customer is responsible for backup and restoration of the virtual machines. A recovery vault resource is provided for each Landing Zone.

#### 2.5.5 Antimalware

[Microsoft Antimalware](https://docs.microsoft.com/en-us/azure/security/fundamentals/antimalware), helps protect Azure Virtual Machines from viruses, spyware,...

Core features of Microsoft Antimalware:

+ Real-time protection - monitors activity in Cloud Services and on Virtual Machines to detect and block malware execution.
+ Scheduled scanning - Scans periodically to detect malware, including actively running programs.
+ Malware remediation - automatically takes action on detected malware, such as deleting or quarantining malicious files and cleaning up malicious registry entries.
+ Signature updates - automatically installs the latest protection signatures (virus definitions) to ensure protection is up-to-date on a pre-determined frequency.
+ Antimalware Engine updates – automatically updates the Microsoft Antimalware engine.
+ Antimalware Platform updates – automatically updates the Microsoft Antimalware platform.
+ Active protection - reports telemetry metadata about detected threats and suspicious resources to Microsoft Azure to ensure rapid response to the evolving threat landscape, as well as enabling real-time synchronous signature delivery through the Microsoft Active Protection System (MAPS).
+ Samples reporting - provides and reports samples to the Microsoft Antimalware service to help refine the service and enable troubleshooting.
+ Exclusions – allows application and service administrators to configure exclusions for files, processes, and drives.
+ Antimalware event collection - records the antimalware service health, suspicious activities, and remediation actions taken in the operating system event log and collects them into the customer’s Azure Storage account.

#### 2.5.6 Monitoring

Azure Security Center and Azure Monitor are enabled to Monitor the different resources within the Landing Zone.
prerequisites for Azure Disk Encryption:

+ Azure Disk Encryption is not available on Basic, A-series VMs, or on virtual machines with a less than 2 GB of memory.
+ Azure Disk Encryption is also available for VMs with premium storage.
+ Azure Disk Encryption is not available on Generation 2 VMs. For more exceptions, see Azure Disk Encryption: Unsupported scenarios.
+ Azure Disk Encryption is not available on VM images without temp disks (Dv4, Dsv4, Ev4, and Esv4). See Azure VM sizes with no local temporary disk.

#### 2.5.7 Azure Disk Encryption

Azure Disk Encryption (ADE) provides the possibility to encrypt data on the disk by using bitlocker to encrypt the volume and Key Vault to manage the disk encryption keys.

TBD
    https://docs.microsoft.com/en-us/azure/security/fundamentals/azure-marketplace-images

#### 2.5.8 Azure role-based access control

Built-in Roles Virtual Machine:

| **Built-in role**                        | **Description**          | **Accounts**|
|----|----------------------|----|
| Classic Virtual Machine Contributor             | Lets you manage classic virtual machines, but not access to them, and not the virtual network or storage account they're connected to. |    |
| Virtual Machine Administrator Login       | View Virtual Machines in the portal and login as administrator                                                                               |    |
| Virtual Machine Contributor             | Lets you manage virtual machines, but not access to them, and not the virtual network or storage account they're connected to.       |    |
| Virtual Machine User Login             | View Virtual Machines in the portal and login as a regular user.       |    |

### 2.6. Service Limits

+   [Azure limits per subscription](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits#application-insights-limits)
+   [Virtual Machine limits](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#virtual-machines-limits---azure-resource-manager)
 
## 3. Service Level Agreement
### 3.1 Virtual Machine

| Description | Service Level Agreement |
|--|--|
| Virtual Machines deployed in Availability Zones | >99.99% |
| Virtual Machines deployed in Availability Sets | >99.95% |
| Single Virtual Machine using Premium Storage | >99.90% |
| Single Virtual Machine using Standard SSD Storage | >99.50% |
| Single Virtual Machine using Standard HDD Storage | >95.00% |
## 4. Service Provisioning

### 4.1. Prerequisites

The following Azure resources need to be in place before this Certified Service can be provisioned:

+ Resource Group
+ Virtual Network (& NSG)
+ Application gateway & WAF/Application proxy(/NVA?) (Pre-authentication!)
+ Azure Key Vault
+ Log Analytics Workspace
+ Storage Account for Diagnostic logging
+ Azure Recovery vaults for Backup ***TBD***

### 4.2. Deployment parameters

|                                     | NON-PRODUCTION                                                        | PRODUCTION                                                            | Implementation | Implementation Status |
|-------------------------------------|-----------------------------------------------------------------------|-----------------------------------------------------------------------|----------------|-----------------------|
|                                     | Windows                                                               | Windows                                                               |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Subscription                        |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**Implemented** (By Policy)</span>      |
| Resource Group                      |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**Implemented**</span>      |
| VM Name                             |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**Implemented**</span>      |
| Admin Username                      |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**Implemented**</span>      |
| Admin Password                      | Secret taken from Key Vault                                           | Secret taken from Key Vault                                           |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Key Vault ID                        |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**Implemented**</span>      |
| Region                              | Vnet region                                                           | Vnet region                                                           |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**Implemented**</span>      |
| Availability                        | No Redundancy required                                                | No Redundancy required                                                |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Image                               | Windows images (TBD & enforced by policy)                             | Windows images (TBD & enforced by policy)                             |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**Implemented**</span>      |
| Azure Spot instance                 | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Size                                | Fixed choices by policy                                               | Fixed choices by policy                                               |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**Implemented** (By Policy)</span>      |
| Public Inbound ports                | None                                                                  | None                                                                  |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| OS Disk type                        | Standard SSD                                                          | Premium SSD                                                           |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Encryption type                     | Encryption at Rest with platform Key                                  | Encryption at Rest with platform Key                                  |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Data Disk (Attach an existing disk) | Yes                                                                   | Yes                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Use Managed Disk                    | Yes                                                                   | Yes                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Ephemeral OS Disk                   | No                                                                    | No                                                                    |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Virtual Network                     | Existing (coming from Platform)                                       | Existing (coming from Platform)                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**Implemented**</span>      |
| Subnet                              |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**Implemented**</span>      |
| Public IP                           | No                                                                    | No                                                                    |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| NIC network security group          | None (use Vnet NSG)                                                   | None (use Vnet NSG)                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Accelerated networking              | Off                                                                   | On                                                                    |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Load balancing                      | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Azure Security Center               | Your subscription is protected by Azure Security Center standard plan | Your subscription is protected by Azure Security Center standard plan |  <span style="color:grey">**N/A**</span>                |  <span style="color:green">**Implemented**</span>      |
| Boot diagnostics                    | On                                                                    | On                                                                    |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented** (By Policy)</span>      |
| OS guest diagnostics                | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| System assigned managed identity    | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Login with AAD credentials          | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Enable auto-shutdown                | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Enable backup                       | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Patch Installation                  | OS-orchestrated patching                                              | OS-orchestrated patching                                              |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Extensions                          | Network Watcher Agent for Windows                                     | Network Watcher Agent for Windows                                     |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
|                                     | Microsoft Antimalware (by policy)                                     | Microsoft Antimalware (by policy)                                     |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
|                                     | Microsoft Dependency Agent (by policy)                                | Microsoft Dependency Agent (by policy)                                |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
|                                     | Azure Monitor Windows Agent (by policy)                               | Azure Monitor Windows Agent (by policy)                               |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| VM Generation                       | v2                                                                    | v2                                                                    |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
| Tags                                |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**Implemented**</span>      |
| Domain Join (After VM creation)     | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**Implemented**</span>      |
|                                     |                                                                       |                                                                       |                |                       |

<!-- | Recovery Services vault         | Existing (coming from Platform)           | Existing (coming from Platform)         |  <span style="color:green">**PARAMETER**</span>         |     <span style="color:grey">**N/A**</span>           |
     | Backup Policy                   | DefaultPolicy                             | DefaultPolicy                           |  <span style="color:grey">**N/A**</span>                |     <span style="color:grey">**N/A**</span>           | 

Add file integrity by using policy TBD
Disk encryption -> ADE and/or bitlocker
-->

### 4.3 Policies

### 4.3.1. Policies Definiations

The following policies are grouped within a single Policy Initiative **pxs-cn-vm-pi** :

The following Policies are in place (see article [Foundation Design](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/410/Foundation-Design) > [Governance](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/496/Governance) in Wiki to learn more about Policies)

| Policy type | Policy id | Policy Display Name | Parameter | Allowed values |
| --- | --- | --- | --- | --- |
| custom   | `pxs-cn-vm-antimalware-pd` | Microsoft Antimalware protection signatures configuration                                                          | antimalwareeffect | `"AuditIfNotExists"`, `"Disabled"` |
| custom   | `pxs-cn-vm-bootdiagnostics-pd` | Boot diagnostics for Virtual Machines should be enabled                                                        | bootdiagnosticseffect | `"Audit"`, `"Deny"`, `"Disabled"` |
| custom   | `pxs-cn-vm-dependency-pd` | Dependency agent should be installed on Virtual Machines                                                            | dependencyagenteffect | `"AuditIfNotExists"`, `"Disabled"` |
| custom   | `pxs-cn-vm-extensions-pd` | Only approved VM extensions should be installed for Virtual Machines                                                | vmextensionseffect <br> approvedExtensions | `"Audit"`, `"Deny"`, `"Disabled"`, `Array of approved extensions` |
| custom   | `pxs-cn-vm-os-restriction-pd` | OS Restriction for the creation Virtual Machine                                                                 | osrestrictioneffect <br> allowedWindowsSKUImages | `"Audit"`, `"Deny"`, `"Disabled"` |
| custom   | `pxs-cn-vm-manageddisk-pd` | Enforce managed disk usage                                                                                         | manageddiskeffect | `"Audit"`, `"Deny"` |
| custom   | `pxs-cn-vm-deploy-da-windows-pd ` | Deploy Dependency agent for Windows virtual machines                                                        | Effect <br> listOfImageIdToInclude | `"DeployIfNotExists"`, `Array of custom images` |
| custom   | `pxs-cn-vm-deploy-iaa-windows-pd` | Deploy IaaS Anti-Malware agent for Windows virtual machines                                                 | Effect <br> listOfImageIdToInclude  | `"DeployIfNotExists"`, `Array of custom images` |
| custom   | `pxs-cn-vm-deploy-laa-windows-pd` | Deploy Log Analytics agent for Windows virtual machines                                                     | Effect <br> logAnalytics <br> listOfImageIdToInclude | `"DeployIfNotExists"`, `Log Analytics Workspace ID`, `Array of custom images` |
| custom   | `pxs-cn-vm-deploy-nwa-windows-pd` | Deploy Network Watcher agent for Windows virtual machines                                                   | Effect <br> listOfImageIdToInclude  | `"DeployIfNotExists"`, `Array of custom images` |
| built-in | `pxs-cn-vm-os-update-pd` | Audit if Guest operating system updates is enabled on virtual machine scale set                                    | guestosupdateeffect | `"Audit"`, `"Deny"`, `"Disabled"` |
| built-in | `a4fe33eb-e377-4efb-ab31-0784311bc499` | Log Analytics agent should be installed on your virtual machine for Azure Security Center monitoring | loganalyticseffect | `"AuditIfNotExists"`, `"Disabled"` |
| built-in | `2c89a2e5-7285-40fe-afe0-ae8654b92fb2` | Unattached disks should be encrypted                                                                 | diskEncryptionEffect | `"Audit"`, `"Disabled"` |
| built-in | `4da35fc9-c9e7-4960-aec9-797fe7d9051d` | Azure Defender for servers should be enabled                                                         | DefenderEffect | `"AuditIfNotExists"`, `"Disabled"` |
| built-in | `e1e5fd5d-3e4c-4ce1-8661-7d1873ae6b15` | Vulnerabilities in security configuration on your machines should be remediated                      | osVulnerabilityEffect | `"AuditIfNotExists"`, `"Disabled"` |

### 4.3.2. Policies Assignments

| Policy id | Displayname | Parameter | NON-PRODUCTION | PRODUCTION |
| --- | --- | --- | --- | --- |
| `a4fe33eb-e377-4efb-ab31-0784311bc499` | Log Analytics agent should be installed on your virtual machine for Azure Security Center monitoring                                             | logAnalyticsEffect  |  <span style="color:green">**AuditIfNotExists**</span> |  <span style="color:green">**AuditIfNotExists**</span>
| `2c89a2e5-7285-40fe-afe0-ae8654b92fb2` | Unattached disks should be encrypted | diskEncryptionEffect                                                           |  <span style="color:green">**Audit**</span> | <span style="color:green">**Audit**</span>
| `4da35fc9-c9e7-4960-aec9-797fe7d9051d` | Azure Defender for servers should be enabled | DefenderEffect                                                         |  <span style="color:green">**AuditIfNotExists**</span> |  <span style="color:green">**AuditIfNotExists**</span>
| `e1e5fd5d-3e4c-4ce1-8661-7d1873ae6b15` | Vulnerabilities in security configuration on your machines should be remediated                     | osVulnerabilityEffect  |  <span style="color:green">**AuditIfNotExists**</span> |  <span style="color:green">**AuditIfNotExists**</span>
| `pxs-cn-vm-deploy-laa-windows-pd` | Deploy Log Analytics agent for Windows virtual machines                                                     | Effect <br> logAnalytics <br> listOfImageIdToInclude| <span style="color:green">**DeployIfnotExists**</span> <br> `"Non-Production Log Analytics Workspace ID"` <br> `array of custom images` | <span style="color:green">**DeployIfnotExists**</span> <br> `"Production Log Analytics Workspace ID"` <br> `array of custom images`
| `pxs-cn-vm-deploy-da-windows-pd ` | Deploy Dependency agent for Windows virtual machines                                                        | Effect <br> listOfImageIdToInclude | <span style="color:green">**DeployIfnotExists**</span> <br> `array of custom images` | <span style="color:green">**DeployIfnotExists**</span> <br>  `array of custom images`
| `pxs-cn-vm-antimalware-pd` | Microsoft Antimalware protection signatures configuration| antimalwareeffect |  <span style="color:green">**AuditIfNotExists**</span> |  <span style="color:green">**AuditIfNotExists**</span>
| `pxs-cn-vm-bootdiagnostics-pd` | Boot diagnostics for Virtual Machines should be enabled                                                                       | bootdiagnosticseffect  | <span style="color:green">**Audit**</span> | <span style="color:green">**Deny**</span>
| `pxs-cn-vm-dependency-pd` | Dependency agent should be installed on Virtual Machines                                                             | depencyagenteffect  | <span style="color:green">**AuditIfNotExists**</span> | <span style="color:green">**AuditIfNotExists**</span>
| `pxs-cn-vm-deploy-iaa-windows-pd` | Deploy IaaS Anti-Malware agent for Windows virtual machines                                                     | Effect <br> listOfImageIdToInclude | <span style="color:green">**DeployIfnotExists**</span> <br> `array of custom images` | <span style="color:green">**DeployIfnotExists**</span> <br> `array of custom images`
| `pxs-cn-vm-deploy-nwa-windows-pd` | Deploy Network Watcher agent for Windows virtual machines                                                      | Effect <br> listOfImageIdToInclude | <span style="color:green">**DeployIfnotExists**</span> <br> `array of custom images` | <span style="color:green">**DeployIfnotExists**</span> <br> `array of custom images`
| `pxs-cn-vm-extensions-pd` | Only approved VM extensions should be installed for Virtual Machines                                                    | vmssextensionseffect <br> approvedExtensions | <span style="color:green">**Audit**</span> <br> `"AzureDiskEncryption", "AzureDiskEncryptionForLinux", "DependencyAgentWindows", "DependencyAgentLinux", "IaaSAntimalware", "IaaSDiagnostics", "LinuxDiagnostic", "MicrosoftMonitoringAgent", "NetworkWatcherAgentLinux", "NetworkWatcherAgentWindows", "OmsAgentForLinux", "VMSnapshot", "VMSnapshotLinux", "DSC","LinuxAgent.AzureSecurityCenter", "WindowsAgent.AzureSecurityCenter", "guesthealthwindowsagent", "azuremonitorwindowsagent", "SqlIaaSAgent", "azurebackupwindowsworkload", "CustomScript"` |  <span style="color:green">**Deny**</span> <br> `"AzureDiskEncryption", "AzureDiskEncryptionForLinux", "DependencyAgentWindows", "DependencyAgentLinux", "IaaSAntimalware", "IaaSDiagnostics", "LinuxDiagnostic", "MicrosoftMonitoringAgent", "NetworkWatcherAgentLinux", "NetworkWatcherAgentWindows", "OmsAgentForLinux", "VMSnapshot", "VMSnapshotLinux", "DSC","LinuxAgent.AzureSecurityCenter", "WindowsAgent.AzureSecurityCenter", "guesthealthwindowsagent", "azuremonitorwindowsagent", "SqlIaaSAgent", "azurebackupwindowsworkload", "CustomScript"`
| `pxs-cn-vm-manageddisk-pd` | Enforce managed disk usage                                                                                     | enforcemanageddiskeffect | <span style="color:green">**Audit**</span> |  <span style="color:green">**Deny**</span>
| `pxs-cn-vm-os-restriction-pd` | OS Restriction for the creation Virtual Machine                                                                    | osrestrictioneffect <br> allowedWindowsSKUImages |  <span style="color:green">**Audit**</span> <br> `"2012-R2-Datacenter", "2016-Datacenter-Server-Core", "2016-Datacenter", "2019-Datacenter-Core", "2019-Datacenter"`| <span style="color:green">**Deny**</span> <br> `"2012-R2-Datacenter", "2016-Datacenter-Server-Core", "2016-Datacenter", "2019-Datacenter-Core", "2019-Datacenter"` 
| `pxs-cn-vm-os-update-pd` | Audit if guest operating system updates is enabled on a virtual machine                                                   | guestosupdateeffect | <span style="color:green">**Audit**</span> | <span style="color:green">**Deny**</span>

## 5. Security Controls

All product-specific security controls - for the current product version - can be found on the table below:

| Index | Security Requirements | Relevance | Implementation details  | Policy Enforced / Audit | Design Status | Implemented Status |
|--|--|--|--|--|--|--|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later).  | Not applicable. | N/A  | N/A  |  |
| CN-SR-02 | Secret and Key management needs to be done by a dedicated database/vault. | This security requirement is not directly applicable to VM unless VM is using Bitlocker. | In case Azure Disk Encryption is used, Bitlocker keys need to be stored in the Azure Key Vault as described here: https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-key-vault |  |  |
| CN-SR-03 | Encrypt information at rest (Disc encryption).  | Same as CN-SR-02.  |  |  |  |
| CN-SR-04 | Maintain an inventory of sensitive Information.  | Needs to be defined at resource creation phase. Procedural. | N/A  | N/A |  |
| CN-SR-05 | Use an active discovery tool to identify sensitive data.  | Not applicable. | N/A | N/A |  |
| CN-SR-06 | Protect the database from permanently deleting data by enabling soft delete functionality.  | Not applicable. | N/A | N/A  |
| CN-SR-07 | Ensure regular automated back ups. | **TBD** | **TBD** |  |
| CN-SR-08 | Enforce the use of Azure Active Directory.  | Not applicable since VM will not be AD domain joined (on-premises Active Directory). | N/A | N/A  |  |
| CN-SR-09 | Follow the principle of least privilege.  | Needs to be defined at resource creation phase. Procedural. |   |    |  
| CN-SR-10 | Configure security log storage retention.  | Integration between resource and SIEM solution is required. | Agents need to be deployed as code to enforce Diagnostic and activity logs to be shipped to Log Analytics Workspace and from there also (using Event Hub) to SIEM solution. This is provided by the Platform.  |  
| CN-SR-11 | Enable alerts for anomalous activity.  | Antimalware solution needs to be enforced. | Azure Defender for Servers in Azure Security Center needs to be enforced, one of the component is Microsoft Defender for Endpoints. (https://docs.microsoft.com/en-us/azure/security-center/defender-for-servers-introduction) |  |  |
| CN-SR-12 | Configure central security log management. | Security logging needs to be implemented (enforced). | Logging will be implemented using an Event Hub, similar to CN-SR-10. More information: https://docs.microsoft.com/en-us/azure/storage/common/storage-analytics-logging?tabs=dotnet | ARM template to send logs and metrics to the Event Hub. Custom Policy (Audit/DeployIfNotExists)|   |  | | 
| CN-SR-13 | Enable audit logging of Azure Resources.  | Enable (enforce) diagnostic logs on the service to the Central Log Analytics Workspace and Storage Account. https://docs.microsoft.com/en-us/azure/storage/common/storage-monitor-storage-account | Custom Policy (Audit/DeployIfNotExists) |  |
| CN-SR-14 | Enable MFA and conditional access with MFA.  | Not applicable. Inherited from Azure AD.	| N/A |   |  |
| CN-SR-15 | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network.  | Not directly applicable. Needs to be implemented on NSG/Azure Firewall level. Access only for the LZ resources | N/A |   |  |
| CN-SR-16 | Ensure that the endpoint protection for all Virtual Machines is installed. | Windows  | N/A  | N/A |  |
| CN-SR-17 | Secure outbound communication to the internet.  | **TBD**  | N/A |   |  |
| CN-SR-18 | Enable JIT network access.  |  Just in time access to VMs need to be enforced. | Configured and enforced JIT needs to be enabled on VM in Azure Security Center. More information here: https://docs.microsoft.com/en-us/azure/security-center/security-center-just-in-time?tabs=jit-config-asc%2Cjit-request-asc  | N/A |  |
| CN-SR-19 | Run automated vulnerability scanning tools.  | **TBD** | **TBD**  |   |  |
| CN-SR-20 | Use automated tools to monitor network resource configurations and detect changes.  |  Not applicable.  | N/A | N/A |   |
| CN-SR-21 | Disable remote user access ports (RDP, SSH, Telnet, FTP).  | **To be confirmed! Should RDP really be disabled?** | RDP should be allowed (by using Local Policy and Windows Firewall configuration and Azure NSG) to allow users to access VM using JIT feature in Azure Security Center. All other ports should be closed.  | ARM template, Built-in Policy |  |
| CN-SR-22 | Enable automated Patching/ Upgrading.  |  Patch management for OS should be implemented for VM. | Customer responsibility, configuration using Local Po licy import (or any other option).   | N/A |  |
| CN-SR-23 | Enable transparent data encryption. |  Not applicable. | N/  | N/A |  |
| CN-SR-24 | Enable OS vulnerabilities recommendations.  |  Patch management for OS should be implemented for VM. | Customer responsibility, configuration using Local Policy import (or any other option).   | Local policy import or Registry import. |  |
| CN-SR-25 | Configure firewall rules of existing firewalls if necessary.  | Firewall and NSG need to be configured to be able to access VM from External network. | **Firewall on OS level:** VM's built-in Windows Firewall is enabled by default and needs to be configured to allow RDP access to VM. This could be configured with importing Windows Firewall policy in the deployment phase on using any other option. <BR> **On Vnet level:** On the Vnet level RDP needs to be allowed to be able to access VM from External network (Azure Firewall, NSG) |  | |  |   |  |
| CN-SR-26 | Enable command-line audit logging.  | Not applicable. | N/A |   |  |
| CN-SR-27 | Enable conditional access control.  | Not applicable, but could be inherited from Azure AD if it would be Azure AD joined. | N/A |   |  |
| CN-SR-28 | Specify service tags to define network access controls on network security groups or Azure Firewall. | Implemented with the tags in the ARM template. | Embedded in the ARM template.  | N/A |  |
| CN-SR-29 | Use Corporate Active Directory Credentials.  | Not applicable since VM will not be AD domain joined (on-premises Active Directory). | N/A | N/A | 
  