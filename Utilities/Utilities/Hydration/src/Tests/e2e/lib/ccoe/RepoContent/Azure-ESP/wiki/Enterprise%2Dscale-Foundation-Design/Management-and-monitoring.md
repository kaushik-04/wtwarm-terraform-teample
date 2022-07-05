[[_TOC_]]

# Overview

For all central components managed by the CCoE team, two dedicated Subscriptions will be provisioned to centralize these components, so the Platform teams can use these services, but are not allowed to access these.

![Overview of Management and monitoring](/.attachments/images/Foundation-Design/platform-design-cloud-native-management.png)

In the scope of the ACF engagement, with the focus on providing a secure Landing Zone for the contoso Data project (Malta), the focus is on the monitoring of the 18 components.
For the CCoE teams, the focus of the motoring solutions is focused on Azure Monitor and Azure Security Center, which will collect their data in a centrally deployed Log Analytics Workspace, deployed per Landing Zone. This provides the native Azure monitoring capabilities with  Azure dashboards an alerting in the Azure Portal.

As there is yet no central SIEM solution implemented in the cloud, a solution is agreed with the Monitoring team on collecting the logs in a Central Event Hub, one for non-prod workloads and one for prod workloads, which will be linked to the on-prem Splunk solution . 

In the scope of this project, all services below will be enabled on **each Landing Zone** implemented.

## Azure Monitor

There are a few different resources and services that complete the native monitoring toolkit in Azure. Azure Monitor becomes the service at the top, which spans across all monitoring tools, while everything else lives underneath. The service collects and analyzes data generated from Azure resources. Azure Monitor captures monitoring data from the following sources:

- Application
- Guest OS
- Azure resources
- Azure subscriptions
- Azure tenant

Data collected by Azure Monitor is composed of metrics in Azure Monitor Metrics and logs in Azure Monitor Logs. 

- **Azure Monitor Metrics** are lightweight numerical values stored in a time-series database that can be used for near real time alerting. 
- **Azure Monitor Logs** collects and organizes log data from Azure resources. The major difference between Azure Monitor Metrics and Azure Monitor Logs is the structure of data generated. Azure Monitor Metrics only store numeric data using a specific structure. Azure Monitor Logs can store Azure Monitor Metrics data and a variety of other data types, each using their own structure.

## Log Analytics Workspace

Log Analytics workspaces are containers where Azure Monitor data is collected, aggregated, and analyzed. Compute resources in Azure require a number of agents to help collect monitoring data inside Log Analytics and Azure Monitor.

Azure Monitor stores log data in a Log Analytics workspace. A workspace is a container that includes data and configuration information.

### Access control overview

With Azure role-based access control (Azure RBAC), you can [grant users and groups only the amount of access they need](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/design-logs-deployment#access-control-overview) to work with monitoring data in a workspace.

The data a user has access to is determined by a combination of factors that are listed in the following table. Each is described in the sections below.

| Factor                 | Description                                                                                                                                               |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Access mode            | Method the user uses to access the workspace. Defines the scope of the data available and the access control mode that's applied.                         |
| Access control mode    | Setting on the workspace that defines whether permissions are applied at the workspace or resource level.                                                 |
| Permissions            | Permissions applied to individual or groups of users for the workspace or resource. Defines what data the user will have access to.                       |
| Table level Azure RBAC | Optional granular permissions that apply to all users regardless of their access mode or access control mode. Defines which data types a user can access. |
## Event Hub

Event Hubs is a fully managed, real-time data ingestion service that’s simple, trusted, and scalable. Stream millions of events per second from any source to build dynamic data pipelines and immediately respond to business challenges. Keep processing data during emergencies using the geo-disaster recovery and geo-replication features.

![image.png](/.attachments/image-c2f60be6-b5b8-4928-8d62-1d1f98ea17f2.png)

## Azure Security Center

As a unified infrastructure security management system, Azure Security Center is designed to help you:

- Strengthen the security posture of your organization.
- Meet compliance requirements.
- Provide threat protection for your Azure and non-Azure workloads.
- Use the Azure Security Center dashboard in the Azure portal to obtain and manage an organization level overview of the company’s security posture, compliance, and any threats.

Azure Security Center provides proactive and comprehensive protection for your workloads in the cloud, including:

- Virtual machines and servers.
- Containers.
- Data and storage.
- Internet of Things (IoT) infrastructure.
- Azure Key Vault.

## Microsoft Defender Advanced Threat Protection

Azure Security Center is designed to work with other Azure services to continuously protect and monitor your workloads. Azure Security Center can extend how it protects your cloud workloads by integrating with Microsoft Defender Advanced Threat Protection (ATP) . Both services will work together to provide intelligent endpoint detection and response capabilities. Microsoft Defender ATP detects threats, and triggers alerts. You can then see these alerts from Azure Security Center. From there, you can jump to the Microsoft Defender ATP portal, and carry out detailed investigations to understand the scope of an attack.

## Network watcher

Network Watcher is an Azure service that combines tools in a central place to diagnose the health of Azure networks. Network watcher will be implemented as part of the Certified [**Virtual Network**]([Virtual Network](/Product-Catalog/Virtual-Network) component
The Network Watcher tools are divided into two categories:

### Monitoring tools

- Topology
- Connection Monitor
- Network Performance Monitor

### Diagnostic tools

- IP flow verify
- Next hop
- Effective security rules
- Packet capture
- Connection troubleshoot
- VPN troubleshoot

## CSIRT reader
The CSIRT team requires to see all the subscriptions in the cloud native context. To be able to do this the team needs the following:
  - Group with their Admin Accounts
  - Security Reader resource role assigned to the above group 
  - Assigned on the pxs-cloudnative-mg
  
# Design Decisions

## Management subscription

The Management subscription will be used for the CCoE related workloads to managed the Foundation implementation, eg. for Security Center.

## Logging subscription

A logging subscription will be deployed under the Cloud-native Management Management Group (see section [Governance](/Foundation-Design/Governance.md)).

### Management Log Analytics workspace

- Subscription diagnostic settings will be sent to central dedicated Log Analytics workspace in the logging subscription
- Logs to Management Log Analytics Workspace will be configured via Azure Policy at `Cloud-Native` management group level. See [Governance](/Foundation-Design/Governance.md#cloud-native)

**Access control mode**

The [Access control mode](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/design-logs-deployment#access-control-mode) is a setting on each workspace that defines how permissions are determined for the workspace
- The central Log Analytics workspace will be configured to use resource or workspace permissions. This control mode allows granular Azure RBAC. Users can be granted access to only data associated with resources they can view by assigning Azure `read` permission.

**Default Alerts**

- Service Health alerts
  - Event type: Service Issue, Planned Maintenance, Health advisories, Security Advisory
  - Services: all
  - Regions: West Europe, Global
  - Action: e.g: send email to azure_monitoring@contoso.be
- Resource Health alerts for all resource types
  - Resource Type: all
  - Resource Group: all
  - Event status: all
  - Current resource status: all
  - Previous resource status: all
  - Reason type: all

### LZ Team Log Analytics workspace

- contoso will use one dedicated Azure Log Analytics Workspace for each Cloud-Native Landing Zone, deployed in the CCoE managed Logging Subscription. For Platform workloads, a Log Analytics Workspace can be created in the Landing Zone itself for the use of the Platform team application logging data.
- Logs to LZ Team Log Anlytics Workspace will be configured via Azure Policy at `Cloud-Native` management group level. See [Governance](/Foundation-Design/Governance.md#cloud-native)

**Access control mode**

The [Access control mode](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/design-logs-deployment#access-control-mode) is a setting on each workspace that defines how permissions are determined for the workspace
- Each Landing-Zone work analytics workspace will be configured to require workspace permissions. This control mode does not allow granular Azure RBAC. For a user to access the workspace, they must be granted permissions to the workspace or to specific tables.

**RBAC assignments**

- `LZ Team Contr` AAD Group will be assigned with [Log Analytics Reader](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#log-analytics-reader) built-in role on their log analytics workspace
- All LZ Service Principals will be assigned with [Log Analytics Contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#log-analytics-contributor) built-in role on their log analytics workspace. This built-in role includes the action `Microsoft.OperationalInsights/workspaces/sharedKeys/action`, which is required to read the workspace keys and allow sending logs to this workspace.

# Forwarding logs to On-premise (Splunk)

## Event Hub

- contoso will deploy two Event Hub Namespaces (EHN). One for the production environment and one for the non production environment.
- Each namespace will contain an Event Hub Instance (EHI) for each resource type in use (certified component) and an EHI for the Subscription Activity logs. 
- An EHI in both the Prod and Non prod EHN will be created during the component certification process to receive the logs of that component. 

Splunk add-ons like the Splunk Add-on for Microsoft Cloud Services and the Microsoft Azure Add-on for Splunk provide the ability to connect to, and ingest all kinds of data sources from your Azure environment. If you’re managing large Azure environments, this might require configuring dozens of inputs to ensure you are collecting data from all your subscriptions and resource groups.
By using Event Hubs, we can consolidate some of this effort by configuring logging in Azure to route to an Event Hub and off to the Splunk environment.

Each Certified component will be configured by **policy** to enforce forwarding it's logs to the Log Analytics Workspace and also to the Event Hub.

## Forwarding Security Center Logs to Event Hub

As discussed with contoso, there are 2 ways to export Security Center alerts and notifications to Splunk:
- Splunk Connector for Security Center using Graph API
- Using [Continuous Export](https://docs.microsoft.com/en-us/azure/security-center/continuous-export?tabs=azure-portal)

As the information from the Continuous Export is more relevant for contoso, the continuous export will be configured on each Landing Zone (Subscription) by using a built-in policies on the Cloud Native management group. The built in policy describing all the **settings** applied in the scope of this project for the continuous export can be found here: https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2fproviders%2fMicrosoft.Authorization%2fpolicyDefinitions%2fcdfcce10-4578-4ecd-9703-530938e4abcb

## Capturing ADO logs with Splunk

As ADO doesn't support event forwarding to an Event Hub, the preferable solution is to use an Audit Stream. All details can be found here: https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2fproviders%2fMicrosoft.Authorization%2fpolicyDefinitions%2fcdfcce10-4578-4ecd-9703-530938e4abcb

**Example setup:**

Non prod EHN
   - Virtual machine EHI
   - Key Vault EHI
   - Subscription Activity logs EHI

Prod EHN
   - Virtual machine EHI
   - Key Vault EHI
   - Subscription Activity logs EHI

# Planned work

::: query-table 8cff3fed-4b24-4bbb-9d20-42544b294d88
:::

# Configuration details

## Resource Groups

| Representing | IaC module used                                                                                                          | Configuration file                                                                                                                                                                                                                                                                                                                             | Deployment pipeline                                                                                                                                                                                                                                  | Link to the deployed                                                                                                                                                                               |
| ------------ | ------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Logging RG` | [resourcegroup-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fresourcegroup%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/parameters/resourcegroup/pxs-mgmt-p-log-logging-rg.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fparameters%2Fresourcegroup%2Fpxs-mgmt-p-log-logging-rg.json) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fpipeline.yml) | [pxs-mgmt-p-log-logging-rg](https://portal.azure.com/#@contoso.onmicrosoft.com/resource/subscriptions/94a25935-980f-4ffd-b710-7fb3bf986ae0/resourceGroups/pxs-mgmt-p-log-logging-rg/overview) |

## Log analytics workspace

| Representing                         | IaC module used                                                                                                        | Configuration file                                                                                                                                                                                                                                                                                                                         | Deployment pipeline                                                                                                                                                                                                                                  | Link to the deployed                                                                                                                                                                                                                                                          |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Management Log analytics workspace` | [loganalytics-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Floganalytics%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/parameters/loganalytics/pxs-mgmt-p-log-mgmt-law.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fparameters%2Floganalytics%2Fpxs-mgmt-p-log-mgmt-law.json)   | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fpipeline.yml) | [pxs-mgmt-p-log-mgmt-law](https://portal.azure.com/#@contoso.onmicrosoft.com/resource/subscriptions/94a25935-980f-4ffd-b710-7fb3bf986ae0/resourceGroups/pxs-mgmt-p-log-logging-rg/providers/Microsoft.OperationalInsights/workspaces/pxs-mgmt-p-log-mgmt-law/Overview)   |
| `CCoE Log analytics workspace`       | [loganalytics-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Floganalytics%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/parameters/loganalytics/pxs-mgmt-p-log-ccoe-law.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fparameters%2Floganalytics%2Fpxs-mgmt-p-log-ccoe-law.json)   | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fpipeline.yml) | [pxs-mgmt-p-log-ccoe-law](https://portal.azure.com/#@contoso.onmicrosoft.com/resource/subscriptions/94a25935-980f-4ffd-b710-7fb3bf986ae0/resourceGroups/pxs-mgmt-p-log-logging-rg/providers/Microsoft.OperationalInsights/workspaces/pxs-mgmt-p-log-ccoe-law/Overview)   |
| `BDP Log analytics workspace`        | [loganalytics-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Floganalytics%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/parameters/loganalytics/pxs-mgmt-p-log-bdp-law.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fparameters%2Floganalytics%2Fpxs-mgmt-p-log-bdp-law.json)     | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fpipeline.yml) | [pxs-mgmt-p-log-bdp-law](https://portal.azure.com/#@contoso.onmicrosoft.com/resource/subscriptions/94a25935-980f-4ffd-b710-7fb3bf986ae0/resourceGroups/pxs-mgmt-p-log-logging-rg/providers/Microsoft.OperationalInsights/workspaces/pxs-mgmt-p-log-bdp-law/Overview)     |
| `CSIRT Log analytics workspace`      | [loganalytics-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Floganalytics%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/parameters/loganalytics/pxs-mgmt-p-log-csirt-law.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fparameters%2Floganalytics%2Fpxs-mgmt-p-log-csirt-law.json) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fpipeline.yml) | [pxs-mgmt-p-log-csirt-law](https://portal.azure.com/#@contoso.onmicrosoft.com/resource/subscriptions/94a25935-980f-4ffd-b710-7fb3bf986ae0/resourceGroups/pxs-mgmt-p-log-logging-rg/providers/Microsoft.OperationalInsights/workspaces/pxs-mgmt-p-log-csirt-law/Overview) |

## Eventhubs / namespaces

| Representing          | IaC module used                                                                                                | Configuration file                                                                                                                                                                                                                                                                                                                     | Deployment pipeline                                                                                                                                                                                                                                  | Link to the deployed                                                                                                                                                                                                                                                   |
| --------------------- | -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Event hubs Prod`     | [eventhub-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Feventhub%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/parameters/eventhub/pxs-mgmt-p-log-prod-ehn.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fparameters%2Feventhub%2Fpxs-mgmt-p-log-prod-ehn.json)       | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fpipeline.yml) | [pxs-mgmt-p-log-prod-ehn](https://portal.azure.com/#@contoso.onmicrosoft.com/resource/subscriptions/94a25935-980f-4ffd-b710-7fb3bf986ae0/resourceGroups/pxs-mgmt-p-log-logging-rg/providers/Microsoft.EventHub/namespaces/pxs-mgmt-p-log-prod-ehn/overview)       |
| `Event hubs Non-Prod` | [eventhub-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Feventhub%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/parameters/eventhub/pxs-mgmt-p-log-nonprod-ehn.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fparameters%2Feventhub%2Fpxs-mgmt-p-log-nonprod-ehn.json) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pxs-mgmt-p-log-logging-rg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpxs-mgmt-p-log-logging-rg%2Fpipeline.yml) | [pxs-mgmt-p-log-nonprod-ehn](https://portal.azure.com/#@contoso.onmicrosoft.com/resource/subscriptions/94a25935-980f-4ffd-b710-7fb3bf986ae0/resourceGroups/pxs-mgmt-p-log-logging-rg/providers/Microsoft.EventHub/namespaces/pxs-mgmt-p-log-nonprod-ehn/overview) |
