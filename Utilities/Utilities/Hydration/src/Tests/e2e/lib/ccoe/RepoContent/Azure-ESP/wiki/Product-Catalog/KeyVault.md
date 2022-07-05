# Key Vault 1.0

| **Status**    | <span style="color:orange">**Final Version**</span> |
|-----------|---------------|
| **Version**   | v1.0         |
| **Edited By** | Rinat Nosonov<br>Peter Theuns |
| **Date**      | 20/01/2021     |
| **Approvers** | Frederik De Ryck<br>Jonas De Troy              |
| **Deployment documentation** | [Key Vault 1.0 Implementation Details](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fkeyvault%2F1.0%2FREADME.md&_a=preview) |
| **To Do**     |   |

[[_TOC_]]

## 1. Introduction

### 1.1. Service Description

[Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-overview)  is a cloud service that allows you to securely store an centralize secrets, keys and certificates. Azure Key Vault helps solve the following problems:

- Secrets Management - Azure Key Vault can be used to Securely store and tightly control access to tokens, passwords, certificates, API keys, and other secrets

- Key Management - Azure Key Vault can also be used as a Key Management solution. Azure Key Vault makes it easy to create and control the encryption keys used to encrypt your data.

- Certificate Management - Azure Key Vault is also a service that lets you easily provision, manage, and deploy public and private Secure Sockets Layer/Transport Layer Security (SSL/TLS) certificates for use with Azure and your internal connected resources.

- Store secrets backed by Hardware Security Modules - The secrets and keys can be protected either by software or FIPS 140-2 Level 2 validates HSMs

 
In this version of the Certified Service, the Azure Key Vault will be deployed with the following features:

- A [Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-whatis)  with [Standard SKU](https://azure.microsoft.com/en-us/pricing/details/key-vault/).

- A Key Vault will be configured with the [soft-delete and purge protection](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-ovw-soft-delete) enabled. Soft-delete is enforced by default by Azure. Once enabled the purge option, it cannot be disabled anymore.

- Permission model for Azure Key Vault is split in a Management and Data plane access model:
   - The Management plane is where you manage Key Vault itself and it is the interface used to create and delete vaults. You can also read key vault properties and manage access policies. 

   - Data plane allows you to work with the data stored in a key vault. You can add, delete, and modify keys, secrets, and certificates. Permissions follow the Access Policy model where these policies are being assigned to the KeyVaults in order to authorize the user to perform the necessary tasks. Currently, RBAC for Data Plane is in preview, therefore we will use Access Policies until the RBAC is removed from Preview. With RBAC on Data Plane the permissions will be able to be handled via RBAC for Key Vault Data Plane. (An approach needs to be set-up in order to make the migration from access policies to RBAC in an efficient manner)

- Firewall rules can be configured to allow [Azure Virtual Networks](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-overview-vnet-service-endpoints#configure-key-vault-firewalls-and-virtual-networks) , [Internet Public IP ranges](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-overview-vnet-service-endpoints#usage-scenarios)  and [trusted Microsoft Services](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-overview-vnet-service-endpoints#trusted-services). Notice that Azure DevOps is not in the trusted Microsoft Services list and needs to be additionally whitelisted.
Also, if additional services need to have access, the Azure Key Vault Firewall parameters need to be adapted by the CCoE team. The Private endpoint option shouldn't be enabled.

  
## 2. Architecture

### 2.1. High Level Design

The following figure describes the overall architecture for this service:


![image.png](/.attachments/image-cf86a8c6-1ca0-4f18-a958-0e77c46b351c.png)


The following Azure Services will be deployed in this Certified Service:

- [Key Vault 1.0 Certified Service](https://docs.microsoft.com/en-us/azure/key-vault/general/overview)
 

### 2.2. Data plane (Access Policies) (Consumption keys, certificates and secrets by endpoints)

You can grant data plane access by setting Key Vault access policies for a key vault. To set these access policies, a user, group, or application must have Key Vault Contributor permissions for the management plane for that key vault.

You grant a user, group, or application access to execute specific operations for keys or secrets in a key vault. Key Vault supports up to 1,024 access policy entries for a key vault. To grant data plane access to several users, create an Azure AD security group and add users to that group.

You can see the full list of vault and secret operations here: [Key Vault Operation Reference](https://docs.microsoft.com/en-us/rest/api/keyvault/#vault-operations)

Key Vault access policies grant permissions separately to keys, secrets, and certificates. Access permissions for keys, secrets, and certificates are at the vault level.

After the preview mode for  [Azure RBAC permission model](https://docs.microsoft.com/en-us/azure/key-vault/general/rbac-guide#azure-built-in-roles-for-key-vault-data-plane-operations-preview) is removed, then the Access Policies should be replaced by RBAC. RBAC Permission model provides the following roles to manage the Data Plane. 

| **Built-in role**                        | **Description**          | **Accounts**|
|----|----------------------|----|
| Key Vault Administrator              | Perform all data plane operations on a key vault and all objects in it, including certificates, keys, and secrets. Cannot manage key vault resources or manage role assignments. Only works for key vaults that use the 'Azure role-based access control' permission model. |  Service Principal  |
| Key Vault Certificates Officer       | Perform any action on the certificates of a key vault, except manage permissions. Only works for key vaults that use the 'Azure role-based access control' permission model.                                                                                                |    |
| Key Vault Crypto Officer             | Perform any action on the keys of a key vault, except manage permissions. Only works for key vaults that use the 'Azure role-based access control' permission model.                                                                                                        |    |
| Key Vault Crypto Service Encryption  | Read metadata of keys and perform wrap/unwrap operations. Only works for key vaults that use the 'Azure role-based access control' permission model.                                                                                                                        |    |
| Key Vault Crypto User                | Perform cryptographic operations using keys. Only works for key vaults that use the 'Azure role-based access control' permission model.                                                                                                                                     |    |
| Key Vault Reader                     | Read metadata of key vaults and its certificates, keys, and secrets. Cannot read sensitive values such as secret contents or key material. Only works for key vaults that use the 'Azure role-based access control' permission model.                                       |  Create Azure AD Group  |
| Key Vault Secrets Officer            | Perform any action on the secrets of a key vault, except manage permissions. Only works for key vaults that use the 'Azure role-based access control' permission model.                                                                                                     |    |
| Key Vault Secrets User               | Read secret contents. Only works for key vaults that use the 'Azure role-based access control' permission model.                          |    |

The following links in the Azure documentation give more information about these endpoints:

- [Azure Key Vault Data Plane access control](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-secure-your-key-vault#data-plane-access-control)

- [Azure Key Vault REST API reference](https://docs.microsoft.com/en-us/rest/api/keyvault/)

- [Authentication, Requests and Responses](https://docs.microsoft.com/en-us/azure/key-vault/authentication-requests-and-responses)


#### 2.2.1. Endpoint Access

| Consumption Endpoint (Data plane) | Port|
| - | - |
|https://{serviceName}.vault.azure.net/ | 443|

The service will be deployed as a public endpoint storing Landing Zone infrastructure and application keys, secrets and certificates, allowing traffic to directly reach the KeyVault. 

![image.png](/.attachments/image-23fd29e2-3568-4e67-98da-12376a9a7bbc.png)

#### 2.2.2. Endpoint Authorization and Authentication

The access to the exposed endpoints will be authenticated and authorized according to the following table:

| Endpoint (Data Plane) | Authentication | Authorization
| - | - | -
| [https://{serviceName}.vault.azure.net/| Authentication must be done against the Azure Active Directory tenant|The authorization will be accomplished using Access Policies for the time that RBAC is in Preview|


### 2.3 Management Plane 

RBAC for the Management Plane will be provided built-in roles when creating a Key Vault:

- "Key Vault Administrator": A list of Service Principals object Ids must be provided as input to give them the role definition "Key Vault Administrator". This role will be mandatory. This role performs all data plane operations on a key vault and all objects in it, including certificates, keys, and secrets. Cannot manage key vault resources or manage role assignments.

- "Key Vault Reader": A list of Service Principals object Ids can be provided as input to give them the role definition "Key Vault Reader". This role will be optional. This role can read metadata of key vaults and its certificates, keys, and secrets. Cannot read sensitive values such as secret contents or key material.




 ### 2.4. Service Limits

Following are the limits per subscriptions and per product:

- [Azure limits per subscription](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits)

- [Azure Key Vault limits](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-service-limits)

 
## 3. Service Provisioning


### 3.1. Prerequisites

The following Azure resources need to be in place before this Certified Service can be provisioned:

- Subscription
- Resource Group
- Central Log Analytics Workspace
- Eventhub (see CN-SR-12)

### 3.2 Deployment parameters

All Parameters indicated with Fixed will not be included as an option during deployment of the artifact and will be set as default parameter:

|**Parameter**|**Prod**|**Non-Prod**| **Implementation** | **Implementation Status** |
|--|--|--|--|--|
|**Subscription**|N/A|N/A| <span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span>
|**Resource Group**|N/A|N/A|<span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span>
|**Name**|<name>|<name>|<span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span>
|**Region**|West EU (Default Value)/North Europe|West EU (Default Value)/North Europe|<span style="color:green">**PARAMETER**</span>|<span style="color:green">**IMPLEMENTED<br>Policy on root allows West and North Europe**</span>
|**SKU**|Standard (fixed)<br>Cannot be changed after deployment|Standard (fixed)<br>Cannot be changed after deployment|<span style="color:green">**PARAMETER**</span>|<span style="color:green">**IMPLEMENTED<br>**</span>
|**Soft delete**|True (Fixed)<br>Enforced by  Policy|True (Fixed)|<span style="color:green">**PARAMETER**</span>|<span style="color:green">**IMPLEMENTED**</span>
|**Soft delete retention days**|7-90 days (90 days defaultvalue)<br>Cannot be changed after deployment|7-90 days (90 days defaultvalue)<br>Cannot be changed after deployment|<span style="color:green">**PARAMETER**</span>|<span style="color:green">**IMPLEMENTED**</span>
|**Azure VM for deployment**|True/False|True/False|<span style="color:green">**PARAMETER**</span>|<span style="color:green">**IMPLEMENTED**</span>
|**Azure Resource Manager for Template**|True/False|True/False|<span style="color:green">**PARAMETER**</span>|<span style="color:green">**IMPLEMENTED**</span>
|**Azure Disk Encryption for Volume Encryption**|True/False|True/False|<span style="color:green">**PARAMETER**</span>|<span style="color:green">**IMPLEMENTED**</span>
|**Permission model**|RBAC (Management Plane)<br>Access Policy (Data Plane)|RBAC (Management Plane)<br>Access Policy (Data Plane)|<span style="color:green">**DEFAULT**<br>**PARAMETER**</span>|<span style="color:green">**IMPLEMENTED**</span>
|**Connectivity method**|Public Endpoint|Public Endpoint|<span style="color:green">**DEFAULT**</span>|<span style="color:green">**IMPLEMENTED**</span>
|**Purge Protection**|True (Fixed)<br>Enforced by Policy<br>Cannot be changed after deployment (if purge is enabled)|False|<span style="color:green">**PARAMETER**</span>|<span style="color:green">**IMPLEMENTED**</span>

Legenda:
- Fixed: The parameter is enforced in the ARM template/Artifact
- Enforced by policy: There will be a policy created to manage the parameter changes after deployment
- Cannot be changed after deployment: The parameter will be unchangeable after deployment.

## 4. Service Management for Key Vault

All product-specific MSMCF controls - for the current product version - can be found on the table below:

 

| **MSM Code** | **Functional Control Description** | **Product Assessment Q&A** | **Validated** | **Implementation** | **Status** |
|----------|----------------------------------------------------------------------------------------------------------------------------|------------------------|------------------------|------------------------|----|----|
| **M-STD01** | Health alerts are automatically generated, correlated and managed based on event monitoring.                            |   - Health alerts are automatically triggered by Azure. <br> - No product specific health alerting or dashboard/report requirements. <br> - Guidance for DevOps teams about monitoring best practices to be documented on the wiki product description. (e.g. B[asic Key Vault metrics to monitor](https://docs.microsoft.com/en-us/azure/key-vault/general/alert#basic-key-vault-metrics-to-monitor) )<br><br>       |      Yes     |   - This control is applied by defining Resource Health Alerts on a subscription level, therefore provided for all certified products/platforms. <br> <br> - Additional resource monitoring is under the responsibility of each workload DevOps team.  <br> <br>           |  <span style="color:grey">**N/A**<br>Needs to be configured on the Log Analytics Workspace certified product</span>   |
|  **M-STD04**        |       Disaster Recovery (DR) scenario’s are applied and  tested periodically          | <br>- Geo-replication included as part of the PAAS service  <br>- Automatic Failover is not relevant <br> -Guidance for DevOps teams about DR best practices to be documented on the wiki product description.|  No  |      <br>  - Key Vault DR concept is part of Azure´s PaaS service, therefore no additional implementations needed: <br> - Key Vault are replicated within the region and to a secondary region and DR is implemented by default and triggered and rolled back automatically and transparently. <br> - No DR testing is needed (or possible) because the DR is managed by Microsoft Azure <br><br>      |    <span style="color:green">**FINAL**</span>   |
|  **M-PaaS01**       |        RTO / RPO requirements are achieved for PaaS backup and restore           |  <br> - ensure regular backups are performed (mandatory)  <br>- Backup Container Registry (Mandatory)  <br> - Guidance for DevOps teams about backup & restore best practices to be documented on the wiki product description.     |    No    |   - Key Vault backup:. <br>- No backup implemented on a product level. <br>- Secrets can be secured, in case of critical business need, manually via PowerShell scripts. Product team will provide only documentation. <br>- The customer is responsible for backup and restore of its Key Vault <br> Key Vault Soft Delete:<br>- Current setup: enabled for Production and Global. <br> Key Vault soft-delete will t[urn into an Azure default](https://docs.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview) <br>       |    <span style="color:green">**Final**</span>    |

 

## 5. Security Controls for Key Vault

Microsoft Key Vault best practices: 
All product-specific security controls - for the current product version - can be found on the table below:

| Index    | Security Requirement                                                                                 | Relevance                                                                                                                                                                                                                                         | Implementation details                                                                         | Policy Enforced / Audit | Design Status                                      |Implementation Status                                      |
|----------|------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|-------------------------|---------------------------------------------|---------------------------------------------|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later).                      | Not applicable. <BR>_(Implemented by design for AKV resource.)_                                                                                                                                                                                   |  NA                                                                                             |  NA                  | <span style="color:green">**FINAL**</span>  | <span style="color:green">**IMPLEMENTED BY DEFAULT**</span>
| CN-SR-02 | Secret and Key management needs to be done by a dedicated database/vault.                            | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-03 | Encrypt information at rest (Disc encryption).                                                       | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:green">**IMPLEMENTED BY DEFAULT**</span>
| CN-SR-04 | Maintain an inventory of sensitive Information.                                                      | Not applicable. <BR>_(Every information in AKV is sensitive.)_                                                                                                                                                                                    |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-05 | Use an active discovery tool to identify sensitive data.                                             | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-06 | Protect the database from permanently deleting data by enabling soft delete functionality.           | Enforce Azure Key Vault soft-delete is enabled.                                                                                                                                                                                                   |  Built-In Policy and Mandatory ARM Parameter                                                            |  Enforced               | <span style="color:green">**FINAL**</span>  | <span style="color:green">**IMPLEMENTED**</span>
| CN-SR-07 | Ensure regular automated back ups                                                                    | Implement regular automated AKV backups. https://docs.microsoft.com/en-us/azure/key-vault/general/security-baseline#data-recovery. See also **M-PaaS01** above.	                                                                                                                 |  Customer responsibility                                                                       |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-08 | Enforce the use of Azure Active Directory.                                                           | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span> 
| CN-SR-09 | Follow the principle of least privilege.                                                             | [RBAC access control](https://docs.microsoft.com/en-us/azure/key-vault/general/rbac-guide). A list of Service Principals object Ids can be provided as input to give them the role definition of 'Key Vault Administrator' or 'Key Vault Reader'. |  Key Vault Administrator RBAC role for the Service Principal on Management Plane. Access Policies on Data Plane level. Indicated in ARM template   |    Enforced                 | <span style="color:green">**FINAL**</span>  |<span style="color:green">**IMPLEMENTED**</span> 
| CN-SR-10 | Configure security log storage retention.                                                            | Log Analytics retention is configured on the LAW product itself. More information: https://docs.microsoft.com/en-us/azure/key-vault/key-vault-logging                                  |  NA                                                                                 | NA| <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span> 
| CN-SR-11 | Enable alerts for anomalous activity.                                                                | Threat Protection for AKV in Azure Security Center needs to be enforced using Defender for Key Vault. https://docs.microsoft.com/en-us/azure/security-center/advanced-threat-protection-key-vault                                                                              |  Enable Azure defender for KeyVault                                                                                |  Audit                  | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**<br>Will be enabled by MG policy in every subscription</span>  
| CN-SR-12 | Configure central security log management.                                                           | Security logging needs to be implemented (enforced). Policies will be put in place which enforce the usage of specific Eventhub and Analytics workspace. More information: https://docs.microsoft.com/en-us/azure/key-vault/general/howto-logging                                                                                                     | Custom Policy<br>(Audit/DeployIfNotExists)                                                                                |  Enforced                  | <span style="color:green">**FINAL**</span>  |<span style="color:green">**IMPLEMENTED**<br>Policies will be integrated into the framework for Subscription and Management Group</span>
| CN-SR-13 | Enable audit logging of Azure Resources.                                                            | Enable (enforce) diagnostic logs on the service to the Central Log Analytics Workspace and eventHub.<br>https://docs.microsoft.com/en-us/azure/key-vault/general/alert                                                                                                                                                                                                  | ARM template to send logs and metrics to the eventHub<br> Custom Policy (Audit/DeployIfNotExists)                                                                                   |  Enforced | <span style="color:green">**FINAL**</span>  | <span style="color:green">**IMPLEMENTED**</span> 
| CN-SR-14 | Enable MFA and conditional access with MFA.                                                          | Not applicable. Inherited from Azure AD                                                                                                                                                                                                                                  |  NA                                                                                            |  NA (inherited)                    | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span> 
| CN-SR-15 | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network.     | Not directly applicable. Needs to be implemented on NSG/Azure Firewall level.Access only for the LZ resources                                                                                                                                     |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-16 | Ensure that the endpoint protection for all Virtual Machines is installed.                           | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-17 | Secure outbound communication to the internet.                                                       | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>
| CN-SR-18 | Enable JIT network access.                                                                           | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>
| CN-SR-19 | Run automated vulnerability scanning tools.                                                          | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>
| CN-SR-20 | Use automated tools to monitor network resource configurations and detect changes.                   | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  | <span style="color:grey">**N/A**</span>
| CN-SR-21 | Disable remote user access ports (RDP,SSH,Telnet,FTP).                                               | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-22 | Enable automated Patching/ Upgrading.                                                                | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-23 | Enable transparent data encryption.                                                                  | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-24 | Enable OS vulnerabilities recommendations.                                                           | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-25 | Configure firewall rules of existing firewalls if necessary.                                         | Firewall can be enabled and configured on he KeyVault, but at deployment we will follow the public by default security principles and open the firewall to all traffic.                                                                                                                                                                     |  NA                                                           |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:green">**IMPLEMENTED**</span>
| CN-SR-26 | Enable command-line audit logging.                                                                   | Not applicable.                                                                                                                                                                                                                                   |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>  
| CN-SR-27 | Enable conditional access control.                                                                   | Not applicable (only Service principal has access to AKV).                                                                                                                                                                                        |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>  
| CN-SR-28 | Specify service tags to define network access controls on network security groups or Azure Firewall. | We have tags defined in the ARM template.                                                                                                                                                                                                                                   |  Embeded in the ARM template                                                                                            |    NA                 | <span style="color:green">**FINAL**</span>  | <span style="color:green">**IMPLEMENTED**</span>
| CN-SR-29 | Use Corporate Active Directory Credentials.                                                          | Azure AD is the authentication mechanism, if AAD is synchronized with Corporate Active Directory then this requirement is compliant.                                                                                                              |  NA                                                                                            |  NA                     | <span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>

## 6. Implemented Policies

This section describes the policies which will be implemented for KeyVault.
These policies will be assigned when deploying a KeyVault or when deploying a Subcription/Management Group, this separation will be discussed below.

| Policy | Description | Implementation Scope
|--|--|--|
|Enforce SKUs policy|This policy restrict the SKUs you can specify when deploying KeyVaults|Subscription (where the KeyVault is deployed)|
|Enforce RBAC parameter|Disable RBAC authorization on Data Plane to manage Keys, Secrets and Certificates (Temporary deny policy)|Subscription (where the KeyVault is deployed)|
|Enforce Purge protection|This policy restricts the KeyVaults to only be deployed if the have the purge feature enabled|Subscription (where the KeyVault is deployed)|
|Audit Private Endpoint|This policy audits the usage of private endpoint for KeyVaults|Subscription (where the KeyVault is deployed)|
|Deploy Diagnostic settings if those are not correct or don't exist| This policy checks whether the KeyVault has Diagnostic settings enabled and whether the correct EventHub and Log analytics workspace Ids are used|Deployed on each Subscription or Management group with the relevant Ids|
