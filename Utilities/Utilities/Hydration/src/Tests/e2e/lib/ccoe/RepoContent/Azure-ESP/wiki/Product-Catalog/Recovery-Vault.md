# Azure Recovery Services Vault 1.0

| **Status**    | <span style="color:orange">**Final Version**</span> |
|-----------|---------------|
| **Version**   | v1.0         |
| **Edited By** | Peter Theuns |
| **Date**      | 20/01/2021     |
| **Approvers** | Frederik De Ryck<br>Jonas De Troy              |
| **Deployment documentation** |  |
| **To Do**     |   |

[[_TOC_]]

## 1. Introduction

### 1.1. Service Description
A Recovery Services vault is a storage entity in Azure that houses data. The data is typically copies of data, or configuration information for virtual machines (VMs), workloads, servers, or workstations. You can use CCoE Recovery Services vaults to hold backup data for IaaS VMs (Linux or Windows). Recovery Services vaults make it easy to organize your backup data, while minimizing management overhead. 
 
 
 
In this version of the Certified Service, the Azure Recovery Services Vault **will provide** the following features:
 
+ [RBAC access control](https://docs.microsoft.com/en-us/azure/backup/backup-rbac-rs-vault) will be configured to manage Azure Backups.
+ **Soft Delete**: With soft delete, even if a malicious actor deletes a backup (or backup data is accidentally deleted), the backup data is retained for 14 additional days, allowing the recovery of that backup item with no data loss. The additional 14 days of retention for backup data in the "soft delete" state don't incur any cost to you.
+ **Encryption of backup data**: By default, all your data is encrypted using platform-managed keys. You don't need to take any explicit action from your end to enable this encryption. It applies to all workloads being backed up to your Recovery Services vault.
+ Storage Replication type by default is set to Geo-redundant (**GRS**). Once you configure the backup, the option to modify is disabled.
 
The following features of the Azure Recovery Services Vault **will not be supported** in the current version:
+ **Cross Region Restore**: Cross Region Restore (CRR) allows you to restore Azure VMs in a secondary region, which is an Azure paired region. If Azure declares a disaster in the primary region, the data replicated in the secondary region is available to restore in the secondary region to mitigate real downtime disaster in the primary region for their environment.
 
To know more about Azure Recovery Services Vault service, please review [Recovery Services vaults overview](https://docs.microsoft.com/en-us/azure/backup/backup-azure-recovery-services-vault-overview).
 
 
## 2.      Architecture
 
 
### 2.1. High Level Design
 
 
**Azure Recovery Services vault will be used to store VM Backups**. To know more about how backups will be handled within CCoE VM.
 
To use Recovery Services Vault within a CCoE VM product, the location of the VM and the Recovery Services Vault must be the same.
 
 
### 2.2. Consumption endpoints (Data plane)
> No consumption endpoints are exposed for this version of the service.
 
 
#### 2.2.1. Endpoint Access
> No endpoint access are exposed for this version of the service.
 
 
 
#### 2.2.2. Endpoint Authorization and Authentication
 
**RBAC:** It will be provided two built-in roles when creating a Recovery Service Vault:
 
- "**Backup Contributor**": A list of Service Principals object Ids must be provided as input to give them the role definition "**Backup Contributor**" to be able to create and manage backup except deleting Recovery Services vault and giving access to others. Imagine this role as admin of backup management who can do every backup management operation.
 
- "**Backup Operator**": A list of Service Principals object Ids can be provided as input to give them the role definition "**Backup Operator**" to be able to manage backup services, except removal of backup, vault creation and giving access to others. 
 
Please check [Mapping backup built-in roles to backup management actions](https://docs.microsoft.com/en-us/azure/backup/backup-rbac-rs-vault#mapping-backup-built-in-roles-to-backup-management-actions) to understand better which roles require each management operations when backing up VM, restoring, etc.
 
### 2.3. Service Limits
 
Following are the service limits, per subscriptions and product:
+ [Resource limits](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits)
+ [Azure Recovery Service Vault limits](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#site-recovery-limits) 
+ [Backup support mattrix](https://docs.microsoft.com/en-us/azure/backup/backup-support-matrix#vault-support)
 
 
### 2.4. Monitoring
 
Azure Backup sends diagnostics events that can be collected and used for the purposes of analysis, alerting, and reporting. This is done by default in the CCoE certified Product.
 
In our scenario these logs will be stored in a central Log Analytics where all events from all environments will be logged. This central Log Analytics workspace will be set by default, nevertheless it can be provided a different Log Analytics worskpace as an input parameter.
 
Azure Backup provides the following diagnostics events. Each event provides detailed data on a specific set of backup-related artifacts:
 
- _CoreAzureBackup_: This table provides information about core backup entities, such as vaults and backup items.
- _AddonAzureBackupAlerts_: This table provides details about alert related fields.
- _AddonAzureBackupProtectedInstance_: This table provides basic protected instances-related fields.
- _AddonAzureBackupJobs_: This table provides details about job-related fields.
- _AddonAzureBackupPolicy_: This table provides details about policy-related fields.
- _AddonAzureBackupStorage_: This table provides details about storage-related fields.
 
After data flows into the Log Analytics workspace, dedicated tables for each of these events are created in your workspace. You can query any of these tables directly. You can also perform joins or unions between these tables if necessary.

 
To know more about the data model of these tables please review [Data Model for Azure Backup Diagnostics Events
](https://docs.microsoft.com/en-us/azure/backup/backup-azure-reports-data-model).
 
 
Azure Backup provides built-in monitoring and alerting capabilities in a Recovery Services vault. These capabilities are available without any additional management infrastructure.
 
In Azure Monitor, you can create your own **alerts** in a Log Analytics workspace. To check how to do show, please refer to [Monitor at scale by using Azure Monitor](https://docs.microsoft.com/en-us/azure/backup/backup-azure-monitoring-use-azuremonitor#create-alerts-by-using-log-analytics).
 
 
### 2.5. Backup & Restore
 
The Azure Recovery Service Vault CCoE certified product has soft delete enabled as a mandatory feature for Production and Test workloads. For environments Lab and Dev it allows enabling or disabling soft delete (for testing purposes, for example).
 
 
 
####Soft Delete
With soft delete, even if a malicious actor deletes a backup (or backup data is accidentally deleted), the backup data is retained for 14 additional days, allowing the recovery of that backup item with no data loss. The additional 14 days of retention for backup data in the "soft delete" state don't incur any cost.
 
To know the steps to restore a VM backup, you can follow the steps in [Soft delete for VMs using Azure portal](https://docs.microsoft.com/en-us/azure/backup/soft-delete-virtual-machines#soft-delete-for-vms-using-azure-portal). or through Powershell in [Soft delete for VMs using Azure PowerShell
](https://docs.microsoft.com/en-us/azure/backup/soft-delete-virtual-machines#soft-delete-for-vms-using-azure-powershell).
 
 

### 2.6 Disaster Recovery
 
Azure Backup automatically handles storage for the vault. Storage Replication type by default is set to Geo-redundant (GRS).
 
Geo-redundant storage (GRS) copies your data synchronously three times within a single physical location in the primary region using LRS. It then copies your data asynchronously to a single physical location in a secondary region that is hundreds of miles away from the primary region. 
A write operation is first committed to the primary location and replicated using LRS. The update is then replicated asynchronously to the secondary region. When data is written to the secondary location, it's also replicated within that location using LRS.
 
Although Azure Recovery Service Vault CCoE certified product storage replication is set to Geo-redundant by default, this option can as well be changed from Azure Portal. Changing Storage Replication type (Locally redundant/ Geo-redundant) for a Recovery Services vault has to be done **before** configuring backups in the vault. Once you configure backup, the option to modify is disabled. You can do so under "Properties" menu in the lateral blade option. You can as well follow the following [article](https://docs.microsoft.com/en-us/azure/backup/backup-create-rs-vault#set-storage-redundancy).
 

## 3.      Service Provisioning
 
 
### 3.1. Deployment parameters

|                                     | **Prod**                                    | **Non**-Prod                                | **Implementation** | Implementation Status           |
|-------------------------------------|-----------------------------------------|-----------------------------------------|----------------|---------------------------------|
|  **Subscription**                   | N/A | N/A                                     | <span style="color:green">**PARAMETER**</span>| <span style="color:grey">**N/A**</span>                            |
|  **Resource group**                 | N/A                                     | N/A                                     | <span style="color:green">**PARAMETER**</span>| <span style="color:grey">**N/A**</span>                       |
|  **Name**                           |  <name>                                 |  <name>                                 | <span style="color:green">**PARAMETER**</span>| <span style="color:green">**IMPLEMENTED**</span>|
|  **Region**                         | West EU (fixed) <br> Enforced by Policy | West EU (fixed) <br> Enforced by Policy | <span style="color:green">**DEFAULT**</span>| <span style="color:green">**IMPLEMENTED<br>Policy on root**</span>|
|  **SKU**                    |  Standard_LRS/Standard_GRS/Standard_ZRS/Premium_LRS                       |  Standard_LRS/Standard_GRS/Standard_ZRS//Premium_LRS | <span style="color:green">**PARAMETER**</span>| <span style="color:green">**IMPLEMENTED**</span>|
| **Soft Delete Method** | true | true |<span style="color:green">**PARAMETER**</span>| <span style="color:green">**IMPLEMENTED**</span>|
 

 
## 4. MSM Controls for Azure Recovery Services Vault 
 

All product-specific MSMCF controls - for the current product version - can be found on the table below: 
 
 
| **Title**                                                                                                                                                                                                          | **Functional Control   Description**                                                                         | **Category**               | **Product Assessment Q&A**                                                                                                                                                                             | **Implementation**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | **Status**                                                 |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------              |------------------------------------------------------------------------------------------------   |--------------       |------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------              |------------------------------------------------     |
| **M-STD02**  | Health alerts are automatically generated, correlated and   managed based on event monitoring     | Standard          | Monitoring Resource Health alerts covered on subscription level.       <br> - Additional   default monitoring enabled on product level?                                                                |   - Monitoring of Azure Recovery   Service Vault - only over Resource Health alerting.      <br>- Additional product Monitoring to be designed and implemented by   the DevOps teams      <br>- Azure Backup sends diagnostics events that can be collected and   used for the purposes of analysis, alerting, and reporting. This is done by   default in the CCoE certified Product. After data flows into the Log   Analytics workspace, dedicated tables for each of these events are created in   your workspace. You can query any of these tables directly.       <br>- Azure Backup provides built-in monitoring and alerting   capabilities - without any additional management infrastructure - in a   Recovery Services vault.            <br><br>- Monitoring documentation PBI: include guidance about   how to set up backup failures alerts                                                                                                                                                      | <span style="color:blue">**FINAL**</span>        |
|
| **M-STD05**   | Disaster Recovery (DR) scenario’s are applied and tested   periodically                                     | Standard          | Considerations for DR and higher availability:      <br>- Cross Region Restore Optional? >> not supported in the   current version                                                                     |  SUPPORTED in the current   version:      <br> - Storage Replication type by default is set to Geo-redundant   (GRS): copies your data synchronously three times within a single physical   location in the primary region using LRS and then copies your data   asynchronously to a single physical location in a secondary region that is   hundreds of miles away from the primary region.       <br>- Once you configure the backup, the option to modify is   disabled.            <br><br>- DR documentation PBI: include guidance about Disaster   Recovery                                                                                                                                                                                                                                                                                                                                                                                                                                                | <span style="color:blue">**FINAL**</span>        |
| **M-STD06**       | RTO / RPO requirements are achieved for backup and restore                                                   | Standard          | Backup:      <br>- Soft Delete optional? >> YES      <br>- Documentation of Backup & Restore capabilities                                                                                              |  SUPPORTED in the current   version:      <br>- _Soft delete_ active for Azure Recovery Services Vault storage:   the backup data is retained for 14 additional days, allowing the recovery of   that backup item with no data loss (_soft delete_ enabled as a mandatory   feature for Prod and Test workloads, optional for Lab and Dev)      <br>- Backups for VMs certified products, even in the case of having   CRR inactive, are created on Recovery Service Vault and replicated to a   different region (for all stages, by default)         <br>- No additional backup (of the backup´s itself) will be   performed            <br><br> The following features of the Azure Recovery Services   Vault will NOT be SUPPORTED in the current version:      <br>-  Cross Region Restore   (CRR) to restore Azure VMs in a secondary region, which is an Azure paired   region.            <br><br>- Backup documentation PBI: include guidance about   Backup and Restore for the product                  | <span style="color:blue">**FINAL**</span>        |
 
## 5. Security Controls 

All product-specific security controls - for the current product version - can be found on the table below:

| **Index** | **Security Requirements** | **Relevance** | **Implementation details**  | **Policy Enforced / Audit** | **Design Status** | **Implemented Status** |
|--|--|--|--|--|--|--|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later).  | N/A| N/A | N/A |<span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-02 | Secret and Key management needs to be done by a dedicated database/vault. | N/A |  Microsoft managed key encryption is enabled by design.  |N/A  |<span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-03 | Encrypt information at rest (Disc encryption).  | Encryption for Recovery Vault by Default.  |N/A | N/A | <span style="color:green">**FINAL**</span>  | <span style="color:green">**IMPLEMENTED BY DEFAULT**</span> |
| CN-SR-04 | Maintain an inventory of sensitive Information.  | Needs to be defined at resource creation phase. Procedural. | N/A  | N/A | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-05 | Use an active discovery tool to identify sensitive data.  | N/A |  N/A |N/A  | <span style="color:green">**FINAL**</span> |<span style="color:grey">**N/A**</span>
| CN-SR-06 | Protect the database from permanently deleting data by enabling soft delete functionality.  | Soft delete for recovery vault needs to be enabled. | Azure Custom Policy and fixed ARM parameter.  |Audit| <span style="color:green">**FINAL**</span> |
| CN-SR-07 | Ensure regular automated back ups. | N/A |N/A  |N/A | <span style="color:green">**FINAL**</span>|<span style="color:grey">**N/A**</span>
| CN-SR-08 | Enforce the use of Azure Active Directory.  |  N/A |N/A  |N/A | <span style="color:green">**FINAL**</span>|<span style="color:grey">**N/A**</span>
| CN-SR-09 | Follow the principle of least privilege.  |  N/A |N/A  |N/A | <span style="color:green">**FINAL**</span>|<span style="color:grey">**N/A**</span>
| CN-SR-10 | Configure security log storage retention.  | Log Analytics retention is configured on the LAW product itself. More information: https://docs.microsoft.com/en-us/azure/key-vault/general/logging?tabs=Vault  |Implemented on the LAW  |  N/A |<span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-11 | Enable alerts for anomalous activity.  |  N/A| N/A | N/A |<span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
| CN-SR-12 | Configure central security log management. | N/A| N/A | N/A |<span style="color:green">**FINAL**</span>  |<span style="color:grey">**N/A**</span>
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
