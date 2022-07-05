
[[_TOC_]]

 

| **Status**    | <span style="color:green">**FINAL**</span> |
|-----------|---------------|
| **Version**   | v0.1         |
| **Edited By** | <author> |
| **Date**      | 08/01/2021     |
| **Approvers** |               |
|      **Deployment documentation**      |     <Link to readme>   |
| **To Do**     |   |

 

 

# SQL Database
 

## 1. Introduction

### 1.1. Service Description

[Azure SQL Database](https://docs.microsoft.com/en-us/azure/azure-sql/database/sql-database-paas-overview) is a fully managed platform as a service (PaaS) database engine that handles most of the database management functions without user involvement:

- upgrading 
- host system patching 
- backups

Azure SQL Database is always running on the latest stable version of the SQL Server database engine and patched OS with 99.99% availability.

SQL Database allows an easily up- or downscaling of performance within two different purchasing models: a vCore-based purchasing model and a DTU-based purchasing model. 

## 2. Architecture
The following picture is showing a simplified level architecture of this service:

***Prod*** _(Public network access on Azure SQL Database should be restricted by Firewall rules)_
![contoso_sql_level_architecture_allow_azure.png](/.attachments/contoso_sql_level_architecture_allow_azure-350ff6f0-1ec1-4b39-ba57-a94a66de80ab.png)

***Prod*** _(Data Scientists)_

![contoso_sql_level_architecture_pub_end.png](/.attachments/contoso_sql_level_architecture_pub_end-1d21631c-26a4-47ad-8fc4-fab11df3d305.png)

***Non-Prod***

![contoso_sql_level_architecture_non-prod.png](/.attachments/contoso_sql_level_architecture_non-prod-4d6b7aef-14b8-4f72-af3f-e16967523b00.png)

### 2.1 Service Layered Defense-in-depth
In this version of Azure SQL Database as a Certified Service considered the basics of securing the data tier. The security strategy follows the layered defense-in-depth approach and moves from the outside in:
![defense-in-depth.png](/.attachments/defense-in-depth-65c13ff0-fe28-4210-97b1-40dc9a28ac41.png)

#### 2.1.1 Network security
**IP firewall** rules grant access to databases based on the originating IP address of each request. Network connectivity over the Azure backbone and selected known networks that are needed by the application are allowed.

| Public Endpoint |
|--|
|<sqlservername>.database.windows.net:1433 |

#### 2.1.2 Access management
Azure portal user account's role assignments for managing databases and servers within Azure is controlled by IAM. IAM permissions aren't reflecting the access rights given at the application database level. 

- **Owner**: Only an Azure AD Service Principal for deployment purposes will be added to this role. An exception is the Sandbox environment, to balance between progress of development and security. 

- "**Log Analytics Reader**": Log Analytics Reader can view and search all monitoring data as well as view monitoring settings, including viewing the configuration of Azure diagnostics on all Azure resources.
 
**Azure SQL Database** is using an independent service specific Role and Access management that support two types of authentication to prove the user and application Service Principals:

**SQL authentication** refers to the authentication of a user when connecting to Azure SQL Database using username and password. A server admin login with a username and password must be specified when the server is being created. The server admin should be the only user with this authentication method. 

**Azure Active Directory** authentication is to use as the default mechanism of connecting to Azure SQL Database by using identities in Azure Active Directory (Azure AD). Azure AD authentication allows administrators to centrally manage the identities and permissions of database users and groups along with other Azure services in one central location. Benefits include:

- No proliferation of user identities across servers
- Password rotation in a single place
- Management of database permissions using external Azure AD groups
- Supports contained database users to authenticate identities at the database level

[Configure and manage Azure AD authentication with Azure SQL](https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-configure?tabs=azure-powershell#powershell-for-sql-database-and-azure-synapse)

Automating the creation of AAD backed SQL users (i.e. external users/groups) [requires](https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-service-principal-tutorial) the MSI of SQL Server to have `Directory Reader` role over AAD. In order to automate the assignment of `Directory Reader` permissions to SQL Server MSIs, there are three options available:
- Create an AAD Group with `Directory Reader` permission, and grant group ownership to Landing Zones. This solution will effectively allow Landing Zones to add the SQL Server MSIs to this group as the SQL Servers get created, while requiring little development and ensuring the minimum set of permissions over AAD is granted to Landing Zones. The only risk associated with this solution is the fact that AAD permissions over AD Group is a feature in Public Preview. Therefore there is a small chance this feature will not get to be Generally Available. This solution is the preferred one in terms of security and implementation effort.
- Create an Azure Function at organization level, that Landing Zones could call in order to request that the `Directory Reader` permission is granted to SQL Server MSIs. The code of the function could use a set of checks to make sure that the function is not misused. This solution is thus flexible and avoids granted elevated permissions to Landing Zones, however it will require the most effort in terms of development and maintenance.
- Granting Landing Zones' service principals one of the following permissions: `Global Administrator` or `Privileged Roles Administrator`. This will effectively allow the service connections used by the Landing Zones, to grant the necessary permissions to SQL Server MSIs. However, this solution is the least preferred one, due to high security risks associated with granting elevated permissions over AAD to Landing Zones.


#### 2.1.3 SQL auditing
SQL Database auditing tracks database activities and helps maintain compliance with security standards by recording database events to an audit log in a customer-owned Azure Storage Account or Log Analytics. Auditing allows to monitor ongoing database activities, as well as analyze and investigate historical activity to identify potential threats or suspected abuse and security violations. If Auditing is enabled on the server, it always apply to the database, regardless of the database settings.

#### 2.1.4 Advanced Threat Protection
SQL Database is providing threat detection capabilities to protect customer data. The feature detects anomalous activities indicating unusual and potentially harmful attempts to access or exploit databases. Advanced Threat Protection can identify Potential SQL injection, Access from unusual location or data center, Access from unfamiliar principal or potentially harmful application, and Brute force SQL credentials attacks. Alerts are viewed from the Azure Security Center, where the details of the suspicious activities are provided and recommendations for further investigation given along with actions to mitigate the threat.

[Use PowerShell to configure SQL Database auditing and Advanced Threat Protection](https://docs.microsoft.com/en-us/azure/azure-sql/database/scripts/auditing-threat-detection-powershell-configure#:~:text=%20Use%20PowerShell%20to%20configure%20SQL%20Database%20auditing,Script%20explanation.%20This%20script%20uses%20the...%20More)

#### 2.1.5 Transport Layer Security (Encryption-in-transit)
SQL Database and Azure Synapse Analytics secure customer data by encrypting data in motion with [Transport Layer Security (TLS)](https://docs.microsoft.com/en-us/azure/azure-sql/database/security-overview#transport-layer-security-encryption-in-transit).
_This ensures all data is encrypted "in transit" between the client and server irrespective of the setting of Encrypt or TrustServerCertificate in the connection string_.

**Note**: [Enforce a minimal TLS version at the server level that applies to Azure SQL Databases hosted on the server using the TLS version setting](https://docs.microsoft.com/en-us/azure/azure-sql/database/connectivity-settings#minimal-tls-version). It is recommend setting the minimal TLS version to 1.2.

#### 2.1.6 Transparent Data Encryption (Encryption-at-rest)
[Transparent data encryption (TDE)](https://docs.microsoft.com/en-us/azure/azure-sql/database/transparent-data-encryption-tde-overview?tabs=azure-portal) for SQL Database and Azure Synapse Analytics adds a layer of security to help protect data at rest from unauthorized or offline access to raw files or backups. 
In Azure, all newly created databases are encrypted by default and the database encryption key is protected by a built-in server certificate. Certificate maintenance and rotation are managed by the service and require no input from the user. 

### 2.3. Service Limits
Following are the limits per subscriptions and per product:

- [Azure limits per subscription](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits)

- [Azure SQL Database resource limits](https://docs.microsoft.com/en-us/azure/azure-sql/database/resource-limits-logical-server)

## 3.     Service Provisioning

### 3.1. Prerequisites
The following Azure resources need to be in place before this Certified Service can be provisioned:
- Subscription
- Resource Group
- Central Log Analytics Workspace (CN-SR-10: Auditing/Threat Protection, Monitoring)
- Storage Account (CN-SR-10: Auditing/Thread Protection)
### 3.2 Deployment parameters
#### 3.2.1 Azure SQL servers 

|  |  Prod	| Non-Prod | Implementation |
|--|--|--|--|
| **Azure Region** | resource group location | resource group location | Parameter |
| **SQL Server Name** | mandatory | mandatory  | Parameter |
| **SQL admin_user** | mandatory | mandatory | Parameter |
| **SQL admin_password** | mandatory | mandatory | Parameter |
| **ad_admin_login** | mandatory AD group | mandatory AD group | Parameter |
| **ad_admin_sid** | AAD sid | AAD sid| Parameter |
| **enable_identity** | enable | enable| Parameter |
| **Firewall Azure services** | allow | allow | Parameter |
| **Firewall public network access** | restricted | restricted | Parameter |
| [**Minimal TLS version**](https://docs.microsoft.com/en-us/azure/azure-sql/database/connectivity-settings#set-the-minimal-tls-version-via-powershell) | 1.2 | 1.2| Default |
| **Connectivity method** | Public endpoint| Public endpoint | Parameter |
| **Auditing** | Storage/Log Analytics (Preview)/Event Hub(Preview) | Storage/Log Analytics (Preview)/Event Hub (Preview) | Parameter |
| **Advanced Thread Protection Storage** | Storage | Storage | Parameter |
| **Advanced Thread Protection Notification** | email  | N/A | Parameter |
<br>

#### 3.2.2 Azure SQL Database 

|  |  Prod	| Non-Prod | Implementation |
|--|--|--|--|
| **Azure Region** | resource group location | resource group location | Parameter |
| **SKU** | GP_Gen5 | GP_Gen5 | Default |
| **SQL Server Name** | mandatory  | mandatory | Parameter |
| **SQL Database Name** | mandatory | mandatory | Parameter |
| **Firewall Azure services** | allow | allow | Inherit |
| **Firewall public network access** | restricted | restricted | Inherit |
| **Minimal TLS version** | 1.2 | 1.2| Inherit |
| **Connectivity method** | Public endpoint| Public endpoint | Inherit |
| **Auditing** | Storage/Log Analytics | Storage/Log Analytics (Preview)| Inherit |
| **Advanced Thread Protection Storage** | Storage | Storage | Inherit |
| **Advanced Thread Protection Notification** | email  | N/A | Inherit |
| **Backup Retention** | 30| 30 | Parameter |
| **Backup Protection** | Enable| Enable| Parameter |
<br>
## 4. Service Management

All product-specific MSMCF controls - for the current product version - can be found on the table below:

 

| **MSM Code** | **Functional Control Description** | **Category** | **Product Assessment Q&A** | **Validated** | **Implementation** | **Status** |
|----------|----------------------------------------------------------------------------------------------------------------------------|------------------------|------------------------|------------------------|----|----|
| **M-STD02** | Health alerts are automatically generated, correlated and managed based on event monitoring.                            |     Standard   |   - Health alerts are automatically triggered by Azure. <br> - No product specific health alerting or dashboard/report requirements. <br> - No product specific health alerting or dashboard/report requirements. <br> - Guidance for DevOps teams about monitoring best practices to be documented on the wiki product description. (e.g. [SQL Database metrics to monitor](https://docs.microsoft.com/en-us/azure/azure-sql/database/monitor-tune-overview#azure-sql-database-and-azure-sql-managed-instance-resource-monitoring)  and [Synapse Analytics](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-workload-management-portal-monitor))<br><br>       |      Yes     |   - This control is applied by defining Resource Health Alerts on a subscription level, therefore provided for all certified products/platforms. <br> <br> - Additional resource monitoring is under the responsibility of each workload DevOps team.  <br> <br>           |  <span style="color:green">**FINAL**</span>   |
|  **M-STD05**        |       Disaster Recovery (DR) scenario’s are applied and  tested periodically          |    Standard    |  <br>- Geo-replication included as part of the PAAS service  <br>- Automatic Failover is not relevant <br> -Guidance for DevOps teams about DR best practices to be documented on the wiki product description.|  No  |      <br>  - SQL Database and Synapse Analytics DR concept is part of Azure´s PaaS service, therefore no additional implementations needed: <br> - SQL Database and Synapse Analytics are replicated within the region and to a secondary region and DR is implemented by default and triggered and rolled back automatically and transparently. <br> - No DR testing is needed (or possible) because the DR is managed by Microsoft Azure <br><br>      |    <span style="color:green">**FINAL**</span>   |
|  **M-PaaS01**       |        RTO / RPO requirements are achieved for PaaS backup and restore           |    Standard    |   <br> - ensure regular backups are performed (mandatory)  <br>- Backup Container Registry (Mandatory)  <br> - Guidance for DevOps teams about backup & restore best practices to be documented on the wiki product description.     |    No    |   The default backup period for DTU-based and vCore-based Azure SQL databases is set to 7 days. [To set a different retention period using Azure Portal, PowerShell or REST API.](https://docs.microsoft.com/en-us/azure/azure-sql/database/automated-backups-overview?tabs=single-database#how-to-change-the-pitr-backup-retention-period) <br> Synapse Analytics automatically creates data warehouse snapshot as [restore point to recover or copy the data warehouse to a previous state](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/backup-and-restore). Since dedicated SQL pool is a distributed system, a data warehouse snapshot consists of many files that are located in Azure storage. Snapshots capture incremental changes from the data stored in your data warehouse. Dedicated SQL pool deletes a restore point when it hits the 7-day retention period and when there are at least 42 total restore points (including both user-defined and automatic).     |    <span style="color:green">**FINAL**</span>    |

## 5. Security Controls for SQL Database

Microsoft Azure SQL Database best practices: 
All product-specific security controls - for the current product version - can be found on the table below:

| Index    | Security Requirement                                                                                 | Relevance                                                                                                                                                                                                                                         | Implementation details                                                                         | Policy Enforced / Audit | Status                                      |
|----------|------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|-------------------------|---------------------------------------------|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later). | [The enforcement of TLS 1.2 must configured at the Azure SQL server level](https://docs.microsoft.com/en-us/azure/azure-sql/database/connectivity-settings#minimal-tls-version), it's not possible to revert to the default (all versions). Azure SQL Database then doesn’t support unencrypted connections. This will ensure data transmission is secure and can help prevent man-in-the-middle Jump attacks. | NA | PowerShell/ARM | <span style="color:green">**FINAL**</span>  |
| CN-SR-02 | Secret and Key management needs to be done by a dedicated database/vault. | Azure AD is the authentication mechanism. | NA | NA | <span style="color:green">**FINAL**</span>  |
| CN-SR-03 | Encrypt information at rest (Disc encryption) | All newly created databases in SQL Database are encrypted by default by using service-managed transparent data encryption. Existing SQL databases created before May 2017 and SQL databases created through restore, geo-replication, and database copy are not encrypted by default. | PowerShell/ARM | Built-in: Deploy SQL DB transparent data encryption | <span style="color:green">**FINAL**</span>  |
| CN-SR-04 | Maintain an inventory of sensitive Information. | Usually the data owner is responsible to maintain a data catalog. This is not in the domain of the platform. | NA |  NA | <span style="color:green">**FINAL**</span>  |
| CN-SR-05 | Use an active discovery tool to identify sensitive data. | [Data Discovery & Classification is built into Azure SQL Database](https://docs.microsoft.com/en-us/azure/azure-sql/database/data-discovery-and-classification-overview) that support developers with a built-in set of sensitivity labels and a built-in set of information types and discovery logic. | PowerShell/ARM |  [Customize the SQL information protection policy in Azure Security Center (Preview)](https://docs.microsoft.com/en-us/azure/azure-sql/database/threat-detection-overview) | <span style="color:green">**FINAL**</span>  |
| CN-SR-06 | Protect the database from permanently deleting data by enabling soft delete functionality.           | NA |  PowerShell/ARM  | Built-in: Long-term geo-redundant backup should be enabled for Azure SQL Databases | <span style="color:green">**FINAL**</span>  |
| CN-SR-07 | Ensure regular automated back ups | The default backup period for DTU-based and vCore-based Azure SQL databases is set to 7 days. [To set a different retention period using Azure Portal, PowerShell or REST API.](https://docs.microsoft.com/en-us/azure/azure-sql/database/automated-backups-overview?tabs=single-database#how-to-change-the-pitr-backup-retention-period) |  PowerShell/ARM |  Long-term geo-redundant backup should be enabled for Azure SQL Databases | <span style="color:green">**FINAL**</span>  |
| CN-SR-08 | Enforce the use of Azure Active Directory. | NA |  PowerShell/ARM  |  Built-in: An Azure Active Directory administrator should be provisioned for SQL servers | <span style="color:green">**FINAL**</span>  |
| CN-SR-09 | Follow the principle of least privilege. | RBAC access control is inherited from the Azure subscription level. At the database security must be designed by application developers. |  NA  |  NA  | <span style="color:green">**FINAL**</span>  |
| CN-SR-10 | Configure security log storage retention. | For Auditing and Advanced Thread Protection a Azure Log Analytics Workspace and a dedicated Azure Storage is required. |  Service requirement | NA  | <span style="color:green">**FINAL**</span>  |
| CN-SR-11 | Enable alerts for anomalous activity. | [Advanced Threat Protection for SQL](https://docs.microsoft.com/en-us/azure/azure-sql/database/threat-detection-overview)  |  PowerShell |  Built-in: Deploy Threat Detection on SQL servers | <span style="color:green">**FINAL**</span>  |
| CN-SR-12 | Configure central security log management. | Security logging must implemented using [Azure Log Analytics Workspace and Azure Storage](https://docs.microsoft.com/en-us/azure/azure-sql/database/auditing-overview). | Service requirement |  NA  | <span style="color:green">**FINAL**</span>  |
| CN-SR-13 | Enable audit logging for Azure resources. | [The default auditing policy includes all actions and the following set of action groups:](https://docs.microsoft.com/en-us/azure/azure-sql/database/auditing-overview#setup-auditing) BATCH_COMPLETED_GROUP, SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP, FAILED_DATABASE_AUTHENTICATION_GROUP | PowerShell/ARM |Built-in: Auditing on SQL server should be enabled | <span style="color:green">**FINAL**</span>  |
| CN-SR-14 | Enable MFA and conditional access with MFA. | Depend on the company Azure AD configuration and policies|  NA |  NA  | <span style="color:green">**FINAL**</span>  |
| CN-SR-15 | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network. SQL Database only accessible with Privat IP. | [Use database-level IP firewall rules whenever possible.](https://docs.microsoft.com/en-us/azure/azure-sql/database/firewall-configure) This practice enhances security and makes your database more portable. Use server-level IP firewall rules for administrators. | PowerShell/ARM |  [Custom: Audit SQL Firewall](https://github.com/Azure/azure-policy/blob/master/samples/SQL/audit-sql-server-firewall-rule/azurepolicy.rules.json) | <span style="color:green">**FINAL**</span>  |
| CN-SR-16 | Ensure that the endpoint protection for all Virtual Machines is installed. | NA |  NA |  NA | <span style="color:green">**FINAL**</span>  |
| CN-SR-17 | Secure outbound communication to the internet.  | NA | NA | NA | <span style="color:green">**FINAL**</span>  |
| CN-SR-18 | Enable JIT network access. | NA | NA | NA | <span style="color:green">**FINAL**</span> |
| CN-SR-19 | Run automated vulnerability scanning tools. | Azure Defender for SQL extend Azure Security Center's data security package to secure your databases and their data.  | PowerShell/ARM |  Built-in: Deploy Threat Detection on SQL servers | <span style="color:green">**FINAL**</span>  |
| CN-SR-20 | Use automated tools to monitor network resource configurations and detect changes.                   | This must be covered by the VNET architecture. |  NA |  NA | <span style="color:green">**FINAL**</span>  |
| CN-SR-21 | Disable remote user access ports (RDP,SSH,Telnet,FTP) | NA | NA | NA | <span style="color:green">**FINAL**</span>  |
| CN-SR-22 | Enable automated Patching/ Upgrading. | [Azure SQL Database](https://docs.microsoft.com/en-us/azure/azure-sql/database/sql-database-paas-overview) is a fully managed platform as a service (PaaS) database engine that handles most of the database management functions without user involvement  |  NA  |  NA | <span style="color:green">**FINAL**</span>  |
| CN-SR-23 | Enable transparent data encryption. | All newly created databases in SQL Database are encrypted by default by using service-managed transparent data encryption. Existing SQL databases created before May 2017 and SQL databases created through restore, geo-replication, and database copy are not encrypted by default. | PowerShell/ARM | Built-in: Deploy SQL DB transparent data encryption | <span style="color:green">**FINAL**</span>  |
| CN-SR-24 | Enable OS vulnerabilities recommendations. | NA | NA | NA | <span style="color:green">**FINAL**</span>  |
| CN-SR-25 | Configure firewall rules of existing firewalls if necessary. | Already covered with CN-SR-15. | NA | NA | <span style="color:green">**FINAL**</span>  |
| CN-SR-26 | Enable command-line audit logging. | NA |  NA  |  NA | <span style="color:green">**FINAL**</span>  |
| CN-SR-27 | Enable conditional access control. | NA |  NA |  NA  | <span style="color:green">**FINAL**</span>  |
| CN-SR-28 | Specify service tags to define network access controls on network security groups or Azure Firewall. | NA | NA |  NA  | <span style="color:green">**FINAL**</span>  |
| CN-SR-29 | Use Corporate Active Directory Credentials.  | Azure AD is the authentication mechanism, if AAD is synchronized with Corporate Active Directory then this requirement is compliant. |  PowerShell/ARM  |  Built-in: An Azure Active Directory administrator should be provisioned for SQL servers  | <span style="color:green">**FINAL**</span>  |

# 6. The following Policies are in place
This section describes the policies which will be implemented for KeyVault. These policies will be assigned when deploying a KeyVault or when deploying a Subcription/Management Group, this separation will be discussed below.

## 6.1. Server level
| Policy type | Policy Display Name | Policy description | Allowed values | Effect | Scope |
| - | - | - | - | - | - |
| custom | Restrict minimum TLS version for SQL Server. | This policy restricts the minimum TLS version you can specify when deploying Azure SQL Servers. | `"1.2"` | Deny | Subscription |
| custom  | Deploys the diagnostic settings for Azure SQL Database server to stream resource logs to a Log Analytics workspace when any SQL Server which is missing this diagnostic settings is created or updated.| This policy checks whether the Azure SQL has Diagnostic settings enabled and whether the correct EventHub and Log analytics workspace Ids are used | n/a |AuditIfNotExists | Subscription |
| Built-in | Advanced data security should be enabled on your SQL servers | Audit SQL servers without Advanced Data Security | n/a |AuditIfNotExists | Subscription | 
| Built-in | Deploy Threat Detection on SQL servers | This policy ensures that Threat Detection is enabled on SQL Servers.| n/a |DeployIfNotExists | Subscription | 
| Built-in |Deploy Auditing on SQL servers | This policy ensures that Auditing is enabled on SQL Servers for enhanced security and compliance. It will automatically create a storage account in the same region as the SQL server to store audit records. | n/a |AuditIfNotExists | Subscription |

## 6.2. Database level
|Policy type | Policy Display Name | Policy description | Allowed values | Effect| Scope |
| - | - | - | - | - | -|
| custom | Restrict allowed SKUs for SQL Database | This policy restricts the SKUs you can specify when deploying Azure SQL Databases. | `"GP_Gen5"` | Audit | Resource |
| built-in | Long-term geo-redundant backup should be enabled for Azure SQL Databases | This policy audits any Azure SQL Database with long-term geo-redundant backup not enabled. | n/a | AuditIfNotExists | Resource |
 built-in | Deploy SQL DB transparent data encryption | Enables transparent data encryption on SQL databases. | n/a | DeployIfNotExists | Resource |

