# Azure Storage Account 1.0 (Generals )

| **Status** | <span style="color:orange">**DRAFT**</span> |
|--|--|
| **Version** | v0.1 |
| **Edited By** | samuel-peeters |
| **Date** | 20/01/2021  |
| **Approvers** |  |
| **Deployment documentation** | https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?version=GBusers%2Fjonathan%2Fbdpplatform-storageaccount-templates&path=%2Fmodules%2Fstorageaccount%2Fdeploy.json> |
| **To Do** | Verify functionality: tagging |

[[_TOC_]]

## 1. Introduction
An Azure storage account contains all of your Azure Storage data objects: blobs, files, queues, tables, and disks. The storage account provides a unique namespace 
for your Azure Storage data that is accessible from anywhere in the world over HTTP or HTTPS. Data in your Azure storage account is durable and highly available,
 secure, and massively scalable.

### 1.1. Service Description
Azure Storage offers several types of storage accounts. We will limmit its usage here to General-purpose v2 accounts: Basic storage account type for blobs, files, 
queues, and tables. 

## 2. Architecture

### 2.1. High Level Design
Storage can be managed on two levels: Management Plane and Data Plane.
The Management Plane is about operations which can affect storage account itself: You can control access to the operations used to manage that storage account, 
but not to the data objects in the account. For example, you can grant permission to retrieve the properties of the storage account (such as redundancy), but not to a 
container or data within a container inside Blob Storage.
The data plane security is related to securing the data objects in the storage.

### 2.2. Data plane 
You can secure the data objects in storage by allowing access to only limited machines instead of exposing service to whole internet. You can also enable data plane security by providing only required accesses to the data.

For example, some accounts may just want to read the data and some account may want to update the data.

#### 2.2.1. Endpoint Access
We will depend on Azure AD authentication.

#### 2.2.2. Endpoint Authorization and Authentication
Storage accounts have a public endpoint that is accessible through the internet. You can also create Private Endpoints for your storage account, which assigns a private 
IP address from your VNet to the storage account, and secures all traffic between your VNet and the storage account over a private link. The Azure storage firewall provides
access control for the public endpoint of your storage account. 
You can also use the firewall to block all access through the public endpoint when using private endpoints. Your storage firewall configuration also enables select trusted
 Azure platform services to access the storage account securely.

An application that accesses a storage account when network rules are in effect still requires proper authorization for the request. Here, authorization is supported with
 Azure Active Directory (Azure AD) credentials.
### 2.3. Management Plane 

It is the creator of the storageAccount who gains author role. By Default the Service Principle has this right and the LS Service Principal has the right assigned.

### 2.4. Service Limits

Microsoft.STorage:  storageAccount has no limits in Resource Groups.
Note: this is not about the storage limits of the data stored using it.
 Reference: https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resources-without-resource-group-limit 
## 3. Service Provisioning

### 3.1. Prerequisites
 
The storageAccount will be created with valid subscription and depending on service principal.
 The storageAccountName should be at least 3 characters in lenght and may not exceed 24 characters. Only lower case letters and digits are allowed.
 StorageAccountNames should be unique.

The certified product storageAccount provides in:
o	a DataLake storage based on ADLS Gen2 blob storage with Hierarchical Namespace enabled for fine grained access control 
o	a classical storage account allowing file and blob storage

### 3.2. Deployment parameters

All Parameters indicated with Fixed will not be included as an option during deployment and will be set as default parameter:

|                                     | **Prod**                                    | **Non**-Prod                                | **Implementation** | Implementation Status           |
|-------------------------------------|-----------------------------------------|-----------------------------------------|----------------|---------------------------------|
|  **Subscription**                   | N/A | N/A                                     | <span style="color:green">**PARAMETER**</span>| <span style="color:grey">**N/A**</span>                            |
|  **Resource group**                 | N/A                                     | N/A                                     | <span style="color:green">**PARAMETER**</span>| <span style="color:grey">**N/A**</span>                       |
|  **Name**                           |  <name>                                 |  <name>                                 | <span style="color:green">**PARAMETER**</span>| <span style="color:green">**IMPLEMENTED**</span>|
|  **Region**                         | West EU (fixed) <br> Enforced by Policy | West EU (fixed) <br> Enforced by Policy | <span style="color:green">**DEFAULT**</span>| <span style="color:green">**IMPLEMENTED<br>Policy on root**</span>|
|  **SKU**                    |  Standard_LRS/Standard_GRS/Standard_ZRS/Premium_LRS                       |  Standard_LRS/Standard_GRS/Standard_ZRS//Premium_LRS | <span style="color:green">**PARAMETER**</span>| <span style="color:green">**IMPLEMENTED**</span>|
|  **Account kind**                   |  Blobstorage/StorageV2                          |  Blobstorage/StorageV2                            | <span style="color:green">**PARAMETER**</span>| <span style="color:green">**IMPLEMENTED**</span>|
|  **Blob access tier**               | Hot (Fixed)                             | Hot (Fixed)                             | <span style="color:green">**DEFAULT**</span>| <span style="color:green">**IMPLEMENTED**</span>|
|  **Connectivity method**            |   Public (Fixed) <br> Built-In Policy: Storage Accounts should restrict network Access |Public (Fixed) <br> Built-In Policy: Storage Accounts should restrict network Access |      <span style="color:green">**DEFAULT**</span>| <span style="color:green">**IMPLEMENTED<br>Built-In Policy**</span>|
|  **Network routing**                |   Microsoft network routing (Fixed)                                      |       Microsoft network routing (Fixed)                                      |      <span style="color:green">**DEFAULT**</span>| <span style="color:green">**IMPLEMENTED**</span>|
|  **Turn on soft delete for blobs**  | True (Fixed)                            | True (Fixed)                            | <span style="color:green">**DEFAULT**</span>| <span style="color:green">**IMPLEMENTED<br>Custom Policy**</span>|
|  **Turn on versioning**             | yes (Fixed)                             | yes (Fixed)                             | <span style="color:green">**DEFAULT**</span>| <span style="color:green">**IMPLEMENTED<br>Custom Policy**</span>|
|  **Secure transfer required**       | yes (Fixed): <br> Built-In Policy: Secure Transfer to Storage account should be enabled                             | yes (Fixed): <br> Built-In Policy: Secure Transfer to Storage account should be enabled                             | <span style="color:green">**DEFAULT**</span>| <span style="color:green">**IMPLEMENTED<br>Built-In Policy**</span>|
|  **Allow Blob public access**       | False (Fixed)                                        |    False (Fixed)                                       |<span style="color:green">**DEFAULT**</span>| <span style="color:green">**IMPLEMENTED<br>Custom Policy**</span>|
|  **Minimum TLS version**            |  1.2  (Fixed)| 1.2 (Fixed) | <span style="color:green">**DEFAULT**</span>| <span style="color:green">**IMPLEMENTED<br>Built-In Policy**</span>|
|  **Container name**                 |  list of <names>                        |  list of <names>                        | <span style="color:green">**PARAMETER**</span>| <span style="color:green">**IMPLEMENTED**</span>|
|  **Public access Level**            |  Private                                |  Private                                |                |                                 |
|  **DataLake Hierarchy**            |  Enabled/Disabled|  Enabled/Disabled|<span style="color:green">**PARAMETER**</span>| <span style="color:green">**IMPLEMENTED**</span>|                               |
| **AllowSharedKeyAccess**    | False (Fixed) | False (Fixed) | <span style="color:green">**DEFAULT**</span>| <span style="color:green">**IMPLEMENTED<br>Custom Policy**</span>| 
Legend:
- Fixed: The parameter will be hardcoded in the ARM template
- Enforced by policy: There will be a policy created to manage the parameter changes after deployment
- Cannot be changed after deployment: The parameter will be unchangeable after deployment.

Variables
 - storage_account_name   might|shall  be concatenated using:
     'pxs',platform_id,app_id,environment,'st',suffix
- storage_account_id  might be obtained from:
   [resourceId('Microsoft.Storage/storageAccounts', variables('storage_account_name'))]

Output
 - storage_account_id: [variables('storage_account_id')]
 - storage_account_name: [variables('storage_account_name')]  

## 4. Service Management 


| **MSM Code** | **Functional Control Description** | **Product Assessment Q&A** | **Validated** | **Implementation** | **Status** |
|----------|----------------------------------------------------------------------------------------------------------------------------|------------------------|------------------------|------------------------|----|----|
| **M-STD01** | Health alerts are automatically generated, correlated and managed based on event monitoring.                            |   - Health alerts are automatically triggered by Azure. <br> - No product specific health alerting or dashboard/report requirements. <br> - Guidance for DevOps teams about monitoring best practices to be documented on the wiki product description. (e.g. B[asic Key Vault metrics to monitor](https://docs.microsoft.com/en-us/azure/key-vault/general/alert#basic-key-vault-metrics-to-monitor) )<br><br>       |      Yes     |   - This control is applied by defining Resource Health Alerts on a subscription level, therefore provided for all certified products/platforms. <br> <br> - Additional resource monitoring is under the responsibility of each workload DevOps team.  <br> <br>           |  <span style="color:green">**TO BE IMPLEMTED**</span>   |
|  **M-STD04**        |       Disaster Recovery (DR) scenario’s are applied and  tested periodically          | <br>- Geo-replication included as part of the PAAS service  <br>- Automatic Failover is not relevant <br> -Guidance for DevOps teams about DR best practices to be documented on the wiki product description.|  No  |      <br>  - Key Vault DR concept is part of Azure´s PaaS service, therefore no additional implementations needed: <br> - Key Vault are replicated within the region and to a secondary region and DR is implemented by default and triggered and rolled back automatically and transparently. <br> - No DR testing is needed (or possible) because the DR is managed by Microsoft Azure <br><br>      |    <span style="color:green">**FINAL**</span>   |
|  **M-PaaS01**       |        RTO / RPO requirements are achieved for PaaS backup and restore           |  <br> - ensure regular backups are performed (mandatory)  <br>- Backup Container Registry (Mandatory)  <br> - Guidance for DevOps teams about backup & restore best practices to be documented on the wiki product description.     |    No    |   - Key Vault backup:. <br>- No backup implemented on a product level. <br>- Secrets can be secured, in case of critical business need, manually via PowerShell scripts. Product team will provide only documentation. <br>- The customer is responsible for backup and restore of its Key Vault <br> Key Vault Soft Delete:<br>- Current setup: enabled for Production and Global. <br> Key Vault soft-delete will t[urn into an Azure default](https://docs.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview) <br>       |    <span style="color:green">**FINAL**</span>    |

## 5. Security Controls 

All product-specific security controls - for the current product version - can be found on the table below:

| **Index** | **Security Requirements** | **Relevance** | **Implementation details**  | **Policy Enforced / Audit** | **Design Status** | **Implemented Status** |
|--|--|--|--|--|--|--|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later).  | HTTPS/TLS needs to be enforced. | Azure Built-In Policy and fixed ARM parameter.  | Enforced |<span style="color:green">**FINAL**</span>  |
| CN-SR-02 | Secret and Key management needs to be done by a dedicated database/vault. | N/A |  Microsoft managed key encryption is enabled by design.  |N/A  |<span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-03 | Encrypt information at rest (Disc encryption).  | Encryption for Storage Account by Default.  |N/A | N/A | <span style="color:green">**FINAL**</span>  | <span style="color:green">**IMPLEMENTED BY DEFAULT**</span> |
| CN-SR-04 | Maintain an inventory of sensitive Information.  | Needs to be defined at resource creation phase. Procedural. | N/A  | N/A | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-05 | Use an active discovery tool to identify sensitive data.  | N/A |  N/A |N/A  | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-06 | Protect the database from permanently deleting data by enabling soft delete functionality.  | Soft delete for blob storage needs to be enabled. <br> Locking Storage account to prevent Storage account deletion should also be implemented.| Azure Custom Policy and fixed ARM parameter.  |Audit| <span style="color:green">**FINAL**</span> |
| CN-SR-07 | Ensure regular automated back ups. | [Storage Account versioning](https://docs.microsoft.com/en-us/azure/storage/blobs/versioning-overview) and [soft delete](https://docs.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview) for Azure blobs needs to be enabled and enforced. <BR> *Note: Azure Data Lake Storage v2 does not support Versioning or Soft delete functionality. * |Azure Custom Policy and fixed ARM parameter.   |Audit | <span style="color:green">**FINAL**</span>
| CN-SR-08 | Enforce the use of Azure Active Directory.  | Use of Azure AD (RBAC) should be encouraged instead of Shared keys for authorizations mentioned [here](https://docs.microsoft.com/en-us/azure/storage/common/storage-auth-aad). Shared keys could also be prevented as explained [here](https://docs.microsoft.com/en-us/azure/storage/common/shared-key-authorization-prevent?tabs=portal). | Azure Custom Policy and fixed ARM parameter.  |  Audit |<span style="color:green">**FINAL**</span>  |
| CN-SR-09 | Follow the principle of least privilege.  | Least prilege principle needs to be implemented, using authorization options with built-in groups defined [here](https://docs.microsoft.com/en-us/azure/storage/common/storage-auth-aad#azure-built-in-roles-for-blobs-and-queues)  | See CN-SR-08  | N/A  | <span style="color:green">**FINAL**</span>   |<span style="color:grey">**N/A**</span> 
| CN-SR-10 | Configure security log storage retention.  | Log Analytics retention is configured on the LAW product itself. More information: https://docs.microsoft.com/en-us/azure/key-vault/general/logging?tabs=Vault  |Implemented on the LAW  |  N/A |<span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-11 | Enable alerts for anomalous activity.  | Azure Defender for Storage in Azure Security Center needs to be enforced using [Azure Defender for Storage](https://docs.microsoft.com/en-us/azure/storage/common/azure-defender-storage-configure?tabs=azure-security-center). | Built-In Ploicy: Deploy Advanced Threat Protection on Storage Accounts |  Deploy | <span style="color:green">**FINAL**</span>  |
| CN-SR-12 | Configure central security log management. | Security logging needs to be implemented (enforced). Logging will be implemented using an Event Hub. More information: https://docs.microsoft.com/en-us/azure/storage/common/storage-analytics-logging?tabs=dotnet | ARM template to send logs and metrics to the Event Hub. Custom Policy (Audit/DeployIfNotExists)| Deploy  |<span style="color:green">**FINAL**</span>   | | 
| CN-SR-13 | Enable audit logging of Azure Resources.  |Enable (enforce) diagnostic logs on the service to the Central Log Analytics Workspace and Event Hub. https://docs.microsoft.com/en-us/azure/storage/common/storage-monitor-storage-account | Custom Policy (Audit/DeployIfNotExists) | Deploy |<span style="color:green">**FINAL**</span>
| CN-SR-14 | Enable MFA and conditional access with MFA.  | Not applicable. Inherited from Azure AD.	| N/A | N/A  | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-15 | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network.  | Not directly applicable. Needs to be implemented on NSG/Azure Firewall level. Access only for the LZ resources | N/A |  N/A | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-16 | Ensure that the endpoint protection for all Virtual Machines is installed. | Not applicable. (relevant to VMs) | N/A  | N/A |<span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-17 | Secure outbound communication to the internet.  | Not applicable. | N/A | N/A  |  <span style="color:green">**FINAL**</span>|<span style="color:grey">**N/A**</span>
| CN-SR-18 | Enable JIT network access.  |  Not applicable. (relevant to VMs) | N/A  | N/A | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-19 | Run automated vulnerability scanning tools.  | Not applicable. <BR> _Some of the threats are detected using Azure Defender for Storage, details [here](https://docs.microsoft.com/en-us/azure/security-center/alerts-reference#alerts-azurestorage)._ | N/A | N/A  | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-20 | Use automated tools to monitor network resource configurations and detect changes.  |  Not applicable. | N/A  | N/A |<span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-21 | Disable remote user access ports (RDP,SSH,Telnet,FTP).  |  Not applicable. | N/A  | N/A | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-22 | Enable automated Patching/ Upgrading.  |  Not applicable. | N/A  | N/A | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-23 | Enable transparent data encryption. |  Not applicable. | N/A  | N/A | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-24 | Enable OS vulnerabilities recommendations.  |  Not applicable. | N/A  | N/A | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-25 | Configure firewall rules of existing firewalls if necessary.  | Firewall needs to be configured as part of the product. | Built-in Policy. | Enforce | <span style="color:green">**FINAL**</span>  |
| CN-SR-26 | Enable command-line audit logging.  | Not applicable. | N/A| N/A  |<span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-27 | Enable conditional access control.  |Not applicable. Inherited from Azure AD. | N/A | N/A  |<span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-28 | Specify service tags to define network access controls on network security groups or Azure Firewall. |  Not applicable. | N/A  | N/A |<span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-29 | Use Corporate Active Directory Credentials.  |  Not applicable. | N/A  | N/A | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>