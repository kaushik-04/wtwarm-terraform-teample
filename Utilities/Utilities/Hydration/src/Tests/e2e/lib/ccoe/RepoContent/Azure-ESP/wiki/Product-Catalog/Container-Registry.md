# Container Registry 1.0

| **Status** | <span style="color:orange">**DRAFT**</span> |
|--|--|
| **Version** | v0.1 |
| **Edited By** | @<69524D5A-F086-63B1-95B4-2BD9FF216276>  |
| **Date** | 10/02/2021  |
| **Approvers** |  |
| **Deployment documentation** |  |
| **To Do** | |

[[_TOC_]]

## 1. Introduction
### 1.1. Service Description
Azure Container Registry is a managed Docker registry service based on the open-source Docker Registry 2.0. Create and maintain Azure container registries to store and manage your private Docker container images.

Use Azure Container Registry Tasks to build container images in Azure on-demand, or automate builds triggered by source code updates, updates to a container's base image, or timers.

In this version of the Certified Service, the Azure Container Registry will be deployed with the following features:

+ The container registry must be configured with Premium [capabilities](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-skus) for all environments.
+ Public endpoint will be configured.
+ [RBAC access control](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-roles) will be configured to access the container registry.
+ Images should be uploaded to the container registry from an existing CI pipeline.
+ No customer-managed keys will be used.


## 2.      Architecture


### 2.1. High Level Design
The following figure describes the overall architecture for this service:

![acr_architecture.png](/.attachments/acr_architecture-85271c11-093f-477a-8340-46ff65101041.png)

### 2.2. Consumption endpoints (Data plane)
| Consumption Endpoint (Data plane) | Port
| - | -
| https://{serviceName}.azurecr.io | 443

The following links in the Azure documentation give more information about these endpoints:

+ [Push and pull an image](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-docker-cli)
+ [View Repositories](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-repositories)
+ [Delete container images](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-delete)

#### 2.2.1. Endpoint Access

The service will be deployed as a public endpoint allowing traffic from the Internet; access limited by authentication. This way we ensure that any external service access to this resource.


#### 2.2.2. Endpoint Authorization and Authentication

The access to the exposed endpoints will be authenticated and authorized according to the following table:

| Endpoint (Data Plane) | Authentication | Authorization
| - | - | -
| https://{serviceName}.azurecr.io | Authentication must be done against the Azure Active Directory tenant| Azure Active Directory RBAC|


**RBAC Authorization**: 

| Role/Permission | Access Resource Manager | Create/delete registry | Push image | Pull image | Delete image data | Change policies | Sign images | Description                                                                                                                     |
|-----------------|-------------------------|------------------------|------------|------------|-------------------|-----------------|-------------|---------------------------------------------------------------------------------------------------------------------------------|
| Reader          | X                       |                        |            | X          |                   |                 |             | Can be assigned to end-users who should be able to view the images in a registry.                                               |
| AcrPush         |                         |                        | X          | X          |                   |                 |             | Can be assigned to entities (service principals / managed identities) that need to pull the images.                             |
| AcrPull         |                         |                        |            | X          |                   |                 |             | Can be assigned to DevOps service principals responsible for building and pushing images to the registry.                       |
| AcrDelete       |                         |                        |            |            | X                 |                 |             | Can be assigned to DevOps service principals for automated cleaning or end-users who need to manage the images in a repository. |



### 2.3. Service Limits

Following are the service limits, per subscriptions and product:
+ [Azure limits per subscription](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits)
+ [Resource limits](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits#container-registry-limits)
+ Only one Container Registry should be deployed per environment.
+ Geo-replication support will be added as an optional feature.
+ The following features of the Azure Container Registry will not be supported in the current version of the Container Registry service:
  + ACR webhooks. For simplicity and better traceability, we wanted image lifecycle to be managed in VSTS by leveraging Build and Release Pipelines for now.
    [Deploy to an Azure Web App for Containers](https://docs.microsoft.com/en-us/vsts/pipelines/apps/cd/deploy-docker-webapp?view=vsts)


### 2.4. Monitoring

Azure Container Registry will be enabled for the collection of resource logs.

In our scenario these logs will be stored in a central Log Analytics Workspace where all events from the Landing Zone will be logged. This central Log Analytics workspace will be set by default, and controlled by policy.


Resource logs contain information emitted by Azure resources that describe their internal operation. For an Azure Container Registry, the logs contain authentication and repository-level events stored in the following tables.

- _ContainerRegistryLoginEvents_ - Registry authentication events and status, including the incoming identity and IP address.
- _ContainerRegistryRepositoryEvents_ - Operations such as push and pull for images and other artifacts in registry repositories.

To know more about Azure Container Registry logs, please check [here](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-diagnostics-audit-logs).


Some best practices for monitoring are:
- Enable monitoring across all web apps and services: this way, you can easily visualize end-to-end transactions and connections across all components.
- Setup actionable alerts with notifications and/or remediation: Having a robust alerting pipeline is essential for any monitoring strategy and it is recommended to set up actionable alerts for all predictable failure states.
- Prepare role-based dashboards and workbooks for reporting.


### 2.5. Backup & Restore

It is the responsibility of the workload DevOps teams to protect, backup and restore the images. Following are some functionalities provided by Azure that the workload DevOps teams can leverage on:

- You can easily import (copy) container images to an Azure container registry, without using Docker commands. For example, import images from a development registry to a production registry, or copy base images from a public registry. With this functionality in mind, workload DevOps team can leverage it to do backup on the images contained in the Azure Container Registry. To know more about this functionality, please follow the [following link](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-import-images).

- Moreover, the Azure DevOps repository provides the capability to push/restore the images that were contained within the ACR.


- To prevent unexpected changes, workload DevOps team can lock or protect an image version or a repository so that it can't be deleted or updated. More information to do so can be found [here](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-image-lock#protect-an-image-or-repository-from-deletion). 


### 2.6 Disaster Recovery

For a disaster recovery scenario within the CCoE Azure Container Registry Product, the geo-replication functionality can be enabled. This means that a workload can choose to enable or disable geo-replication for the deployed resource.

Geo-replication enables an Azure container registry to function as a single registry, serving multiple regions with multi-master regional registries.

A geo-replicated registry provides the following benefits:

- Single registry/image/tag names can be used across multiple regions
- Network-close registry access from regional deployments
- No additional egress fees, as images are pulled from a local, replicated registry in the same region as your container host
- Single management of a registry across multiple regions



## 3. Service Provisioning


### 3.1. Prerequisites

The following Azure resources need to be in place before this Certified Service can be provisioned:

- Resource Group

### 3.2. Deployment parameters


|                                     | **Prod**                                    | **Non**-Prod                                | **Implementation** | Implementation Status           |
|-------------------------------------|-----------------------------------------|-----------------------------------------|----------------|---------------------------------|
| **Subscription** | N/A | N/A | <span style="color:green">**PARAMETER**</span>| <span style="color:grey">**N/A**</span>| 
| **Resource Group**  | N/A | N/A |<span style="color:green">**PARAMETER**</span>| <span style="color:grey">**N/A**</span>|
| **Name** | <name> | <name> | <span style="color:green">**PARAMETER**</span>| <span style="color:green">**IMPLEMENTED**</span>|
| **Region** |West EU (fixed) <br> Enforced by Policy | West EU (fixed) <br> Enforced by Policy | <span style="color:green">**DEFAULT**</span>| <span style="color:green">**IMPLEMENTED<br>Policy on root**</span>|
| **SKU** |Basic, Standard, Premium  | Basic, Standard, Premium  | <span style="color:green">**PARAMETER**</span>| <span style="color:green">**IMPLEMENTED**</span>|
|**Connectivity method**|Public Endpoint (fixed)|Public Endpoint (fixed)|<span style="color:green">**DEFAULT**</span>|<span style="color:green">**IMPLEMENTED<br>Policy**</span>
| **Customer Managed Key** | Disabled (fixed) | Disabled (fixed) |<span style="color:green">**DEFAULT**</span> | <span style="color:green">**IMPLEMENTED<br>Policy**</span>|
| **Geo Replication** | No | No|<span style="color:green">**DEFAULT**</span> |<span style="color:green">**IMPLEMENTED<br>Policy**</span> |

## 4. Service Management for Key Vault

All product-specific MSMCF controls - for the current product version - can be found on the table below:

|  **Title**                                                                                                                                                                                                                        |  **Functional Control   Description**                                                                                        |  **Category**                            |  **Product Assessment Q&A**                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |  **Implementation**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |  **Status**                                                              |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------              |-------------------------------------------------------------------------------------------------------        |----------------     |-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------              |------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |--------------------------------------------------  |
|  **M-STD02**   |  Health alerts are automatically   generated, correlated and   managed   based on event monitoring                             |  Standard                       |  Monitoring Resource Health alerts   covered on subscription level.               <br> -Health alerts are automatically triggered by Azure.            <br> -No product specific health alerting or dashboard/report   requirements.            <br> -No product specific health alerting or dashboard/report   requirements.            <br> -Guidance for DevOps teams about monitoring best practices to   be   documented on the wiki product   description.                         |  - This control is applied by   defining Resource Health Alerts on a subscription level, therefore   provided   for all certified   products/platforms.       <br>   <br> - Additional resource monitoring is under the   responsibility of each workload DevOps   team.                                                                                                                                                                                                                                                                                |   <span style="color:green">**Final**</span>     |
|  **M-STD05**                                                |  Disaster Recovery (DR) scenario’s   are applied and tested     periodically                                                 |  Standard                       |  Considerations for DR and higher   availability:      <br> -   Geo-replication option (mandatory)        <br> - General documentation available in the section Geo   Replication                                                                                                                                                                                                                                                                                                           |  <br>  - Since the deployment   is scripted, the DevOps team is capable of   deploying the Azure Container     Registry again in case of a disaster.       <br> - The customer is   responsible for choosing the Geo-replication     sites. Geo-replication enables an Azure container registry to function   as a   single registry, serving   multiple regions with multi-master regional     registries and thus functions as DR scenario.                                                                                                                                                                                                                                                                                          |   <span style="color:green">**Final**</span>     |
|  **M-STD06**        |  RTO / RPO requirements are   achieved for backup and restore                                                           |  Standard                       |  <br> - Ensure regular   backups are performed (mandatory)          <br>- Backup Container Registry (Mandatory)       <br> - Registry protection   (Optional)       <br> - Guidance   for DevOps teams about backup & restore best   practices to be documented on the wiki   product description.                                                                                                                                                                                            |  - The Azure DevOps Repo   (out-of-the -box functionality) used by the     DevOps team provides the capability to push/restore the images that   were   contained within the ACR.       <br>- The Azure Container   Registry is backed up in the form of geo     replication. Geo-replication enables an Azure container registry to   function   as a single registry,   serving multiple regions with multi-master regional   registries .       <br>- It is the responsibility   of the application teams to backup the     images.       <br>-   Applying an RBAC role to restrict the restore capabilities is   not applicable here (ACR images can be   just redeployed - from the     corresponding Repo)                         |   <span style="color:green">**Final**</span>      |

 

## 5. Security Controls for Container Registry

Microsoft Container Registry  best practices: 
All product-specific security controls - for the current product version - can be found on the table below:

| Index    | Security Requirement                                                                                 | Relevance                                                                                                                                                                                                                                         | Implementation details                                                                         | Policy Enforced / Audit | Design Status                                      |Implementation Status                                      |
|----------|------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|-------------------------|---------------------------------------------|---------------------------------------------|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later).                      | Not applicable. <BR>_(Implemented by design for ACR resource.)_                                                                                                                                                                                   |  NA                                                                                             |  NA                  | <span style="color:green">**FINAL**</span>  | <span style="color:green">**IMPLEMENTED BY DEFAULT**</span>
| CN-SR-02 | Secret and Key management needs to be done by a dedicated database/vault.                            | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-03 | Encrypt information at rest (Disc encryption).                                                       | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:green">**IMPLEMENTED BY DEFAULT**</span>
| CN-SR-04 | Maintain an inventory of sensitive Information.                                                      | Not applicable.                                                                                                                                                                                 |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-05 | Use an active discovery tool to identify sensitive data.                                             | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-06 | Protect the database from permanently deleting data by enabling soft delete functionality.           |NA                                                                                                                                                                              |  NA                                                           |  NA| <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>
| CN-SR-07 | Ensure regular automated back ups                                                                    | If you choose to take a backup of your images to another ACR, then you can use [import command]( https://docs.microsoft.com/en-us/azure/container-registry/container-registry-import-images) This even works if you want to copy images from any other registry to ACR.  |  Customer responsibility                                                                       |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-08 | Enforce the use of Azure Active Directory.                                                           | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span> 
| CN-SR-09 | Follow the principle of least privilege.                                                             | [RBAC access control](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-roles).    | - DevOps Service Principals responsible for building and pushing images will be assigned **AcrPush**. <br> - Service Principals and Managed Identities consuming the images will only be assigned **AcrPull**.  |     |  |
| CN-SR-10 | Configure security log storage retention.                                                            | Log Analytics retention is configured on the LAW product itself. More information: https://docs.microsoft.com/en-us/azure/key-vault/key-vault-logging                                  |  NA                                                                                 | NA| <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span> 
| CN-SR-11 | Enable alerts for anomalous activity.                                                                | Image scanning with Azure Security Center                                                                                                                                                                                                                                                         |  This control is inherited from the Azure Security Center configuration applied at the Subscription Level.     |  Enforced| <span style="color:green">**FINAL**</span>  |  <span style="color:green">**IMPLEMENTED BY DEFAULT**</span>
| CN-SR-12 | Configure central security log management.                                                           | Security logging needs to be implemented (enforced). Policies will be put in place which enforce the usage of specific Eventhub and Analytics workspace. More information: https://docs.microsoft.com/en-us/azure/key-vault/general/howto-logging                                                                                                     | Custom Policy<br>(Audit/DeployIfNotExists)                                                                                | Enforced |<span style="color:green">**FINAL**</span> | <span style="color:green">**IMPLEMENTED<br>Policy on Root**</span>
| CN-SR-13 | Enable audit logging of Azure Resources.                                                            | [Resource Audit Logs](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-diagnostics-audit-logs)                                                                                                                                                                                            | It will be enabled using Azure Monitor for the collection of resource logs. | Enforced |<span style="color:green">**FINAL**</span> | <span style="color:green">**IMPLEMENTED<br>Policy on Root**</span> |  
| CN-SR-14 | Enable MFA and conditional access with MFA.                                                          | Not applicable. Inherited from Azure AD                                                                                                                                                                                                                                  |  NA                                                                                            |  NA (inherited)                    | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span> 
| CN-SR-15 | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network.     | Not directly applicable. Needs to be implemented on NSG/Azure Firewall level.Access only for the LZ resources                                                                                                                                     |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-16 | Ensure that the endpoint protection for all Virtual Machines is installed.                           | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-17 | Secure outbound communication to the internet.                                                       | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>
| CN-SR-18 | Enable JIT network access.                                                                           | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>
| CN-SR-19 | Run automated vulnerability scanning tools.                                                          |   [Azure Defender for Container Registries](https://docs.microsoft.com/en-us/azure/security-center/defender-for-container-registries-introduction)      |  This control is inherited from the Azure Security Center configuration applied at the Subscription Level.     |  NA                     | <span style="color:green">**FINAL**</span>  |  <span style="color:green">**IMPLEMENTED BY DEFAULT**</span>
| CN-SR-20 | Use automated tools to monitor network resource configurations and detect changes.                   | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>
| CN-SR-21 | Disable remote user access ports (RDP,SSH,Telnet,FTP).                                               | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-22 | Enable automated Patching/ Upgrading.                                                                | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-23 | Enable transparent data encryption.                                                                  | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-24 | Enable OS vulnerabilities recommendations.                                                           | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-25 | Configure firewall rules of existing firewalls if necessary.                                         | Firewall can be enabled and configured on he Container Registry, but at deployment we will follow the public by default security principles and open the firewall to all traffic.                                                                                                                                                                     |  NA                                                           |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:green">**IMPLEMENTED**</span>
| CN-SR-26 | Enable command-line audit logging.                                                                   | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>  
| CN-SR-27 | Enable conditional access control.                                                                   | Not applicable (only Service principal has access to AKV).                                                                                                                                                                                        |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>  
| CN-SR-28 | Specify service tags to define network access controls on network security groups or Azure Firewall. | We have tags defined in the ARM template.                                                                                                                                                                                                                                   |  Embeded in the ARM template                                                                                            |    NA                 | <span style="color:green">**FINAL**</span>  | <span style="color:green">**IMPLEMENTED**</span>
| CN-SR-29 | Use Corporate Active Directory Credentials.                                                          | Azure AD is the authentication mechanism, if AAD is synchronized with Corporate Active Directory then this requirement is compliant.                                                                                                              |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>

## 6. Implemented Policies

This section describes the policies which will be implemented for Container Registry.
These policies will be assigned when deploying a Container Registry or when deploying a Subcription/Management Group, this separation will be discussed below.

| Policy | Description | Implementation Scope
|--|--|--|
|Enforce SKUs policy|This policy restrict the SKUs you can specify when deploying Container Registry|Subscription |
|Enforce RBAC parameter|Disable RBAC authorization on Data Plane to manage Keys, Secrets and Certificates (Temporary deny policy)|Subscription |
|Deploy Diagnostic settings if those are not correct or don't exist| This policy checks whether the Container Registry has Diagnostic settings enabled and whether the correct EventHub and Log analytics workspace Ids are used|Deployed on each Subscription or Management group with the relevant Ids|
