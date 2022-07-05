# Resource Group 1.0

| **Status** | <span style="color:orange">**FINAL DRAFT**</span> |
|--|--|
| **Version** | v0.1 |
| **Edited By** | Rinat Nosonov |
| **Date** | 30/01/2021  |
| **Approvers** |  |
| **Deployment documentation** | [Resource Group 1.0 Implementation Details](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fresourcegroup%2F1.0%2Freadme.md&version=GBusers%2Fmastorha%2FRinatNosonov%2FPolicyComponents) |
| **To Do** |  |

[[_TOC_]]

## 1. Introduction

### 1.1. Service Description
A resource group is a container that holds related resources for an Azure solution. The resource group can include all the resources for the solution, or only those resources that you want to manage as a group. You decide how you want to allocate resources to resource groups based on what makes the most sense for your organization. Generally, add resources that share the same lifecycle to the same resource group so you can easily deploy, update, and delete them as a group.

The resource group stores metadata about the resources. Therefore, when you specify a location for the resource group, you are specifying where that metadata is stored. 

## 2. Architecture

### 2.1. Management Scope Hierarchy
Azure provides four levels of management scope: management groups, subscriptions, resource groups, and resources. The following image shows the relationship of these levels.

![image.png](https://dev.azure.com/contoso-azure/8c71d833-fcd8-42b9-a81d-d3092c875f91/_apis/git/repositories/e9bc2d50-a628-4a26-bc6c-63bab6240428/items?path=%2F.attachments%2Fscope-levels.png&versionDescriptor%5BversionOptions%5D=0&versionDescriptor%5BversionType%5D=0&versionDescriptor%5Bversion%5D=RinatNosonov%2FResourceGroupDoc&resolveLfs=true&%24format=octetStream&api-version=5.0)

Management groups: These groups are containers that help you manage access, policy, and compliance for multiple subscriptions. All subscriptions in a management group automatically inherit the conditions applied to the management group.<br><br>
Subscriptions: A subscription logically associates user accounts and the resources that were created by those user accounts. Each subscription has limits or quotas on the amount of resources you can create and use. Organizations can use subscriptions to manage costs and the resources that are created by users, teams, or projects.<br><br>
Resource groups: A resource group is a logical container into which Azure resources like web apps, databases, and storage accounts are deployed and managed.<br><br>
Resources: Resources are instances of services that you create, like virtual machines, storage, or SQL databases.
 
## 3. Service Provisioning

### 3.1. Prerequisites
The following Azure resources need to be in place before this Certified Service can be provisioned:

- Subscription

### 3.2. Deployment parameters
All Parameters indicated with Fixed will not be included as an option during deployment of the artifact and will be set as default parameter:

|Parameter|Prod|Non-Prod|Implementation|Implementation Status|
|--|--|--|--|--|
|**Subscription**|N/A|N/A| <span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span>|
|**Name**|<client>-<deploy-zone-abbreviated>-<env-id>-<platform-id>-<freetext>-rg|<client>-<deploy-zone-abbreviated>-<env-id>-<platform-id>-<freetext>-rg|<span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**<br>Policy on root to enforce naming conventions needed</span>|
|**Resource Lock**|True/False|True/False|<span style="color:green">**PARAMETER**</span>|<span style="color:green">**Implemented**</span>|
|**Tags**|application-id<br>cost-center<br>deployment-id<br>environment<br>(Fixed)|application-id<br>cost-center<br>deployment-id<br>environment<br>(Fixed)|<span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**<br>Enforced by Policy on root</span>|
|**Region**|West EU (Default Value)/North Europe|West EU (Default Value)/North Europe|<span style="color:green">**PARAMETER**</span>|<span style="color:green">**Implemented**</span>|

Legenda:
- Fixed: The parameter is enforced in the ARM template/Artifact
- Enforced by policy: There will be a policy created to manage the parameter changes after deployment
- Cannot be changed after deployment: The parameter will be unchangeable after deployment.

## 4. Service Management 

All product-specific MSMCF controls - for the current product version - can be found on the table below:

| **MSM Code** | **Functional Control Description** | **Product Assessment Q&A** | **Validated** | **Implementation** | **Status** |
|----------|----------------------------------------------------------------------------------------------------------------------------|------------------------|------------------------|------------------------|----|----|
| **M-STD01** | Health alerts are automatically generated, correlated and managed based on event monitoring.                            |   No event monitoring on Resource Groups    |      Yes     |  N/A |  <span style="color:green">**FINAL**</span>  |
|  **M-STD04**        |       Disaster Recovery (DR) scenario’s are applied and  tested periodically          | The Resource Group is replicated between the availability zones of a region |  Yes  |  N/A |    <span style="color:green">**FINAL**</span>   |
|  **M-PaaS01**       |        RTO / RPO requirements are achieved for PaaS backup and restore           |  N/A  |    No    |  N/A  |    <span style="color:green">**FINAL**</span>  |


## 5. Security Controls 

All product-specific security controls - for the current product version - can be found on the table below (and with additional guidelines [here](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/473/Cloud-Native-Security-Controls)):

| Index | Security Requirements | Relevance | Implementation details  | Policy Enforced / Audit | Design Status  | Implementation Status |
|--|--|--|--|--|--|--|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later).  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-02 | Secret and Key management needs to be done by a dedicated database/vault.  |  N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-03 | Encrypt information at rest (Disc encryption).  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-04 | Maintain an inventory of sensitive Information.  |  N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-05 | Use an active discovery tool to identify sensitive data.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-06 | Protect the database from permanently deleting data by enabling soft delete functionality.  |  N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-07 | Ensure regular automated back ups  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-08 | Enforce the use of Azure Active Directory.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-09 | Follow the principle of least privilege.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-10 | Configure security log storage retention.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-11 | Enable alerts for anomalous activity.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-12 | Configure central security log management.   |  N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-13 | Enable audit logging of Azure Resources.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-14 | Enable MFA and conditional access with MFA.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-15 | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-16 | Ensure that the endpoint protection for all Virtual Machines is installed.  |  N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-17 | Secure outbound communication to the internet.  | Following the public by default principle |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-18 | Enable JIT network access.  | Following the public by default principle |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-19 | Run automated vulnerability scanning tools.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-20 | Use automated tools to monitor network resource configurations and detect changes.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-21 | Disable remote user access ports (RDP,SSH,Telnet,FTP).  |   N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-22 | Enable automated Patching/ Upgrading.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-23 | Enable transparent data encryption.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-24 | Enable OS vulnerabilities recommendations.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-25 | Configure firewall rules of existing firewalls if necessary.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-26 | Enable command-line audit logging.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-27 | Enable conditional access control.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-28 | Specify service tags to define network access controls on network security groups or Azure Firewall. | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|
| CN-SR-29 | Use Corporate Active Directory Credentials.  | N/A |  N/A  |  N/A |<span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>|

## 6. Policy Deployments

No specific Resource Groups policies will be deployed