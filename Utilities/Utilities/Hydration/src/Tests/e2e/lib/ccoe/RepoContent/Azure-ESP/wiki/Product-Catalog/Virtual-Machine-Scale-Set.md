<!-- COMMENT 
    SKU
    public IP
    https://docs.microsoft.com/en-us/azure/load-balancer/configure-vm-scale-set-portal
    https://docs.microsoft.com/en-us/azure/security/fundamentals/virtual-machines-overview
 -->


# Virtual Machine Scale Set 1.0

| **Status** | <span style="color:orange">**DRAFT**</span> |
|--|--|
| **Version** | v1.0 |
| **Edited By** | Michaël Tonneau-Midol |
| **Date** | 12/02/2021  |
| **Approvers** | Frederik DE RYCK <br> Peter THEUNS  |
| **Deployment documentation** | <link to GIT Module missing> |
| **To Do** |  |

[[_TOC_]]

## 1. Introduction
### 1.1. Service Description
[Azure virtual machine scale sets](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/overview) provide a scalable way to run applications on a set of virtual machines (VMs). The VMs in this type of scale set all have the same configuration and run the same applications. As demand grows, the number of VMs running in the scale set increases. As demand slackens, excess VMs can be shut down. Virtual machine scale sets are ideal for scenarios that include compute workloads, big-data workloads, and container workloads.

### 1.2. Shared Image Gallery
During the creatio of a Azure Scale Set, an image is used when the VM instances are deployed.  The [Azure Shared Image Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries) service simplifies custom image sharing across your organization. Custom images can be used to bootstrap configurations such as preloading applications, application configurations, and other OS configurations.

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
<!-- links: 
	https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/shared-images-powershell
	https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/tutorial-use-custom-image-powershell -->

### 1.3. Virtual Machines vs Scale Set
Differences between virtual machines and scale sets
Scale sets are built from virtual machines. With scale sets, the management and automation layers are provided to run and scale your applications. You could instead manually create and manage individual VMs, or integrate existing tools to build a similar level of automation. The following table outlines the benefits of scale sets compared to manually managing multiple VM instances.

| Scenario | Manual group of VMs | Virtual machine scale set | 
| -- | -- | --| 
| Add additional VM instances | Manual process to create, configure, and ensure compliance | Automatically create from central configuration | 
| Traffic balancing and distribution | Manual process to create and configure Azure load balancer or Application Gateway | Can automatically create and integrate with Azure load balancer or Application Gateway | 
| High availability and redundancy | Manually create Availability Set or distribute and track VMs across Availability Zones | Automatic distribution of VM instances across Availability Zones or Availability Sets
| Scaling of VMs | Manual monitoring and Azure Automation | Autoscale based on host metrics, in-guest metrics, Application Insights, or schedule | 

## 2. Architecture

### 2.1 High Level Design

![Virtual Machine Scale Set Architecture](/.attachments/vmss_architecture.png)

### 2.2 Horizontal vs Vertical scaling

+ Horizontal scaling is the process of adding or removing several VMs in a scale set.
+ Vertical scaling is the process of adding resources such as memory, CPU power, or disk space to VMs.

![Virtual Machine Scale Scaling](/.attachments/VMSS_Scaling_Diagram.png)

### 2.3 Scheduled vs auto scaling

+ Scheduled scaling: You can proactively schedule the scale set to deploy one or N number of additional instances to accommodate a spike in traffic and then scale back down when the spike ends.
+ Autoscaling: If the workload is variable and can't always be scheduled, you can use metric-based threshold scaling. Autoscaling horizontally scales out based on node usage. It then scales back in when the resources return to a baseline.

### 2.4 Security

#### 2.4.1 Azure Load-Balancing

Virtual Machines support the use of Azure Load balancer and Azure Application Gateway:

+ [Azure Load-Balancing](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-overview): Basic layer-4 traffic distribution
+ [Azure Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/overview) : layer-7 traffic distribution and TLS termination

#### 2.4.2 Just In Time Access

Lock down inbound traffic to your Azure Virtual Machines with Azure Security Center's [just-in-time (JIT)](https://docs.microsoft.com/en-us/azure/security-center/just-in-time-explained) virtual machine (VM) access feature. This reduces exposure to attacks while providing easy access when you need to connect to a VM.

#### 2.4.3 Azure Bastion 

*Azure Bastion* is a PaaS service provisioned inside the Virtual Network and provide a secure way to connect to Virtual Machines through RDP/SSH, whitout needing a Public IP address.  The use of Azure Bastion will be investigated in a later release

#### 2.4.4 windows update

Windows update are installed through Automatic VM guest patching.  This feature has the following characteristics:  

+ Patches classified as Critical or Security are automatically downloaded and applied on the VM.
+ Patches are applied during off-peak hours in the VM's time zone.
+ Patch orchestration is managed by Azure and patches are applied following availability-first principles.
+ Virtual machine health, as determined through platform health signals, is monitored to detect patching failures.
+ Works for all VM sizes.

#### 2.4.4.1 prerequisites

Feature needs to be activate on the subscription before it can be used during the deployment of Virtual Machines and Virtual Machines Scale Set:

1. Use the Register-AzProviderFeature cmdlet to enable the preview for your subscription: <br>
`Register-AzProviderFeature -FeatureName InGuestAutoPatchVMPreview -ProviderNamespace Microsoft.Compute`
2. Feature registration can take up to 15 minutes. To check the registration status: <br> 
`Get-AzProviderFeature -FeatureName InGuestAutoPatchVMPreview -ProviderNamespace Microsoft.Compute`
3. Once the feature is registered for your subscription, complete the opt-in process by propagating the change into the Compute resource provider: <br> `Register-AzResourceProvider -ProviderNamespace Microsoft.Compute`

#### 2.4.4.2 ARM template

To enable automatic VM Guest patching, API version must be 2020-06-01 or higher and the following property has to be added in the ARM template of the Virtual Machine and Virtual Machine Scale Set. The [Azure VM Agent](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/agent-windows) must be installed on the Virtual Machine.

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

#### 2.4.4.3 Supported OS images

the following OS images are currently supported for Automatic VM Guest patching:
| Publisher  | OS Offer  | Sku
| -- | -- | -- |
| MicrosoftWindowsServer | WindowsServer | 2016-Datacenter
| MicrosoftWindowsServer | WindowsServer | 2016-Datacenter-Server-Core
| MicrosoftWindowsServer | WindowsServer | 2019-Datacenter
| MicrosoftWindowsServer | WindowsServer | 2019-Datacenter-Core

#### 2.4.5 Backup

The customer is responsible for backup and restore of the virtual machine scale sets. A recovery vault resource is provide for each Landing Zone.

#### 2.4.6 Antimalware

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

#### 2.4.7 Monitoring

Azure Security Center and Azure Monitor are enabled to Monitor the different resources within the Landing Zone.

#### 2.4.8 Azure Disk Encryption

Azure Disk Encryption (ADE) provides the possibility to encrypt data on the disk by using bitlocker to encrypt the volume and Key Vault to manage the disk encryption keys.
prerequisites for Azure Disk Encryption:

+ Azure Disk Encryption is not available on Basic, A-series VMs, or on virtual machines with a less than 2 GB of memory.
+ Azure Disk Encryption is also available for VMs with premium storage.
+ Azure Disk Encryption is not available on Generation 2 VMs. For more exceptions, see Azure Disk Encryption: [Unsupported scenarios](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-windows#unsupported-scenarios).
+ Azure Disk Encryption is not available on VM images without temp disks (Dv4, Dsv4, Ev4, and Esv4). See Azure VM sizes with no local temporary disk.


#### 2.4.9 Azure role-based access control

Built-in Roles Virtual Machine:

| **Built-in role**                        | **Description**          | **Accounts**|
|----|----------------------|----|
| Classic Virtual Machine Contributor             | Lets you manage classic virtual machines, but not access to them, and not the virtual network or storage account they're connected to. |    |
| Virtual Machine Administrator Login       | View Virtual Machines in the portal and login as administrator                                                                               |    |
| Virtual Machine Contributor             | Lets you manage virtual machines, but not access to them, and not the virtual network or storage account they're connected to.       |    |
| Virtual Machine User Login             | View Virtual Machines in the portal and login as a regular user.       |    |

### 2.5. Service Limits

+ [Azure limits per subscription](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits#application-insights-limits)
+ [Virtual Machine limits](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#virtual-machines-limits---azure-resource-manager)
+ [Virtual Machine Scale Sets limits](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#virtual-machine-scale-sets-limits) 

## 3. Service Level Agreement

### 3.1 Virtual Machine

| Description | Service Level Agreement |
|--|--|
| Virtual Machines deployed in Availability Zones | >99.99% |
| Virtual Machines deployed in Availability Sets | >99.95% |
| Single Virtual Machine using Premium Storage | >99.90% |
| Single Virtual Machine using Standard SSD Storage | >99.50% |
| Single Virtual Machine using Standard HDD Storage | >95.00% |

### 3.2 Virtual Machine Scale Set

Virtual Machine Scale Sets is a free service, therefore, it does not have a financially backed SLA itself. However, if the Virtual Machine Scale Sets includes Virtual Machines in at least 2 Fault Domains, the availability of the underlying Virtual Machines SLA for two or more instances applies. If the scale set contains a single Virtual Machine, the availability for a Single Instance Virtual Machine applies. See the Virtual Machines SLA for more details.

## 4. Service Provisioning

### 4.1. Prerequisites

The following Azure resources need to be in place before this Certified Service can be provisioned:

+ Resource Group
+ Virtual Network (& NSG)
+ Keyvault
+ Azure Load Balancer ***investigation in a later stage***
+ Azure Application gateway & WAF/Application proxy(/NVA?) (Pre-authentication!) ***investigation in a later stage***
+ Log Analytics Workspace 
+ Storage Account for Diagnostic logging 
+ Azure Automation Account ***investigation in a later stage***
+ Azure Recovery vaults for Backup 

### 4.2. Deployment parameters

|          Pararameter                | NON-PRODUCTION                                                        | PRODUCTION                                                            | Implementation | Implementation Status |
|-------------------------------------|-----------------------------------------------------------------------|-----------------------------------------------------------------------|----------------|-----------------------|
|                                     | Windows                                                               | Windows                                                               |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Subscription                        |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:grey">**N/A**</span>               |
| Resource Group                      |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:grey">**N/A**</span>               |
| VMSS Name                           |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**IMPLEMENTED**</span>      |
| VMSS Computer Name                  |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**IMPLEMENTED**</span>      |
| Admin Username                      |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**IMPLEMENTED**</span>      |
| Admin Password                      | Secret taken from Key Vault                                           | Secret taken from Key Vault                                           |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
| Key Vault ID                        |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**IMPLEMENTED**</span>      |
| Location                            | West Europe (Resource group)                                          | West Europe (Resource group)                                          |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**IMPLEMENTED**</span>      |
| Availability                        | No Redundancy required                                                | No Redundancy required                                                |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Image                               | Windows images (TBD & enforced by policy)                             | Windows images (TBD & enforced by policy)                             |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:grey">**N/A**</span>               |
| Azure Spot instance                 | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Size                                | Fixed choices by policy                                               | Fixed choices by policy                                               |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**IMPLEMENTED**</span>      |
| Public Inbound ports                | None                                                                  | None                                                                  |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| OS Disk type                        | Standard SSD                                                          | Premium SSD                                                           |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
| Encryption type                     | Encryption at Rest with platform Key                                  | Encryption at Rest with platform Key                                  |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
| Data Disk (Attach an existing disk) | Yes                                                                   | Yes                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
| Use Managed Disk                    | Yes                                                                   | Yes                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
| Ephemeral OS Disk                   | No                                                                    | No                                                                    |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Virtual Network                     | Existing (coming from Platform)                                       | Existing (coming from Platform)                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**IMPLEMENTED**</span>      |
| Subnet                              | Existing (coming from Platform)                                       | Existing (coming from Platform)                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**IMPLEMENTED**</span>      |
| Public IP                           | No                                                                    | No                                                                    |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| NIC network security group          | None (use Vnet NSG)                                                   | None (use Vnet NSG)                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Accelerated networking              | Off                                                                   | On                                                                    |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Load balancing                      | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Azure Security Center               | Your subscription is protected by Azure Security Center standard plan | Your subscription is protected by Azure Security Center standard plan |  <span style="color:grey">**N/A**</span>                |  <span style="color:grey">**N/A**</span>               |
| Boot diagnostics                    | On                                                                    | On                                                                    |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
| OS guest diagnostics                | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
| System assigned managed identity    | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Login with AAD credentials          | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Enable auto-shutdown                | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Enable backup                       | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Patch Installation                  | Automatic                                                                   | Automatic                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |
| Extensions                          | Network Watcher Agent for Windows (template)                          | Network Watcher Agent for Windows (template)                          |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
|                                     | Microsoft IaaS Antimalware Agent (template)                           | Microsoft IaaS Antimalware Agent  (template)                          |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
|                                     | Microsoft Dependency Agent (template)                                 | Microsoft Dependency Agent (template)                                 |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
|                                     | Microsoft Monitoring Agent (template)                                 | Microsoft Monitoring Agent (template)                                 |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
|                                     | Microsoft Insights VMDiagnostics Settings Agent (template)            | Microsoft Insights VMDiagnostics Settings Agent (template)            |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
|                                     | Azure Disk Encryption (template) <br> CustomScript to format all Data Disk (Template)  | Azure Disk Encryption (template) <br> CustomScript to format all Data Disk (Template)                                     |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
| VM Generation                       | v1                                                                    | v1                                                                    |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:green">**IMPLEMENTED**</span>      |
| Tags                                |                                                                       |                                                                       |  <span style="color:green">**PARAMETER**</span>         |  <span style="color:green">**IMPLEMENTED**</span>      |
| Domain Join (After VM creation)     | Off                                                                   | Off                                                                   |  <span style="color:green">**DEFAULT**</span>           |  <span style="color:grey">**N/A**</span>               |

### 4.3 Policies

### 4.3.1. Policies Definiations

The following policies are grouped within a single Policy Initiative **pxs-cn-vmss-pi** :

The following Policies are in place (see article [Foundation Design](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/410/Foundation-Design) > [Governance](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/496/Governance) in Wiki to learn more about Policies)

| Policy type | Policy id | Policy Display Name | Parameter | Allowed values |
| --- | --- | --- | --- | --- |
| built-in | `7c1b1214-f927-48bf-8882-84f0af6588b1` | Diagnostic logs in Virtual Machine Scale Sets should be enabled | diagnosticLogsEffect | `"AuditIfNotExists"`, `"Disabled"` |
| built-in | `efbde977-ba53-4479-b8e9-10b957924fbf` | The Log Analytics agent should be installed on Virtual Machine Scale Sets | logAnalyticsEffect  | `"AuditIfNotExists"`, `"Disabled"` |
| built-in | `2c89a2e5-7285-40fe-afe0-ae8654b92fb2` | Unattached disks should be encrypted | diskEncryptionEffect  | `"Audit"`, `"Disabled"` |
| built-in | `4da35fc9-c9e7-4960-aec9-797fe7d9051d` | Azure Defender for servers should be enabled | DefenderEffect  | `"AuditIfNotExists"`, `"Disabled"` |
| built-in | `c3f317a7-a95c-4547-b7e7-11017ebdf2fe` | System updates on virtual machine scale sets should be installed | systemUpdatesEffect  | `"AuditIfNotExists"`, `"Disabled"` |
| built-in | `3c735d8a-a4ba-4a3a-b7cf-db7754cf57f4` | Vulnerabilities in security configuration on your virtual machine scale sets should be remediated | osVulnerabilityEffect  | `"AuditIfNotExists"`, `"Disabled"` |
| built-in | `3c1b3629-c8f8-4bf6-862c-037cb9094038` | Deploy Log Analytics agent for Windows virtual machine scale sets | Effect <br> logAnalytics <br> listOfImageIdToInclude | `"DeployIfNotExists"` <br> `"Log Analytics Workspace ID"` <br> `array of custom images`  |
| built-in | `3be22e3b-d919-47aa-805e-8985dbeb0ad9` | Deploy Dependency agent for Windows virtual machine scale sets | Effect <br> listOfImageIdToInclude | `"DeployIfNotExists"` <br> `array of custom images` |
| custom | `pxs-cn-vmss-antimalware-pd` | Microsoft Antimalware for Azure should be configured to automatically update protection signatures. (Virtaul Machine Scale Set) | antimalwareeffect | `"AuditIfNotExists"`, `"Disabled"` |
| custom | `pxs-cn-vmss-bootdiagnostics-pd` | Guest OS updates enabled on virtual machine scale set | bootdiagnosticseffect  | `"Audit", "Deny", "Disabled"` |
| custom | `pxs-cn-vmss-dependcy-pd` | The Dependency agent should be installed on Virtual Machine Scale Sets | depencyagenteffect  | `"AuditIfNotExists"`, `"Disabled"` |
| custom | `pxs-cn-vmss-deploy-iaa-windows-pd` | Deploy IaaS Antimalware agent for Windows virtual machine scale sets | Effect <br> listOfImageIdToInclude | `"DeployIfNotExists"` <br> `array of custom images` |
| custom | `pxs-cn-vmss-deploy-nwa-windows-pd` | Deploy Network Watcher agent for Windows virtual machine scale sets | Effect <br> listOfImageIdToInclude | `"DeployIfNotExists"` <br> `array of custom images` | | `"DeployIfNotExists"` |
| custom | `pxs-cn-vmss-extensions-pd` | Only approved VM extensions should be installed for Virtual Machine Scale Set | vmssextensionseffect <br> approvedExtensions | `"Audit", "Deny", "Disabled"` <br> `array of approved extensions`|
| custom | `pxs-cn-vmss-managed-disk-pd` | Enforce VM scale sets to use managed disks | enforcemanageddiskeffect | `"Audit", "Deny", "Disabled"` |
| custom | `pxs-cn-vmss-os-restriction-pd` | OS Restriction for the creation Virtual Machine Scale Set | osrestrictioneffect <br> allowedWindowsSKUImages |  `"Audit", "Deny", "Disabled"` <br> `Array of allowed Windows SKU Images` |
| custom | `pxs-cn-vmss-os-update-pd` | Audit if Guest operating system updates is enabled on virtual machine scale set | guestosupdateeffect | `"Audit", "Deny", "Disabled"` |

### 4.3.2. Policies Assignments

| Policy id | Displayname | Parameter | NON-PRODUCTION | PRODUCTION |
| --- | --- | --- | :--- | --- |
| `7c1b1214-f927-48bf-8882-84f0af6588b1` | Diagnostic logs in Virtual Machine Scale Sets should be enabled | diagnosticLogsEffect |  <span style="color:green">**AuditIfNotExists**</span> |  <span style="color:green">**AuditIfNotExists**</span>
| `efbde977-ba53-4479-b8e9-10b957924fbf` | The Log Analytics agent should be installed on Virtual Machine Scale Sets | logAnalyticsEffect  |  <span style="color:green">**AuditIfNotExists**</span> |  <span style="color:green">**AuditIfNotExists**</span>
| `2c89a2e5-7285-40fe-afe0-ae8654b92fb2` | Unattached disks should be encrypted | diskEncryptionEffect  |  <span style="color:green">**Audit**</span> | <span style="color:green">**Audit**</span>
| `4da35fc9-c9e7-4960-aec9-797fe7d9051d` | Azure Defender for servers should be enabled | DefenderEffect  |  <span style="color:green">**AuditIfNotExists**</span> |  <span style="color:green">**AuditIfNotExists**</span>
| `c3f317a7-a95c-4547-b7e7-11017ebdf2fe` | System updates on virtual machine scale sets should be installed | systemUpdatesEffect  | <span style="color:green">**AuditIfNotExists**</span> |  <span style="color:green">**AuditIfNotExists**</span>
| `3c735d8a-a4ba-4a3a-b7cf-db7754cf57f4` | Vulnerabilities in security configuration on your virtual machine scale sets should be remediated | osVulnerabilityEffect  |  <span style="color:green">**AuditIfNotExists**</span> |  <span style="color:green">**AuditIfNotExists**</span>
| `3c1b3629-c8f8-4bf6-862c-037cb9094038` | Deploy Log Analytics agent for Windows virtual machine scale sets | Effect <br> logAnalytics <br> listOfImageIdToInclude| <span style="color:green">**DeployIfnotExists**</span> <br> `"Non-Production Log Analytics Workspace ID"` <br> `array of custom images` | <span style="color:green">**DeployIfnotExists**</span> <br> `"Production Log Analytics Workspace ID"` <br> `array of custom images`
| `3be22e3b-d919-47aa-805e-8985dbeb0ad9` | Deploy Dependency agent for Windows virtual machine scale sets | Effect <br> listOfImageIdToInclude | <span style="color:green">**DeployIfnotExists**</span> <br> `array of custom images` | <span style="color:green">**DeployIfnotExists**</span> <br>  `array of custom images`
| `pxs-cn-vmss-antimalware-pd` | Microsoft Antimalware for Azure should be configured to automatically update protection signatures. (Virtaul Machine Scale Set) | antimalwareeffect |  <span style="color:green">**AuditIfNotExists**</span> |  <span style="color:green">**AuditIfNotExists**</span>
| `pxs-cn-vmss-bootdiagnostics-pd` | Guest OS updates enabled on virtual machine scale set | bootdiagnosticseffect  | <span style="color:green">**Audit**</span> | <span style="color:green">**Deny**</span>
| `pxs-cn-vmss-dependcy-pd` | The Dependency agent should be installed on Virtual Machine Scale Sets | depencyagenteffect  | <span style="color:green">**AuditIfNotExists**</span> | <span style="color:green">**AuditIfNotExists**</span>
| `pxs-cn-vmss-deploy-iaa-windows-pd` | Deploy IaaS Antimalware agent for Windows virtual machine scale sets | Effect <br> listOfImageIdToInclude | <span style="color:green">**DeployIfnotExists**</span> <br> `array of custom images` | <span style="color:green">**DeployIfnotExists**</span> <br> `array of custom images`
| `pxs-cn-vmss-deploy-nwa-windows-pd` | Deploy Network Watcher agent for Windows virtual machine scale sets | Effect <br> listOfImageIdToInclude | <span style="color:green">**DeployIfnotExists**</span> <br> `array of custom images` | <span style="color:green">**DeployIfnotExists**</span> <br> `array of custom images`
| `pxs-cn-vmss-extensions-pd` | Only approved VM extensions should be installed for Virtual Machine Scale Set | vmssextensionseffect <br> approvedExtensions | <span style="color:green">**Audit**</span> <br> `"AzureDiskEncryption", "AzureDiskEncryptionForLinux", "DependencyAgentWindows", "DependencyAgentLinux", "IaaSAntimalware", "IaaSDiagnostics", "LinuxDiagnostic", "MicrosoftMonitoringAgent", "NetworkWatcherAgentLinux", "NetworkWatcherAgentWindows", "OmsAgentForLinux", "VMSnapshot", "VMSnapshotLinux", "DSC","LinuxAgent.AzureSecurityCenter", "WindowsAgent.AzureSecurityCenter", "guesthealthwindowsagent", "azuremonitorwindowsagent", "SqlIaaSAgent", "azurebackupwindowsworkload", "CustomScript"` |  <span style="color:green">**Deny**</span> <br> `"AzureDiskEncryption", "AzureDiskEncryptionForLinux", "DependencyAgentWindows", "DependencyAgentLinux", "IaaSAntimalware", "IaaSDiagnostics", "LinuxDiagnostic", "MicrosoftMonitoringAgent", "NetworkWatcherAgentLinux", "NetworkWatcherAgentWindows", "OmsAgentForLinux", "VMSnapshot", "VMSnapshotLinux", "DSC","LinuxAgent.AzureSecurityCenter", "WindowsAgent.AzureSecurityCenter", "guesthealthwindowsagent", "azuremonitorwindowsagent", "SqlIaaSAgent", "azurebackupwindowsworkload", "CustomScript"`
| `pxs-cn-vmss-managed-disk-pd` | Enforce VM scale sets to use managed disks | enforcemanageddiskeffect | <span style="color:green">**Audit**</span> |  <span style="color:green">**Deny**</span>
| `pxs-cn-vmss-os-restriction-pd` | OS Restriction for the creation Virtual Machine Scale Set | osrestrictioneffect <br> allowedWindowsSKUImages |  <span style="color:green">**Audit**</span> <br> `"2016-Datacenter-Server-Core", "2016-Datacenter", "2019-Datacenter-Core", "2019-Datacenter"`| <span style="color:green">**Deny**</span> <br> `"2016-Datacenter-Server-Core", "2016-Datacenter", "2019-Datacenter-Core", "2019-Datacenter"` 
| `pxs-cn-vmss-os-update-pd` | Audit if Guest operating system updates is enabled on virtual machine scale set | guestosupdateeffect | <span style="color:green">**Audit**</span> | <span style="color:green">**Deny**</span>

## 5. Security Controls

All product-specific security controls - for the current product version - can be found on the table below:

| Index | Security Requirements | Relevance | Implementation details  | Policy Enforced / Audit | Design Status | Implemented Status |
|--|--|--|--|--|--|--|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later).  | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span>  | <span style="color:grey">**N/A**</span>  | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span> |
| CN-SR-02 | Secret and Key management needs to be done by a dedicated database/vault. | passwords of virtual machine scale set should be stored in a Keyvault | The ARM template should not contain any password.  The template is referencing a keyvault store and the name of the secret | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:green">**INPLEMENTED BY DEFAULT**</span> |
| CN-SR-03 | Encrypt information at rest (Disc encryption). | This security requirement is not directly applicable to VM unless VM is using Bitlocker. | In case Azure Disk Encryption is used, Bitlocker keys need to be stored in the Azure Key Vault as described here: <br> https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-key-vault | Audit | <span style="color:green">**FINAL**</span> | <span style="color:green">**INPLEMENTED BY DEFAULT**</span>
| CN-SR-04 | Maintain an inventory of sensitive Information. | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span>  | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span> |
| CN-SR-05 | Use an active discovery tool to identify sensitive data.  | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span> |
| CN-SR-06 | Protect the database from permanently deleting data by enabling soft delete functionality.  | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span> |
| CN-SR-07 | Ensure regular automated back ups. | responsability of the customer. A recovery vault is provide for each Landing Zone | <span style="color:grey">**N/A**</span>  | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span> |
| CN-SR-08 | Enforce the use of Azure Active Directory.  | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span>  | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span> |
| CN-SR-09 | Follow the principle of least privilege.  | Needs to be defined at resource creation phase. Procedural. | <span style="color:grey">**N/A**</span>  | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span> |
| CN-SR-10 | Configure security log storage retention.  | Log Analytics retention is configured on the LAW product itself. <br> More information: https://docs.microsoft.com/en-us/azure/key-vault/key-vault-logging | <span style="color:grey">**N/A**</span>  | Audit | <span style="color:green">**FINAL**</span> | <span style="color:green">**INPLEMENTED BY DEFAULT**</span> |
| CN-SR-11 | Enable alerts for anomalous activity.  | Azure Defender for Servers in Azure Security Center needs to be enforced, one of the component is Microsoft Defender for Endpoints. <br> (https://docs.microsoft.com/en-us/azure/security-center/defender-for-servers-introduction) | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:green">**INPLEMENTED BY DEFAULT**</span> |
| CN-SR-12 | Configure central security log management. | Security logging needs to be implemented (enforced). <br> Policies will be put in place which enforce the usage of specific Eventhub and Analytics workspace. | Logging will be implemented using an Event Hub, similar to CN-SR-10. <br> More information: https://docs.microsoft.com/en-us/azure/storage/common/storage-analytics-logging?tabs=dotnet | <span style="color:grey">**N/A**</span>  | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span> |
| CN-SR-13 | Enable audit logging of Azure Resources.  | Enable (enforce) diagnostic logs on the service to the Central Log Analytics Workspace and Event Hub. <br> https://docs.microsoft.com/en-us/azure/storage/common/storage-monitor-storage-account | Custom Policy (Audit/DeployIfNotExists) | Audit | <span style="color:green">**FINAL**</span> | <span style="color:green">**IMPLEMENTED BY DEFAULT**</span> |
| CN-SR-14 | Enable MFA and conditional access with MFA.  | <span style="color:grey">**N/A**</span>	| <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span>	|<span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span>
| CN-SR-15 | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network.  | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span> |
| CN-SR-16 | Ensure that the endpoint protection for all Virtual Machines is installed. | Azure Defender should be enabled on the servers. | <span style="color:grey">**N/A**</span> | Audit | <span style="color:green">**FINAL**</span> | <span style="color:green">**INPLEMENTED BY DEFAULT**</span> |
| CN-SR-17 | Secure outbound communication to the internet.  | <span style="color:grey">**N/A**</span>  | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span> |
| CN-SR-18 | Enable JIT network access. | *To be investigated in a later sprint in combination with Azure Bastion* | <span style="color:grey">**N/A**</span>  | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span> |
| CN-SR-19 | Run automated vulnerability scanning tools.  | Azure IaaS Antimalware agent is installed on the virtual machine scale set | <span style="color:grey">**N/A**</span> | Audit | <span style="color:green">**FINAL**</span> | <span style="color:green">**INPLEMENTED BY DEFAULT**</span> |
| CN-SR-20 | Use automated tools to monitor network resource configurations and detect changes.  |  <span style="color:grey">**N/A**</span>  | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span>
| CN-SR-21 | Disable remote user access ports (RDP, SSH, Telnet, FTP).  | *To be investigated in a later sprint. this will be combined with Azure Bastion* | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span> |
| CN-SR-22 | Enable automated Patching/ Upgrading.  |  Patch management for OS should be implemented for VM. | Customer responsibility, configuration using Local Policy import (or any other option). | Audit | <span style="color:green">**FINAL**</span> | <span style="color:green">**INPLEMENTED BY DEFAULT**</span> |
| CN-SR-23 | Enable transparent data encryption. |  <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span>  | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span>
| CN-SR-24 | Enable OS vulnerabilities recommendations.  |  Patch management for OS should be implemented for VM. | Customer responsibility, configuration using Local Policy import (or any other option). | Audit | <span style="color:green">**FINAL**</span> | <span style="color:green">**INPLEMENTED BY DEFAULT**</span> |
| CN-SR-25 | Configure firewall rules of existing firewalls if necessary.  | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span> |
| CN-SR-26 | Enable command-line audit logging. | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span> |
| CN-SR-27 | Enable conditional access control. | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span> |
| CN-SR-28 | Specify service tags to define network access controls on network security groups or Azure Firewall. | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span>  | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span> |
| CN-SR-29 | Use Corporate Active Directory Credentials.  | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:grey">**N/A**</span> | <span style="color:green">**FINAL**</span> | <span style="color:grey">**N/A**</span> |
