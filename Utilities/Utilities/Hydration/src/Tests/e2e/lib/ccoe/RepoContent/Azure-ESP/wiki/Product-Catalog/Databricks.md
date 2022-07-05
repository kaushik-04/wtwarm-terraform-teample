# Azure Databricks

| **Status** | <span style="color:orange">**DRAFT**</span> |
|--|--|
| **Version** | v0.1 |
| **Edited By** | Matthias Kufa, Joachim Baert |
| **Date** | 03/02/2021  |
| **Approvers** |  |
| **Deployment documentation** | <link to GIT Module missing> |
| **To Do** | <ul><li>Review required Azure Policies<li>Review service management & security controls</ul> |

[[_TOC_]]

## 1. Introduction

### 1.1. Service Description
Azure Databricks Workspace is a fully managed platform as a service (PaaS) and consists of services such as cluster manager, web application, jobs service, etc. Each service has its own mechanism to isolate the processing, metadata, and resources based on a workspace identifier, which is then used to execute every request. The Databricks Workspace is an interactive workspace that enables collaboration between data engineers, data scientists, and machine learning engineers. For a big data pipeline, the data (raw or structured) is ingested into Azure through job pipelines in batches, or streamed near real-time. This data lands in a data lake for long term persisted Azure storage.

Azure Databricks Workspace is built on a strong security foundation, providing native integration with Azure Active Directory (AAD) and is compliant with major security certifications.


The permission model for databricks exists on three levels:

* **Control plane** is the aspects of the Databricks service configuration is done in the Azure portal (or scripted equivalents). There are no Databricks-specific default roles. Any **Owner** and **Contributor** role member will automatically receive administrator-level access to the Database Workspace

* The **Management plane** is where configuration of all resources inside a workspace is done: workspace access and permissions, cluster creation and configuration, etc... This is detailed in section [[link needed]]() below. 
   * The admin console in the workspace UI is where the workspace-level settings are done and is available only to databricks admins. Some (but not all) of these settings can also be set using the REST APIs or Databricks CLI as well
   * Cluster-level settings are managed in the general workspace UI and are available for admins or other users to which cluster management was delegated

* The **Data plane** is where notebooks or jobs are executed by _attaching_ notebooks or jobs definitions to _clusters_, and available data is browsed or accessed. 

In this version of the Certified Service, a Databricks Workspace will be deployed with the following features:

* Set for **batch** workloads. Interactive workloads are not (yet) support (in this version). See also the section on [Databricks workloads]() further in this document.
* A databricks workspace with **Premium** SKU and default vnet settings (public IP endpoints, no vnet injection)
* A locked resource group which holds a default vnet and network security group, the DBFS storage account, and all clusters nodes created later on

## 2. Architecture

### 2.1. High Level Design


Azure Databricks operates out of a control plane and a data plane.

The control plane includes the backend services that Azure Databricks manages in its own Azure account. Any commands that you run will exist in the control plane with your code fully encrypted. Saved commands reside in the data plane.

The data plane is managed by your Azure account and is where your data resides. This is also where data is processed. This diagram assumes that data has already been ingested into Azure Databricks, but you can ingest data from external data sources, such as events data, streaming data, IoT data, and more. You can connect to external data sources outside of your Azure account for storage as well, using Azure Databricks connectors.

![databricks-architecture-azure.png](/.attachments/databricks-architecture-azure.png)

The _data_ always resides in your Azure account in the data plane, not the control plane, so you always maintain full control and ownership of your data without lock-in.

Azure Databricks (ADB) uses Azure Active Directory (AAD) as the exclusive Identity Provider and there’s a seamless out of the box integration between them. If a user is not a member or guest of the Active Directory tenant, they can’t login to the workspace. 

Multiple clusters can exist within a workspace, and there’s a one-to-many mapping between a Subscription to Workspaces, and further, from one Workspace to multiple Clusters.

![Relationship between AAD-Workspace-RG-Clusters.png](/.attachments/Relationship%20between%20AAD-Workspace-RG-Clusters-b25c53f7-ec7d-4c10-a572-579cf3c1ead7.png)

**Cluster pools:**

To reduce cluster start time, you can attach a cluster to a predefined pool of idle instances. When attached to a pool, a cluster allocates its driver and worker nodes from the pool. If the pool does not have sufficient idle resources to accommodate the cluster’s request, the pool expands by allocating new instances from the instance provider. When an attached cluster is terminated, the instances it used are returned to the pool and can be reused by a different cluster.

For more information, see [cluster pools](https://docs.microsoft.com/en-us/azure/databricks/clusters/instance-pools/)



#### 2.1.1 Map Workspaces to Business Divisions

Workspaces should assigned based on a related group of people working together collaboratively. This also helps in streamlining the access control matrix within your workspace (folders, notebooks etc.) and also across all resources that the workspace interacts with (storage, related data stores like Azure SQL DB, Azure SQL DW etc.). This type of division scheme is also known as the Business Unit Subscription design pattern and it aligns well with the Databricks chargeback model.

To trade with different requirements and limitations with ADB workspaces, we consider the [Map Workspaces to Business Workload](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki?wikiVersion=GBfeature%2F10263&pagePath=%2FProduct%20Catalog%2FDatabricks&pageId=1082&_a=edit&anchor=2.1.1-map-workspaces-to-business-divisions) approach. Which means, that user with the same data access permissions, will consolidated at a ADB Workspace. 

#### 2.1.2 Databricks workloads

In general, databricks is used in two types of workloads:

1) **Interactive** workloads

   * In this mode, the Databricks workspace as analytics platform for collaboration between data engineers, data scientists, and machine learning engineers.
   * Clusters should rely on **passthrough authentication** to the underlying data stores (data lake, synapse). If possible, we avoid to setup -and more importantly, maintain- table access control.
   * Clusters can be configured in **high concurrency mode**, unless there is a need to run Scala workloads. 

   ![Interactive-Clusters.png](/.attachments/Interactive-Clusters-57fa06db-91df-4422-8041-a355761061cc.png)

   _Image source: [https://github.com/Azure/AzureDatabricksBestPractices](https://github.com/Azure/AzureDatabricksBestPractices)_


2) **Batch** workloads 

   * The Databricks workspace is used for data processing for batch and streaming workloads, including Databricks as a compute engine for MLS jobs.
   * Clusters for batch workloads should be configured in **Standard mode**: they will run one job at a time, with more predictable performance results. Standard clusters can run workloads in any language (SQL, R, Python or Scala)
   * Batch workload clusters should access the underlying data with fixed service principal credentials: Passthrough may work in some but not all required scenarios so we will standardize on passthrough.

    ![Batch-Clusters.png](/.attachments/Batch-Clusters-73a20c30-ca8b-485d-81ea-ba71ed30e246.png)

    _Image source: [https://github.com/Azure/AzureDatabricksBestPractices](https://github.com/Azure/AzureDatabricksBestPractices)_


| Workload | Environment| Users | Usage |
|--|--|--|--|
| Batch | Non-Prod | Service Principals + Data Engineers | Batch Jobs ETL, Development-related exploration
|   | Prod | Service Principals | Batch Jobs ETL
| Interactive | Prod | Data Scientists, Exploration | Ad-hoc queries, Reporting


As the settings and access controls differ between these types of workloads, each workspace should only be used to support one of the workload types. I.e., separate workspaces for interactive vs batch workloads.

To identify the usage, we will use a mandatory `adb-workload` tag with acceptable values `interactive` or `batch`

> **TODO**: document/define azure policy


How interactive workloads are different from batch workloads:

There are three steps for supporting Interactive workloads on ADB:

### 2.2. Data plane

#### 2.2.1 Network security

The default deployment of Azure Databricks is a fully managed service on Azure: all data plane resources, including a virtual network (VNET) that all clusters will be associated with, are deployed to the databricks locked vnet:

![databricks-network-architecture](/.attachments/databricks-network-architecture.png)


* A vnet `workers-vnet` is created for each Databricks workspace, with `public-subnet` and `private subnet` subnets. All nodes in the databricks clusters are created with two NICs, linked to the public and private subnets.

* A network security group `workers-sg` is created for each Databricks workspace and linked to both subnets. The nsg has an identical setup for the private and public subnets:
    * Allow incoming traffic on the control plane: port 22 (ssh), and 5557 (worker proxy)
    * Allow incoming worker-to-worker traffic (intra-subnet traffic)

> Notes: 
> * It's possible to apply [vnet peering](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/cloud-configurations/azure/vnet-peering) to securely connect the default Databricks vnet to other private networks
> * Databricks deployments offer options to deploy those resources to an existing vnet ([vnet injection](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/cloud-configurations/azure/vnet-inject)) but this option is NOT supported by the certified product
> * The default deployment exposes Public IP address for all cluster nodes. Another options is to use [Secure cluster connectivity](https://docs.microsoft.com/en-us/azure/databricks/security/secure-cluster-connectivity)  but this option is as well NOT supported

#### 2.2.2 Access control

Azure Databricks Workspace provides enterprise-grade Azure security, including Azure Active Directory integration, role-based controls, and SLAs that protect your data and your business.

Integration with Azure Active Directory enables you to run complete Azure-based solutions using Azure Databricks.

Table, cluster, pool, job, and workspace access control are available only in the Azure Databricks Premium Plan

For interactive ADB workspace Azure Active Directory credential passthrough must be enabled to control access to the data lake storage. Credential passthrough provides user-scoped data access controls to any provisioned file stores based on the user’s role based access controls or [ACLs](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-access-control). This approach best support the logging user-level entries in Azure storage audit logs, which is mandatory to associate storage layer actions with specific users.

To trade technical limitations and productive interoperability, batch ADB workspace will configured with use of Azure AD Service Principal (technical user) for data lake store access.

#### 2.2.1. Endpoint Access
A unique instance name, also known as a per-workspace URL, is assigned to each Azure Databricks deployment. It is the fully-qualified domain name used to log into your Azure Databricks deployment and make API requests.

[The unique per-workspace URL has the format adb-<workspace-id>.<random-number>.azuredatabricks.net](https://docs.microsoft.com/en-us/azure/databricks/workspace/workspace-details#--workspace-instance-names-urls-and-ids).

#### 2.2.2. Endpoint Authorization and Authentication
Authentication and access control for Databricks REST APIs is supported through Azure Active Directory (Azure AD) or Azure Databricks personal access tokens.

#### 2.2.1 Table Access
Table Access control feature is only available in High Concurrency mode and needs to be turned on so that users can limit access to their database objects (tables, views, functions, etc.) created on the shared cluster. Best practice for easy manageability is, restricting access using Azure Data Lake storage and the AAD Credential Passthrough feature instead of Table Access Controls.

**Note**: It is recommend to have a Data Lake Lake concept in place, that reflects different Zones, for instance: Raw, Analytics, Curative. 

### 2.3. Management Plane 

In Azure Databricks access control lists (ACLs) can be used to configure permissions to access workspace objects. All admin users can manage access control lists, as can users who have been given delegated permissions to manage access control lists. 

Users with the Contributor or Owner role on the workspace resource can sign in as administrators via the Azure portal. 

### 2.3.1 Users and Groups


Note: Workspace object, cluster, pool, job, and table access control are available only in the Azure Databricks Premium Plan.

The Azure Databricks **admin role** can manage user accounts and group membership using the Azure Databricks Admin Console, the [SCIM](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/scim/) and Groups APIs, and Azure Active Directory single sign-on and provisioning. 

The admin role is assigned automatically to any user logging in to the workspace, with the **Owner** or **Contributor** RBAC role on the Azure Databricks Workspace resource.

All other users need to be provisioned in the Workspace before they will be able to access the workspace. 

> Note: this includes the DevOps service principal executing deployments. To be able to manage the newly created workspace (i.e. [get an Azure Active Directory token using a service principal](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/service-prin-aad-token#--use-the-service-principals-azure-ad-access-token-to-access-the-databricks-rest-api)), the DevOps sp needs to have at least Contributor RBAC role on the workspace resource.

Users can be provisioned manually using the workspace UI, or using the [SCIM API](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/scim/).

SCIM lets you manage users in the Databricks workspaces in two ways:

1. use an identity provider (IdP) to create users in Azure Databricks and give them the proper level of access and remove access (deprovision them) when they leave your organization or no longer need access to Azure Databricks. 
2. invoke the SCIM API directly to manage provisioning

Using the Identity provider is at this point not recommend because of the following limitation:
* No support for nested groups. All users requiring access to a workspace need to be direct members of a AAD group.

> **Note**: Currently (Feb 2021) SCIM is in Public Preview and not recommend for use in production environments. However, it's the only way to provision users and the biggest risk is that, when our SCIM scripts fail, the user provisioning will not work (but the service will not fail). 

Databricks workspace  users will be created by a script using the SCIM API directly, to synchronize users & roles based AAD groups


#### 2.3.2. Workspace Access Control

[Workspace object access control](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/access-control/workspace-acl) is a must-have setting, otherwise no ACLs will be evaluated (all users can create any modify any workspace object). New Databricks workspaces have this setting enabled by default.

> There is no scripted option to verify the setting of the Workspace Access Control setting. The only way to audit this setting is by creating alerts based on events in Log Analytics (when the setting is being changed)

#### 2.3.3. Cluster Access Control

By default, all users can create and modify clusters in a Databricks workspace. It is therefore crucial to enable 
[Cluster, Pool and Jobs Access Control](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/access-control/cluster-acl).

> There is no scripted option to verify the setting of the Cluster Access Control setting. The only way to audit this setting is by creating alerts based on events in Log Analytics (when the setting is being changed)


With Cluster Access Control is activated:
* The **Allow Cluster Creation** user/group setting controls cluster creation permissions. This can be managed in the admin console or using the [SCIM-Users API](https://docs.databricks.com/dev-tools/api/latest/scim/scim-users.html) (in public preview)
* **[Cluster-level permissions](https://docs.microsoft.com/en-us/azure/databricks/security/access-control/cluster-acl#cluster-level-permissions)** determine whether a user can attach to, restart, resize, and manage that cluster. Cluster permissions can be set in the admin console, or using the [permissions API](https://docs.databricks.com/dev-tools/api/latest/permissions.html) (in public preview)

#### 2.3.4. Pool Access Control

To use ACL limitations for pools, the [Cluster, Pool and Jobs Access Control](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/access-control/cluster-acl) setting needs to be activated on the workspace level (see section [Cluster Access Control](#)).

When activated [Pool access control](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/access-control/pool-acl) limitations can be set for users and groups, per Cluster Pool:

- No Permissions
- Can Attach To
- Can Manage: attach to, and edit/modify/delete pool

#### 2.3.5. Jobs Access Control

Enabling [Jobs access control](https://docs.microsoft.com/en-us/azure/databricks/security/access-control/jobs-acl) allows job owners to control who can view job results or manage runs of a job. This article describes the individual permissions and how to configure jobs access control.

The [Cluster, Pool and Jobs Access Control](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/access-control/cluster-acl) needs to enabled(see 
also section [2.3.3. Cluster Access Control](#)).

For detailed information see [Jobs access control](https://docs.microsoft.com/en-us/azure/databricks/security/access-control/jobs-acl), but in summary:
* There are five permission levels for jobs: No Permissions, Can View, Can Manage Run, Is Owner, and Can Manage. 
* Admins are granted the Can Manage permission by default, and they can assign that permission to non-admin users.
* The creator of a job is automatically the Owner of the job

Job permissions can be managed using the UI, or using the [Permission API](https://docs.microsoft.com/en-us/azure/databricks/_static/api-refs/permissions-azure.yaml)


#### 2.3.6. Table Access Control

[Table access control](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/access-control/table-acl) lets you programmatically grant and revoke access to your data from Python and SQL.

By default, all users have access to all data stored in a cluster’s managed tables unless table access control is enabled for that cluster. Once table access control is enabled, users can set permissions for data objects on that cluster.

> This setting is per cluster. To make Table Access Control effective, users should not be able to create their own clusters (user-level `Allow create clusters` permission), and do not have the `AttachTo` permission for clusters that are not enabled for table access control.


### 2.3.7. Conditional Access

Azure Databricks supports Azure Active Directory conditional access, which allows administrators to control where and when users are permitted to sign in to Azure Databricks.

See [Conditional Access](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/access-control/conditional-access) for details.


 
### 2.4. Service Limits
Customers commonly partition workspaces based on teams or departments and arrive at that division naturally. It is also important to partition keeping Azure Subscription and ADB Workspace limits in mind.

#### 2.4.1 Databricks Workspace Limits
Azure Databricks is a multitenant service and to provide fair resource sharing to all regional customers, it imposes limits on API calls. These limits are expressed at the Workspace level and are due to internal ADB components. For instance, you can only run up to 150 concurrent jobs in a workspace. Beyond that, ADB will deny your job submissions. There are also other limits such as max hourly job submissions, max notebooks, etc.

Key workspace limits are:

- The maximum number of jobs that a workspace can create in an hour is 1000
- At any time, you cannot have more than 150 jobs simultaneously running in a workspace
- There can be a maximum of 150 notebooks or execution contexts attached to a cluster
- The maximum number secret scopes per workspace is 100
- Azure Subscription Limits
- Next, there are Azure limits to consider since ADB deployments are built on top of the Azure infrastructure.

Key Azure limits are:

- Storage accounts per region per subscription: 250
- Maximum egress for general-purpose v2 and Blob storage accounts (all regions): 50 Gbps
- VMs per subscription per region: 25,000
- Resource groups per subscription: 980
- These limits are at this point in time and might change going forward. Some of them can also be increased if needed. For more help in understanding the impact of these limits or options of increasing them, please contact Microsoft or Databricks technical architects.

## 3. Service Provisioning
### 3.1. Prerequisites
The following Azure resources need to be in place before this Certified Service can be provisioned:

- Subscription
- Resource Group
- Azure Data Lake Storage Gen2* 
- Azure Databricks Premium Plan

**Note**: Storage accounts must use the hierarchical namespace to work with Azure Data Lake Storage credential passthrough. Permissions for Azure Databricks users on the data they need to read from and write to in Azure Data Lake Storage must be properly configured.

### 3.2. Deployment parameters
|  |  Prod	| Non-Prod | Implementation |Implementation Status|
|--|--|--|--|--|
| **Azure Region** | West EU (Default Value)/North Europe | West EU (Default Value)/North Europe  | Parameter |<span style="color:green">**IMPLEMENTED<br>Policy on root**</span>|
| **SKU** | Premium | Premium  | Default |<span style="color:red">**NOT IMPLEMENTED<br>Policy?**</span>|
| **Workspace Name** | <pxs-{platform_id}-{app_id}-{environment}-adb{suffix}> | <pxs-{platform_id}-{app_id}-{environment}-adb{suffix}> | Default |<span style="color:orange">**IMPLEMENTED<br>Policy?**</span>|
| **Connectivity method** | Public endpoint| Public endpoint | Parameter |<span style="color:red">**NOT IMPLEMENTED<br>Policy?**</span>|
| **Diagnostics Storage** | Storage/Log Analytics/Event Hub | Storage/Log Analytics/Event Hub | Parameter |<span style="color:red">**NOT IMPLEMENTED<br>Policy?**</span>|

## 4. Service Management 
All product-specific MSMCF controls - for the current product version - can be found on the table below:

 

| **MSM Code** | **Functional Control Description** | **Category** | **Product Assessment Q&A** | **Validated** | **Implementation** | **Status** |
|----------|----------------------------------------------------------------------------------------------------------------------------|------------------------|------------------------|------------------------|----|----|
| **M-STD02** | Health alerts are automatically generated, correlated and managed based on event monitoring.                            |     Standard   |   [Requires diagnostic settings for Azure Databricks and send logs to a Log Analytics workspace. Use the Log Analytics workspace to analyze and monitor your Azure Databricks logs for anomalous behavior and regularly review results](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#26-monitor-and-review-logs).    |      Yes     |   [This control is applied by defining Resource Health Alerts in Azure Monitor which requires additional configuration there](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#27-enable-alerts-for-anomalous-activity).   |   <span style="color:green">**FINAL**</span>   |
|  **M-STD05**        |       Disaster Recovery (DR) scenario’s are applied and  tested periodically          |    Standard    | Azure Databricks is a compute service which is having dependencies to data stores. Controls must be applied to data stores. |  No  |   N/A   |     <span style="color:green">**FINAL**</span>   |
|  **M-PaaS01**       |        RTO / RPO requirements are achieved for PaaS backup and restore           |    Standard    |   Azure Databricks is a compute service which is having dependencies to data stores. Controls must be applied to data stores. |  No  |   N/A   |     <span style="color:green">**FINAL**</span>   |

## 5. Security Controls 

All product-specific security controls - for the current product version - can be found on the table below:

**Note**: Azure Policies are not available for Databricks Workspace. ADB provides Azure Databricks provides comprehensive diagnostic logs of activities performed by users, allowing to monitor detailed usage patterns. Alerts must be configured to to track changes affecting relevant security controls.

| Index | Security Requirements | Relevance | Implementation details  | Policy Enforced / Audit | Status  | Implementation Status |
|--|--|--|--|--|--|--|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later).  | HTTPS/TLS needs to be enforced. | [Microsoft will negotiate TLS 1.2 by default when administering your Azure Databricks instance through the Azure portal or Azure Databricks console. Databricks Web App supports TLS 1.3](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#44-encrypt-all-sensitive-information-in-transit). <p><br>**Note**: [Data exchanged between worker nodes in a cluster is not encrypted. If the environment requires that data be encrypted at all times, whether at rest or in transit, an init script must be created that configures the clusters to encrypt traffic between worker nodes, using AES 128-bit encryption over a TLS 1.2 connection](https://docs.microsoft.com/en-us/azure/databricks/security/encryption/encrypt-otw).| N/A | <span style="color:green">**FINAL**</span>|<span style="color:green">**IMPLEMENTED**</span>|
| CN-SR-02 | Secret and Key management needs to be done by a dedicated database/vault. | [There are two types of secret scope: Azure Key Vault-backed and Databricks-backed. Scope permissions Scopes are created with permissions controlled by ACLs](https://docs.microsoft.com/en-us/azure/databricks/security/secrets/secret-scopes). | N/A | N/A | <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-03 | Encrypt information at rest (Disc encryption). | The data that is in Azure Databricks Workspace is stored on Azure Storage. [Azure Storage automatically encrypts data when it is persisted to the cloud](https://docs.microsoft.com/en-us/azure/storage/common/storage-service-encryption). | N/A  | N/A | <span style="color:green">**FINAL**</span> |<span style="color:green">**IMPLEMENTED**</span>|
| CN-SR-04 | Maintain an inventory of sensitive Information.  | [Use Tags to assist in tracking Azure Databricks instances that process sensitive information.](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#41-maintain-an-inventory-of-sensitive-information) | ARM/PowerShell | N/A | <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-05 | Use an active discovery tool to identify sensitive data.  | [Currently not available; data identification, classification, and loss prevention features are not currently available for Azure Databricks. Tag Azure Databricks instances and related resources that may be processing sensitive information as such and implement third-party solution if required for compliance purposes.](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#41-maintain-an-inventory-of-sensitive-information) | N/A  | N/A  | <span style="color:green">**FINAL**</span> |<span style="color:orange">**NOT AVAILABLE **</span>|
| CN-SR-06 | Protect the database from permanently deleting data by enabling soft delete functionality.  | [The Databricks platform is compute-only, and all the data is stored on other Azure data services. For the underlying platform which is managed by Microsoft, Microsoft treats all customer content as sensitive and goes to great lengths to guard against customer data loss and exposure. To ensure customer data within Azure remains secure, Microsoft has implemented and maintains a suite of robust data protection controls and capabilities.](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#41-maintain-an-inventory-of-sensitive-information) | N/A | N/A | <span style="color:green">**FINAL**</span> |<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-07 | Ensure regular automated back ups  | [Azure Databricks data sources have to be configured an appropriate level of data redundancy for its use case, be choose of the appropriate redundancy option (LRS, ZRS, GRS, RA-GRS).](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#91-ensure-regular-automated-back-ups) | N/A | N/A | <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-08 | Enforce the use of Azure Active Directory.  | [Single sign-on (SSO) in the form of Azure Active Directory-backed login is available in Azure Databricks. Only users who are belonging to the AAD can be added to ADB workspace.](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/single-sign-on/).  | N/A | N/A | <span style="color:green">**FINAL**</span>|<span style="color:green">**IMPLEMENTED**</span>|
| CN-SR-09 | Follow the principle of least privilege.  | [Access to data objects is governed by privileges at the storage layer.](https://docs.microsoft.com/en-us/azure/databricks/security/data-governance#how-azure-databricks-addresses-these-challenges). | N/A | N/A | <span style="color:green">**FINAL**</span> |<span style="color:green">**IMPLEMENTED**</span>|
| CN-SR-10 | Configure security log storage retention.  | [Enable diagnostic settings for Azure Databricks with the use of Log Analytics](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/manage-cost-storage#change-the-data-retention-period). | ARM/PowerShell | [Azure Policy Diagnostic Settings](https://github.com/tyconsulting/azurepolicy/tree/master/policy-definitions/resource-diagnostics-settings)| <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-11 | Enable alerts for anomalous activity.  | [Configuration of Databricks diagnostic that send logs to Log Analytics workspace. Within Log Analytics workspace the configuration of alerts required when a pre-defined set of conditions takes place.](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#27-enable-alerts-for-anomalous-activity). | [ARM/PowerShell](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/account-settings/azure-diagnostic-logs#configure-diagnostic-log-delivery) |[Azure Policy Diagnostic Settings](https://github.com/tyconsulting/azurepolicy/tree/master/policy-definitions/resource-diagnostics-settings) | <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-12 | Configure central security log management.   |  [Enable diagnostic settings for Azure Databricks and send logs to a Log Analytics workspace. Use the Log Analytics workspace to analyze and monitor Azure Databricks logs for anomalous behavior and regularly review results](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#26-monitor-and-review-logs). | ARM/PowerShell | [Azure Policy Diagnostic Settings](https://github.com/tyconsulting/azurepolicy/tree/master/policy-definitions/resource-diagnostics-settings)| <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-13 | Enable audit logging of Azure Resources.  | [Enable Azure Activity Log diagnostic settings and send the logs to a Log Analytics workspace, Azure event hub, or Azure storage account for archive](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#26-monitor-and-review-logs). | [ARM/PowerShell](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/account-settings/azure-diagnostic-logs#configure-diagnostic-log-delivery) | [Azure Policy Diagnostic Settings](https://github.com/tyconsulting/azurepolicy/tree/master/policy-definitions/resource-diagnostics-settings)| <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-14 | Enable MFA and conditional access with MFA. | [Enable Azure AD MFA and follow Azure Security Center Identity and Access Management recommendations](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#35-use-multi-factor-authentication-for-all-azure-active-directory-based-access). | N/A | N/A | <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-15 | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network. | [This contoso product reference to "cloud-native" and will not require VNET integration. If required for the production environment, access to workspace can be restricted by IP access lists](https://docs.microsoft.com/en-us/azure/databricks/security/network/ip-access-list).| N/A | N/A | <span style="color:green">**FINAL**</span>|<span style="color:grey">**N/A**</span>|
| CN-SR-16 | Ensure that the endpoint protection for all Virtual Machines is installed. | [This is not applicable since Azure Databricks is fully by Microsoft managed PaaS.](https://docs.microsoft.com/en-us/azure/security/fundamentals/protection-customer-data) | N/A  | N/A | <span style="color:green">**FINAL**</span>|<span style="color:grey">**N/A**</span>|
| CN-SR-17 | Secure outbound communication to the internet. | [This contoso product reference to "cloud-native" and will not require VNET integration. If required for the production environment, access to workspace can be restricted by IP access lists](https://docs.microsoft.com/en-us/azure/databricks/security/network/ip-access-list).| N/A | N/A | <span style="color:green">**FINAL**</span>|<span style="color:grey">**N/A**</span>|
| CN-SR-18 | Enable JIT network access.  | [For security reasons, in Azure Databricks the SSH port is closed by default.](https://docs.microsoft.com/en-us/azure/databricks/clusters/configure#--ssh-access-to-clusters) Connections can made only through the API or workspace management plane. | N/A  | N/A | <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**<br>Policy?</span>|
| CN-SR-19 | Run automated vulnerability scanning tools.  | [Requires implementation of a third-party vulnerability management solution.](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#vulnerability-management) | N/A | N/A  | <span style="color:green">**OPEN**</span>|<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-20 | Use automated tools to monitor network resource configurations and detect changes.  |  [Azure Activity Log can used to monitor network resource configurations and detect changes for network resources related to your Azure Databricks instances](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#38-manage-azure-resources-from-only-approved-locations) | [ARM/PowerShell](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/activity-log#view-the-activity-log)  | N/A | <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-21 | Disable remote user access ports (RDP,SSH,Telnet,FTP).  |  [For security reasons, in Azure Databricks the SSH port is closed by default. SSH can be enabled only if the workspace is deployed into a VNET](https://docs.microsoft.com/en-us/azure/databricks/clusters/configure#--ssh-access-to-clusters). | N/A  | N/A | <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**<br>policy?</span>|
| CN-SR-22 | Enable automated Patching/ Upgrading.  |  This is not applicable since Azure Databricks is fully by Microsoft managed PaaS. | N/A  | N/A | <span style="color:green">**FINAL**</span>|<span style="color:grey">**N/A**</span>|
| CN-SR-23 | Enable transparent data encryption. | Azure Databricks is a compute service which is depended on external data stores. | N/A  | N/A | <span style="color:green">**FINAL**</span>|<span style="color:grey">**N/A**</span>|
| CN-SR-24 | Enable OS vulnerabilities recommendations.  |  This is not applicable since Azure Databricks is fully by Microsoft managed PaaS. | N/A  | N/A | <span style="color:green">**FINAL**</span>|<span style="color:red">**N/A**</span>|
| CN-SR-25 | Configure firewall rules of existing firewalls if necessary.  | Firewall needs to be configured as part of the product | [This contoso product reference to "cloud-native" and will not require VNET integration. If required for the production environment, access to workspace can be restricted by IP access lists](https://docs.microsoft.com/en-us/azure/databricks/security/network/ip-access-list). | N/A  | <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-26 | Enable command-line audit logging.  | [Not applicable; this guideline is intended for compute resources](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#210-enable-command-line-audit-logging). | N/A  | N/A | <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**Not clear, Databricks is a compute resource? </span>|
| CN-SR-27 | Enable conditional access control.  | [Conditional Access Named Locations to allow access from only specific logical groupings of IP address ranges or countries/regions can be configured](https://docs.microsoft.com/en-us/azure/databricks/scenarios/security-baseline#38-manage-azure-resources-from-only-approved-locations) | N/A  | N/A | <span style="color:green">**FINAL**</span>|<span style="color:red">**NOT IMPLEMENTED**</span>|
| CN-SR-28 | Specify service tags to define network access controls on network security groups or Azure Firewall. |  This contoso product reference to "cloud-native" and will not require VNET integration. | N/A  | N/A | <span style="color:green">**FINAL**</span>|<span style="color:grey">**N/A**</span>|
| CN-SR-29 | Use Corporate Active Directory Credentials.  |  [Azure Databricks is automatically setup to use Azure Active Directory single sign-on to authenticate users](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/single-sign-on/).  | N/A  | N/A | <span style="color:green">**FINAL**</span>|<span style="color:grey">**N/A**</span>|

## 6. Policies to be implemented
