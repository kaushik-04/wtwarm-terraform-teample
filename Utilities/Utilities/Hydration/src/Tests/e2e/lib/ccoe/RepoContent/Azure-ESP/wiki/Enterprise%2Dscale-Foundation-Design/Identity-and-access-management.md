[[_TOC_]]

# Overview

![Overview of Identity and access management](/.attachments/images/Foundation-Design/platform-design-identity.png)

> NOTE: the diagram can be modified using the Visio file on [Teams GRP MCS Cloud-native Engagement > Agile Delivery](https://teams.microsoft.com/_?lm=deeplink&lmsrc=homePageWeb&cmpid=WebSignIn#/conversations/Agile%20Delivery?threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&ctx=channel) > Files > [01 - Design Documents](https://contoso.sharepoint.com/sites/GRP_001608-AgileDelivery/Shared%20Documents/Forms/AllItems.aspx?RootFolder=%2Fsites%2FGRP%5F001608%2DAgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20%2D%20Design%20Documents&FolderCTID=0x01200001544C4EB547E84DB41D1C6FCCD4BEA9) > [PXS - Diagrams.vsdx](https://teams.microsoft.com/l/file/6F59E176-935C-450C-B8A0-A23AB3831B4C?tenantId=e7ab81b2-1e84-4bf7-9dcb-b6fec01ed138&fileType=vsdx&objectUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20-%20Design%20Documents%2FPXS%20-%20Diagrams.vsdx&baseUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery&serviceName=teams&threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&groupId=348f9039-5718-417a-8e56-85e2957e26be)

# Design decisions

## Privileged Identity Management

Historically, you could assign a user to an admin role through the Azure classic portal or Windows PowerShell. As a result, that user becomes a permanent admin, always active in the assigned role. Azure AD Privileged Identity Management introduces the concept of an eligible admin. Eligible admins should be users that need privileged access now and then, but not every day. The role is inactive until the user needs access, then they complete an activation process and become an active admin for a predetermined amount of time.
- contoso wants to minimize the number of people who have access to secure information or resources, because that reduces the chance of a malicious user getting that access. However, users still need to carry out privileged operations in Azure, Office 365, or SaaS apps.
- contoso will use a standard named account for access to Azure resources. A second privileged account is only used when administering resources. With Azure Active Directory (AD) Privileged Identity Management, you can manage, control, and monitor access within your organization. This includes access to resources in Azure AD and other Microsoft online services like Office 365 or Microsoft Azure. Privileged Identity Management is available only with the **Premium P2 edition of Azure Active Directory**.
- contoso will use Azure Privileged Identity Management (PIM) to control which personal Azure AD accounts are used, limiting to Just Enough Access (JEA) and Just-In-Time (JIT).

PIM audit history allows to see all role assignments and activations within the past 30 days for all privileged roles. For the full audit history of activity in your Azure Active Directory (Azure AD) organization, including administrator, end user, and synchronization activity, use the default build-in [Azure Active Directory security and activity reports](https://docs.microsoft.com/en-us/azure/active-directory/reports-monitoring/overview-reports).

A separate PIM design document is delivered to contoso and can be found here: [contoso Azure AD PIM Design](https://teams.microsoft.com/l/file/9cff1c89-d494-45a7-bf72-2e4ba1814ec0?tenantId=e7ab81b2-1e84-4bf7-9dcb-b6fec01ed138&fileType=docx&objectUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608%2FShared%2520Documents%2FGeneral%2Fcontoso%2520-%2520Azure%2520AD%2520PIM-Design.docx&baseUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608&serviceName=aggregatefiles)

## Conditional Access and Multi Factor Authentication

CA and MFA is not in scope of this project and is covered in another Microsoft engagement currently delivered at contoso.

## Role-Based Access Control

Azure Role-Based Access Control (RBAC) allows contoso to grant appropriate access to Azure Active Directory users, groups, and services, by assigning roles to them on a Subscription, Resource Group or individual resource level. The standard RBAC roles below are all related to the control plane in Azure. The assigned role defines the level of access that the users, groups, or services have on the Azure resource.
In addition to the built in RBAC roles definitions, it is possible to create custom role definitions that can be loaded into a subscription and scoped at the entire subscription or a resource group. Custom roles can be used to create new role definitions or the tweaking of existing role definition.

## RBAC Auditing

Monitoring changes in RBAC settings will be configured using alerts in Log Analytics. Alerts will initially be created for the following control plane changes:

- Assessment on RBAC roles assigned to Resource Groups.
- Apply notification on creation custom role.
- Group assignment to role.

## Service Principal strategy

A [service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals#service-principal-object) is the local representation, or application instance, of a global application object in a single tenant or directory. The Enterprise applications blade in the portal is used to list and manage the service principals in a tenant. You can see the service principal's permissions, user consented permissions, which users have done that consent, sign in information, and more.

- Service Principals are linked to Azure DevOps via [Service Connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml) to connect to the Azure Environment and remote services with tasks in Azure Pipelines. See section [Azure DevOps Organization](/Foundation-Design/Azure-DevOps-Organization.md).
- Any changes in Azure for Non-production and Production environments need to be coded, automated, tested and deployed via Azure Pipeline using the Service Connections linked to Service Principals.
- The CCoE use Service Principals that allow them to manage the [Foundation Platform](/Foundation-Design.md) via code and [develop, test and publish Certified Components](/Certified-Components.md).
- The Landing Zone Teams use Service Principals with permissions to [use Certified Components](/Certified-Components/Component-usage.md) that allow them manage Workload infrastructure and code in the Cloud-Native Landing Zones.

### Service Principals for Azure Platform Management

The `Governance mgmt` Service Principal will be used for the management of the [Cloud-native Foundation Platform](/Foundation-Design.md) and [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md), including management of:
- [Governance](/Foundation-Design/Governance.md) (Cloud-native Management Groups, Subscriptions, Policies and Custom RBAC roles)
- [Management and monitoring](/Foundation-Design/Management-and-monitoring.md) (Azure Resources such as Log Analytics and Event Hub to support management and monitoring of the Foundation Platform and Landing Zones)
- [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md) (Subscriptions and Policies)

**Azure RBAC**

The `Governance mgmt` Service Principal will be assigned permissions at different levels using Custom Roles following the least-privilege principle. See the section [Governance](/Foundation-Design/Governance.md) for more details on this configuration.

**Azure Active Directory RBAC**

The `Governance mgmt` Service Principal will be assigned with the following Roles in Azure Active Directory following the least-privilege principle.
- [`Directory Readers`](https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#directory-readers). Can read basic directory information. Required to find identities in Azure Active Directories and do RBAC assignments

### Service Principals for Azure Active Directory Management

The `AAD mgmt` Service Principal will be used for the management of the identities required for [Cloud-native Foundation Platform](/Foundation-Design.md) and [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).

**Azure Active Directory RBAC**

The `Governance mgmt` Service Principal will be assigned with the following Roles in Azure Active Directory following the least-privilege principle and leveraging [built-in AAD roles](https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference).
- [`Cloud Application Administrator`](https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#cloud-application-administrator). This role grants the ability to create and manage all aspects of enterprise applications and application registrations. This role also grants the ability to consent to delegated permissions, and application permissions excluding `Microsoft Graph` and `Azure AD Graph`. Required to create all Service Principals provisioned for [Cloud-native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).
- [Privileged Role Administrator](https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#privileged-role-administrator). Users with this role can manage role assignments in Azure Active Directory, as well as within Azure AD Privileged Identity Management. <span style="color:red;">Important: this role grants the ability to manage assignments for all Azure AD roles including the Global Administrator role. This role does not include any other privileged abilities in Azure AD like creating or updating users. However, users assigned to this role can grant themselves or others additional privilege by assigning additional roles.</span> Required to grant `Microsoft Graph` and `Azure AD Graph` permissions to Service Principals provisioned for [Cloud-native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).
- [Groups Administrator](https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#groups-administrator). Users with this role can manage role assignments in Azure Active Directory, as well as within Azure AD Privileged Identity Management. Users in this role can create/manage groups and its settings like naming and expiration policies. Required to create and manage all Active Directory Groups provisioned for [Cloud-native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).

### Service Principals for Cloud-native Landing Zones

The Service Principal provisioned for [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md) will be used by each Landing Zone Team for the management of the Workloads they are responsible for.

The following set of Service Principals are created for each Cloud-Native Landing Zone:
- `LZ Sandbox` Service Principal to manage workloads in the Landing Zone Sandbox subscription.
- `LZ Non-Production` Service Principal to manage workloads in the Landing Zone Non-Production subscriptions.
- `LZ UAT` Service Principal to manage workloads in the Landing Zone UAT subscription.
- `LZ Production` Service Principal to manage workloads in the Landing Zone Production subscription.

**Azure RBAC**

The Service Principals for Cloud-native Landing Zones will be assigned with permissions at different levels using Custom Roles following the least-privilege principle. See the section [Governance](/Foundation-Design/Governance.md) for more details on this configuration.

**Azure Active Directory RBAC**

The Service Principals for Cloud-native Landing Zones will be assigned with the following permissions in Azure Active Directory following the least-privilege principle and leveraging API Permissions.
- [Microsoft Graph](https://docs.microsoft.com/en-us/graph/permissions-reference).
  - [`Directory permissions (Application)`](https://docs.microsoft.com/en-us/graph/permissions-reference#application-permissions-20).
    - `Directory.Read.All`
- [Windows Azure Active Directory](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent). 
  - `Read directory data (Application)`.
    -  `Directory.Read.All`

## Active Directory Groups Strategy

Azure Active Directory (Azure AD) lets you use [Groups](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-manage-groups) to manage access to your cloud-based apps and your resources.

- Groups for users will be used to manage access to Azure DevOps Projects, which are connected via [Service Connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml) to the Azure Environment. See section [Azure DevOps Organization](/Foundation-Design/Azure-DevOps-Organization.md).
- Groups for users will be used to manage access to Azure Resources
- Groups for administrators will be used to elevate access to special configurations, resources or environments via [Privileged Identity Management (PIM)](#privileged-identity-management).

### Groups for CCoE

The Groups for CCoE will be used for access to the pipelines and code that will allow to deploy and manage [Cloud-native Foundation Platform](/Foundation-Design.md) and [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md):
- `CCoE Contr` Group is used to grant the required access to CCoE members to the Azure DevOps Project and to Azure resources.
- `CCoE Admins` Group is used to grant privileged access approved via PIM to CCoE members to the Azure DevOps Organization. **This group only contains admin accounts.**
- `CCoE Readers` Group is used to grant read access to the CCoE Azure DevOps Project.

**Azure DevOps RBAC**

- See section [Building-blocks Project](/Foundation-Design/Azure-DevOps-Organization/Building%2Dblocks-Project.md) for access at project level.
- See section [Azure DevOps Organization](/Foundation-Design/Azure-DevOps-Organization.md) for access at organization level.

**Azure RBAC**

- See section [Governance](/Foundation-Design/Governance.md) for access to Azure Governance resources.
- See section [Management and monitoring](/Foundation-Design/Management-and-monitoring.md) for access to Azure Management resources.

### Groups for Cloud-native Landing Zone Teams

The Groups for Cloud-native Landing Zone Teams will be used for access to the pipelines and code that will allow to deploy and manage workloads to [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md):
- `LZ Team Contr` Group is used to grant the required access to LZ Team members to the [Azure DevOps Project](Azure-DevOps-Organization/Landing-Zone-Team-Project.md) and to the [Cloud-Native Landing Zone](/Foundation-Design/Cloud%2DNative-Landing-Zone.md) Azure Resources.
- `LZ Team Admins` Group is used to grant privileged access approved via PIM to LZ Team members to the [Azure DevOps Project](Azure-DevOps-Organization/Landing-Zone-Team-Project.md) and to the [Cloud-Native Landing Zone](/Foundation-Design/Cloud%2DNative-Landing-Zone.md) Azure Resources. **This group only contains admin accounts.**
- `LZ Team Readers` Group is used to gran read access to the LZ Team [Azure DevOps Project](Azure-DevOps-Organization/Landing-Zone-Team-Project.md).

**Azure DevOps RBAC**

- See section [Landing Zone Project](/Foundation-Design/Azure-DevOps-Organization/Landing-Zone-Team-Project.md) for access at project level.

**Azure RBAC**

- See section [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md) for access to Azure resources.

# Planned work

::: query-table 1e24bd98-c12f-40a4-9dd6-370691ae759d
:::

# Configuration details

## Azure Active Directory Groups

| Representing   | Resource                    | IaC module used                                                                                                | Configuration file in Repo                                                                                                                                                                                                     | Deployment pipeline                                                                                                                        | Link to resource                                                                                                                                             |
| -------------- | --------------------------- | -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `CCoE Admins`  | grp-ccoe-devops-admin       | [aadgroup-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Faadgroup%2F1.0) | [Platform/teams/ccoe/parameters/aadgroup/grp-ccoe-devops-admin.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fteams%2Fccoe%2Fparameters%2Faadgroup%2Fgrp-ccoe-devops-admin.json)             | [Platform/teams/ccoe/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fteams%2Fccoe%2Fpipeline.yml) | [grp-ccoe-devops-admin](https://portal.azure.com/#blade/Microsoft_AAD_IAM/GroupDetailsMenuBlade/Overview/groupId/12522564-c546-4b31-b88e-4f87512b051b)       |
| `CCoE Contr`   | grp-ccoe-devops-contributor | [aadgroup-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Faadgroup%2F1.0) | [Platform/teams/ccoe/parameters/aadgroup/grp-ccoe-devops-contributor.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fteams%2Fccoe%2Fparameters%2Faadgroup%2Fgrp-ccoe-devops-contributor.json) | [Platform/teams/ccoe/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fteams%2Fccoe%2Fpipeline.yml) | [grp-ccoe-devops-contributor](https://portal.azure.com/#blade/Microsoft_AAD_IAM/GroupDetailsMenuBlade/Overview/groupId/cf61a428-7cb8-4048-977e-d8a9201a5855) |
| `CCoE Readers` | grp-ccoe-devops-reader      | [aadgroup-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Faadgroup%2F1.0) | [Platform/teams/ccoe/parameters/aadgroup/grp-ccoe-devops-reader.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fteams%2Fccoe%2Fparameters%2Faadgroup%2Fgrp-ccoe-devops-reader.json)           | [Platform/teams/ccoe/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fteams%2Fccoe%2Fpipeline.yml) | [grp-ccoe-devops-reader](https://portal.azure.com/#blade/Microsoft_AAD_IAM/GroupDetailsMenuBlade/Overview/groupId/b1d83a4f-a09a-45d2-a740-e3d7918e73cd)      |

## Service Principals

| Representing      | Resource                                              | IaC module used                                                                                                                      | Configuration file in Repo                                                                                                                                                                                                                                                                               | Deployment pipeline                                                                                                                                                                              | Link to resource                                                                                                                                                                                         |
| ----------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Governance mgmt` | pxs-buildingblocks-buildingblocks-d-mg-sp             | [aadserviceprincipal-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Faadserviceprincipal%2F1.0) | [Platform/teams/ccoe/parameters/aadserviceprincipal/pxs-buildingblocks-buildingblocks-d-mg-sp.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fteams%2Fccoe%2Fparameters%2Faadserviceprincipal%2Fpxs-buildingblocks-buildingblocks-d-mg-sp.json)                         | [Platform/teams/ccoe/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fteams%2Fccoe%2Fpipeline.yml)                                                       | [pxs-buildingblocks-buildingblocks-d-mg-sp](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/e8f3fab3-2fb0-471f-8d9a-9454eaf284d4/isMSAApp/)             |
| `AAD mgmt`        | pxs-buildingblocks-buildingblocks-p-aad-automation-sp | [aadserviceprincipal-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Faadserviceprincipal%2F1.0) | [Platform/teams/ccoe/parameters/aadserviceprincipal/pxs-buildingblocks-buildingblocks-p-aad-automation-sp.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fteams%2Fccoe%2Fparameters%2Faadserviceprincipal%2Fpxs-buildingblocks-buildingblocks-p-aad-automation-sp.json) | [Platform/teams/ccoe/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fteams%2Fccoe%2Fpipeline.yml)                                                       | [pxs-buildingblocks-buildingblocks-p-aad-automation-sp](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/7eafa4c5-9e5f-41a2-87ec-938414b62b36/isMSAApp/) |
| `Governance mgmt` | pxs-mgmt-p-log-sub-sp                                 | [aadserviceprincipal-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Faadserviceprincipal%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/parameters/aadserviceprincipal/pxs-mgmt-p-log-sub-sp.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fparameters%2Faadserviceprincipal%2Fpxs-mgmt-p-log-sub-sp.json)             | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpipeline.yml)   | [pxs-mgmt-p-log-sub-sp](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/67a9179d-5d01-4846-9a1e-0f1fd5fe15ec/isMSAApp/)                                 |
| `Governance mgmt` | pxs-mgmt-p-ccoe-sub-sp                                | [aadserviceprincipal-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Faadserviceprincipal%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-ccoe-sub/parameters/aadserviceprincipal/pxs-mgmt-p-ccoe-sub-sp.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-ccoe-sub%2Fparameters%2Faadserviceprincipal%2Fpxs-mgmt-p-ccoe-sub-sp.json)         | [Platform/pxs-management-mg/pxs-mgmt-p-ccoe-sub/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-ccoe-sub%2Fpipeline.yml) | [pxs-mgmt-p-ccoe-sub-sp](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/23013205-5032-47cf-9481-c4dafb24fb15/isMSAApp/)                                |

## Service connections

| Representing      | Resource            | IaC module used                                                                                                                  | Configuration file in Repo                                                                                                                                                                                                                                           | Deployment pipeline                                                                                                                                                                              | Link to resource                                                                                                                                    |
| ----------------- | ------------------- | -------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Governance mgmt` | pxs-cloudnative-mg  | [serviceconnection-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fserviceconnection%2F1.0) | [Platform/pxs-cloudnative-mg/parameters/serviceconnection/pxs-cloudnative-mg.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2Fserviceconnection%2Fpxs-cloudnative-mg.json)                         | [Platform/pxs-cloudnative-mg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpipeline.yml)                                         | [pxs-cloudnative-mg](https://dev.azure.com/contoso-azure/building-blocks/_settings/adminservices?resourceId=6a692aee-5503-418e-b966-dd081465997a)  |
| `AAD mgmt`        | aad-Automation      | [serviceconnection-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fserviceconnection%2F1.0) | [Platform/teams/ccoe/parameters/serviceconnection/aad-automation.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fteams%2Fccoe%2Fparameters%2Fserviceconnection%2Faad-automation.json)                                               | [Platform/teams/ccoe/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fteams%2Fccoe%2Fpipeline.yml)                                                       | [aad-Automation](https://dev.azure.com/contoso-azure/building-blocks/_settings/adminservices?resourceId=24f977f7-68bb-4b74-8f63-6441e614f6e9)      |
| `Governance mgmt` | pxs-mgmt-p-log-sub  | [serviceconnection-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fserviceconnection%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/parameters/serviceconnection/parameters.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fparameters%2Fserviceconnection%2Fparameters.json)   | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpipeline.yml)   | [pxs-mgmt-p-log-sub](https://dev.azure.com/contoso-azure/building-blocks/_settings/adminservices?resourceId=0dadd793-0492-435b-b277-17eb1e660380)  |
| `Governance mgmt` | pxs-mgmt-p-ccoe-sub | [serviceconnection-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fserviceconnection%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-ccoe-sub/parameters/serviceconnection/parameters.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-ccoe-sub%2Fparameters%2Fserviceconnection%2Fparameters.json) | [Platform/pxs-management-mg/pxs-mgmt-p-ccoe-sub/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-ccoe-sub%2Fpipeline.yml) | [pxs-mgmt-p-ccoe-sub](https://dev.azure.com/contoso-azure/building-blocks/_settings/adminservices?resourceId=f2b51c56-9355-45f3-877e-04f450e1fc78) |
