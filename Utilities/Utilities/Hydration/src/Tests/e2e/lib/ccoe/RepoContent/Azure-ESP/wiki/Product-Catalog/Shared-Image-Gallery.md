# Shared Image Gallery 1.0

| **Status** | <span style="color:orange">**DRAFT**</span> |
|--|--|
| **Version** | v0.1 |
| **Edited By** | Tonneau-Midol Michaël |
| **Date** | 10/01/2021  |
| **Approvers** |  |
| **Deployment documentation** | <link to GIT Module missing> |
| **To Do** |  |

[[_TOC_]]

## 1. Introduction
### 1.1. Service Description
Shared Image Gallery is a Azure service to structure images based on the needs of the organization. Shared Image Galleries features:
+ Global replication of images.
+ Versioning and grouping of images for easier management.
+ Highly available images with Zone Redundant Storage (ZRS) accounts in regions that support Availability Zones. ZRS offers better resilience against zonal failures.
+ Premium storage support (Premium_LRS).
+ Sharing across subscriptions, and even between Active Directory (AD) tenants, using RBAC.
+ Scaling your deployments with image replicas in each region.

Shared Image Gallery consists of the following resource types:
| Resource | Description |
| -- | -- |
| **Image source** | This is a resource that can be used to create an image version in an image gallery. An image source can be an existing Azure VM that is either generalized or specialized, a managed image, a snapshot, a VHD or an image version in another image gallery. | 
| **Image gallery** | Like the Azure Marketplace, an image gallery is a repository for managing and sharing images, but you control who has access.| 
| **Image definition** | Image definitions are created within a gallery and carry information about the image and requirements for using it internally. This includes whether the image is Windows or Linux, release notes, and minimum and maximum memory requirements. It is a definition of a type of image. | 
| **Image version** | An image version is what you use to create a VM when using a gallery. You can have multiple versions of an image as needed for your environment. Like a managed image, when you use an image version to create a VM, the image version is used to create new disks for the VM. Image versions can be used multiple times.  

![Shared Image Gallery](/.attachments/shared-image-gallery.png) 

### 1.2. Generalized and Specialized Images
Shared Image Gallery supports both type of images.  
**Generalized images** are images that have been through the process of removing specific user and computer information from the virtual machine. For Windows, Sysprep tool is used. For Linux the [waagent](https://github.com/Azure/WALinuxAgent) can be used to generalize a virtual machine.

**Specialized images** are images that haven't been through the process of removing specific information from the virtual machine.

+ VMs and scale sets created from specialized images can be up and running quicker. Because they are created from a source that has already been through first boot, VMs created from these images boot faster.
+ Accounts that could be used to log into the VM can also be used on any VM created using the specialized image that is created from that VM.
+ VMs will have the Computer name of the VM the image was taken from. You should change the computer name to avoid collisions.
+ The osProfile is how some sensitive information is passed to the VM, using secrets. This may cause issues using KeyVault, WinRM and other functionality that uses secrets in the osProfile. In some cases, you can use managed service identities (MSI) to work around these limitations.

### 1.3. Image definitions
Image definitions are a logical grouping for versions of an image. The image definition holds information about why the image was created, what OS it is for, and other information about using the image. An image definition is like a plan for all of the details around creating a specific image. You don't deploy a VM from an image definition, but from the image versions created from the definition.

3 parameters that can be used in combination to describe a Image Definition: **Publisher**, **Offer** and **SKU**.  
The parameters **Operating system state**, **Operating system** and **Hyper-V generation** determine which types of image version they can contain.
Additional parameters can be used to facilitate tracking resources.
+ **Description**: use description to give more detailed information on why the image definition exists. For example, you might have an image definition for your front-end server that has the application pre-installed.
+ **Eula**: can be used to point to an end-user license agreement specific to the image definition.
Privacy Statement and Release notes - store release notes and privacy statements in Azure storage and provide a URI for accessing them as part of the image definition.
+ **End-of-life date**: attach an end-of-life date to your image definition to be able to use automation to delete old image definitions.
+ **Tag**: you can add tags when you create your image definition. For more information about tags, see Using tags to organize your resources
+ **Minimum and maximum vCPU and memory recommendations**: if your image has vCPU and memory recommendations, you can attach that information to your image definition.
+ **Disallowed disk types**: you can provide information about the storage needs for your VM. For example, if the image isn't suited for standard HDD disks, you add them to the disallow list.

### 1.4. Image versions
An image version is used to create a virtual machine or virtual machine scale set.  multiple versions of an image are supported. Image versions can be used multiple times


## 2. Architecture
### 2.1. High Level Design
**Shared Image Gallery** allows to specify the number of replicas Azure needs to keep for images.  the use of multiple replicas can facilitate deployment scenarios as the deployment of VMs can be spread to different replicas, which results in reducing the chance of throttling due to overloading a single replica. 

Best practices for deployment of Virtual Machines and Virtual Machine Scale Set:
+ **For non-Virtual Machine Scale Set deployments**: For every 20 VMs that you create concurrently, we recommend you keep one replica. For example, if you are creating 120 VMs concurrently using the same image in a region, we suggest you keep at least 6 replicas of your image.
+ **For Virtual Machine Scale Set deployments**: For every scale set deployment with up to 600 instances, we recommend you keep at least one replica. For example, if you are creating 5 scale sets concurrently, each with 600 VM instances using the same image in a single region, we suggest you keep at least 5 replicas of your image. <br>

![Shared Image Gallery Scaling](/.attachments/scaling-sig.png)

Resiliency of **Shared Image Gallery** can be achieved by using Azure Zone Redundant Storage(ZRS) to store images.  In the event of an Availability Zone failure in a region, images will still be available for deployment. <br>

![Shared Image Gallery High Availability](/.attachments/zrs-sig.png)

**Shared Image Gallery** also allow to replicate images to different Azure regions automatically.  Each image version can be replicated to different regions depending on the needs of an organization.  A best practise is to replicated the latest version in multiple-regions, while older version are only replicated to 1 or 2 regions. <br>

![Shared Image Gallery Replication](/.attachments/sig-architecture.png)

#### 2.2. Shared Image Gallery Access
#### 2.2.2. RBAC
**Shared Image Galery** support the use of built-in native Azure RBAC controls.  This allows to share images to users, groups, service principals,... . Images can also be shared with external users outside of the tenant where they were created.  A recommendation is to set RBAC Controls at the Gallery level and not at individual image versions.

| Built-in role | Description | Accounts |
| -- | -- | --|
| Owner       | Grants full access to manage all resources, including the ability to assign roles in Azure RBAC.                                                                    | |
| Contributor | Grants full access to manage all resources, but does not allow you to assign roles in Azure RBAC, manage assignments in Azure Blueprints, or share image galleries. | |
| Reader      | View all resources, but does not allow you to make any changes.                                                                                                     | Service Principal |

### 2.3. Service Limits
There are limits, per subscription, for deploying resources using Shared Image Galleries:
+ 100 shared image galleries, per subscription, per region
+ 1,000 image definitions, per subscription, per region
+ 10,000 image versions, per subscription, per region
+ 10 image version replicas, per subscription, per region
+ Any disk attached to the image must be less than or equal to 1TB in size 

Following are the limits per subscriptions and per product:
+ [Azure limits per subscription](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits)

## 3. Service Provisioning
### 3.1. Prerequisites
The following Azure resources need to be in place before this Certified Service can be provisioned:
+ Subscription
+ Resource Group

### 3.2. Deployment parameters
All Parameters indicated with Fixed will not be included as an option during deployment and will be set as default parameter:

|**Parameter**|**Type**|**Prod**|**Non-Prod**| **Implementation** | **Implementation Status** |
|--|--|--|--|--|--|
|**Subscription**	|string|N/A|N/A| <span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span> |
|**Resource Group**	|string|N/A|N/A|<span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span> |
|**Name**			|string|<name>|<name>|<span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span> |
|**location**		|string|West Europe|West Europe|<span style="color:green">**DEFAULT**</span>|<span style="color:grey">**N/A**</span> | 

Legenda:
+ Fixed: The parameter will be hardcoded in the ARM template
+ Enforced by policy: There will be a policy created to manage the parameter changes after deployment
+ Cannot be changed after deployment: The parameter will be unchangeable after deployment.

## 4. Service Management 

## 5. Security Controls 

All product-specific security controls - for the current product version - can be found on the table below:

| Index | Security Requirements | Relevance | Implementation details  | Policy Enforced / Audit | Status  |
|--|--|--|--|--|--|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later).  | |   |  |  |
| CN-SR-02 | Secret and Key management needs to be done by a dedicated database/vault.  |   |   |   |  |
| CN-SR-03 | Encrypt information at rest (Disc encryption).  |  |   |  |  |
| CN-SR-04 | Maintain an inventory of sensitive Information.  |   |   |   |  |
| CN-SR-05 | Use an active discovery tool to identify sensitive data.  |  |   |   |  |
| CN-SR-06 | Protect the database from permanently deleting data by enabling soft delete functionality.  |  |  |   |  |
| CN-SR-07 | Ensure regular automated back ups  |  |  |   |  |
| CN-SR-08 | Enforce the use of Azure Active Directory.  |  |  |   |  |
| CN-SR-09 | Follow the principle of least privilege.  |  |  |   |  |
| CN-SR-10 | Configure security log storage retention.  |  |  |   |  |
| CN-SR-11 | Enable alerts for anomalous activity.  |  |  |   |  |
| CN-SR-12 | Configure central security log management.   |  |  |   |  |
| CN-SR-13 | Enable audit logging of Azure Resources.  |  |  |   |  |
| CN-SR-14 | Enable MFA and conditional access with MFA.  |  |  |   |  |
| CN-SR-15 | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network.  |  |  |   |  |
| CN-SR-16 | Ensure that the endpoint protection for all Virtual Machines is installed.  |  |  |   |  |
| CN-SR-17 | Secure outbound communication to the internet.  |  |  |   |  |
| CN-SR-18 | Enable JIT network access.  |  |  |   |  |
| CN-SR-19 | Run automated vulnerability scanning tools.  |  |  |   |  |
| CN-SR-20 | Use automated tools to monitor network resource configurations and detect changes.  |  |  |   |  |
| CN-SR-21 | Disable remote user access ports (RDP,SSH,Telnet,FTP).  |  |  |   |  |
| CN-SR-22 | Enable automated Patching/ Upgrading.  |  |  |   |  |
| CN-SR-23 | Enable transparent data encryption.  |  |  |   |  |
| CN-SR-24 | Enable OS vulnerabilities recommendations.  |  |  |   |  |
| CN-SR-25 | Configure firewall rules of existing firewalls if necessary.  |  |  |   |  |
| CN-SR-26 | Enable command-line audit logging.  |  |  |   |  |
| CN-SR-27 | Enable conditional access control.  |  |  |   |  |
| CN-SR-28 | Specify service tags to define network access controls on network security groups or Azure Firewall. |  |  |   |  |
| CN-SR-29 | Use Corporate Active Directory Credentials.  |  |  |   |  |