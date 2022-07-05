[[_TOC_]]

# Overview

Management Group (MG) structure within an Azure AD Tenant supports organizational mapping to efficiently manage access, policies, and compliance for multiple Subscriptions. 
Subscriptions (and MGs too) can be organized into containers called MGs and governance conditions can be applied to the MGs such that all child MGs, Subscriptions and resources within the parent MG automatically inherit the conditions applied to the parent MG.
The contoso Management structure implemented in the context of this project is visualized below.

![Overview of Azure Governance](/.attachments/images/Foundation-Design/platform-design-governance.png)

> NOTE: the diagram can be modified using the Visio file on Teams GRP MCS Cloud-native Engagement > Agile Delivery > Files > [01 - Design Documents](https://contoso.sharepoint.com/sites/GRP_001608-AgileDelivery/Shared%20Documents/Forms/AllItems.aspx?RootFolder=%2Fsites%2FGRP%5F001608%2DAgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20%2D%20Design%20Documents&FolderCTID=0x01200001544C4EB547E84DB41D1C6FCCD4BEA9) > [PXS - Diagrams.vsdx](https://teams.microsoft.com/l/file/6F59E176-935C-450C-B8A0-A23AB3831B4C?tenantId=e7ab81b2-1e84-4bf7-9dcb-b6fec01ed138&fileType=vsdx&objectUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20-%20Design%20Documents%2FPXS%20-%20Diagrams.vsdx&baseUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery&serviceName=teams&threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&groupId=348f9039-5718-417a-8e56-85e2957e26be)

Design recommendations:
- Keep Management Group structure as flat as possible. Management groups should be used to group similar subscriptions to ensure governance and compliance.
- Enforce company-wide policies from Cloud Native management group level to ensure basic governance. Add additional policies on lower-level management groups.
- Create management groups based on environment type, its requirements, and data sensitivity.
- All new subscription should be placed under management group to inherit governance, permission and compliance settings.
- All Landing Zones and subscriptions should be created via automation (IaC)
- All management groups and subscriptions should be created and managed by CCoE Foundation team.
- Use “environment” and “application ID” tags for each resource to enable cost per application per environment.
- Enforce tagging on each environment.
- Use Azure environment level policies in deny mode in production, at least audit mode in non-prod and sandbox to gain visibility on governance and compliance.
- Cloud Native level policies should be deployed and managed only by CCoE foundation team. Additional policies can be applied on a subscription level, but Cloud Native level policies cannot be removed by the CCoE platform team.

## Management Groups

Management Group (MG) structure within an Azure AD Tenant supports organizational mapping to efficiently manage access, policies, and compliance for multiple Subscriptions. 

Each Azure AD Tenant is given a single top-level MG called the ‘Tenant Root Group’. This root MG is built into the hierarchy to have all MGs and Subscriptions fold up to it. This root MG allows for Azure Policies and RBAC assignments to be applied at the directory level.

No one is given default access to the root management group. Azure AD Global Administrators are the only users that can elevate themselves to gain access (including the break-glass accounts). Once they have access to the root MG, the global administrators can assign any RBAC role to other users to manage it. A MG tree can support up to six levels of depth. This limit does not include the root or Subscription level.

MGs will help to build a flexible structure of Subscriptions to organize resources into a hierarchy for unified policy and access management. For example, a Policy can be applied to a MG that limits the regions available for VM creation. This policy would be applied to all MGs, Subscriptions, and resources under that MG by only allowing VMs to be created in that region. Another scenario is to provide user access to multiple Subscriptions by assigning RBAC role on the MG, which will inherit that access to all the Subscriptions. 

**When to create Management Groups?**

Different requirements on the following criteria:
- Delegation of access (control layer)
- Configuration and compliance (with Policies)
  - Including automatic deployment of resources with policies that have “deployIfNotExist” effects.

**Management groups and landing zones**

When the existing LZ (Landing Zone) types no longer support the need of a type of workload or scenario of usage, a new management group can be created to support the different needs under the “Cloud-Native” management group. On this management group all the required policies can be set through Azure Policy (by assigning policy or initiatives). Company wide policies can be applied from MG root level to apply on all MG below the root MG. Additional policies can be applied or exclude (e.g. Sandbox) depending on the data handled in the environment.

Having multiple LZs, contoso needs a way to efficiently manage access, policies, and compliance for those LZs. Azure Management Groups provide a level of scope above individual LZs (subscriptions). contoso organizes LZs into Management Groups based on the environment type of a Landing Zone: Production, Non-production, and Sandbox. Individual LZ can be excluded from certain Management Group governance conditions if required. All subscriptions within a management group automatically inherit the conditions applied to the management group. 

## Subscriptions

Subscriptions are a unit of management, billing, and scale within Azure, and play a critical role when designing for Azure adoption. Subscriptions provide a management boundary for governance and isolation, creating a clear separation of concerns. Adopting Azure begins by creating an Azure Subscription which serves as a container for Azure resources. Each resource in Azure, such as a virtual machine or virtual network, is contained within a Subscription. When a resource is created, an Azure subscription is also chosen to deploy that resource to.

Multiple Subscriptions can be created to separate workloads by financial and administration logic. A Subscription has a trust relationship with Azure AD Tenant to authenticate users, services, and devices. Multiple subscriptions can trust the same Azure AD directory while each Subscription can only trust a single directory. A subscription isn’t tied to a specific Azure region. However, each Azure resource is deployed to only one region. Resources can be created in multiple regions within the same Subscription.

**When to create a Subscription?**
- Container of resource groups, and as a child of a management groups.
- Unit of scale so that component workloads can scale within the platform subscription limits. Make sure to consider subscription resource limits during your workload design.
- Management boundary for governance and isolation, which creates a clear separation of concerns.

# Design decisions

## RBAC custom Roles

[Custom roles](https://docs.microsoft.com/en-us/azure/role-based-access-control/custom-roles) allow to follow the principle of least privilege by creating RBAC roles with only the Resource Provider Operations needed.

### Governance Management

This custom role will allow the `Governance Mgmt` Service Principal used by the CCoE via DevOps Pipelines to deploy and manage all Azure resources related to the [Cloud-Native Foundation Platform](/Foundation-Design.md) and to the deployment of [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md). This includes:
- Management of Cloud-Native Management Groups and child Subscriptions, including:
  -  Cloud-Native MG and child subscriptions
  -  Cloud-Native Management MG
  -  Sandbox MG and child Subscriptions
  -  Non-Production MG and child Subscriptions
  -  Production MG and child Subscriptions
-  Management of Policies
-  Management of RBAC

| [Resource Provider Operation](https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations) | Action type | Purpose                                            |
| ---------------------------------------------------------------------------------------------------------------------------- | ----------- | -------------------------------------------------- |
| `*/read`                                                                                                                     | `action`    | Read all components in Azure under the scope       |
| `Microsoft.Authorization/*`                                                                                                  | `action`    | Manage policy and roles                            |
| `Microsoft.Management/*`                                                                                                     | `action`    | Manage all aspects of Management Groups            |
| `"Microsoft.PolicyInsights/*"`                                                                                               | `action`    | Manage compliance and remediation in Azure Policy  |
| `Microsoft.Subscription/*`                                                                                                   | `action`    | Manage all aspects of subscriptions                |
| `*/register/action`                                                                                                          | `action`    | Registers resource providers within a subscription |
### Landing Zone Owner

This custom role will allow Service Principal from Landing Zone Teams manage the workloads they are responsible for in their [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).

| [Resource Provider Operation](https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations) | Action type | Purpose                                                                                                  |
| ---------------------------------------------------------------------------------------------------------------------------- | ----------- | -------------------------------------------------------------------------------------------------------- |
| `*`                                                                                                                          | `action`    | Allow all resource provider operations                                                                   |
| `Microsoft.Subscription/*`                                                                                                   | `notAction` | Prevents from modifying subscription configuration                                                       |
| `Microsoft.Authorization/policyAssignments/write`                                                                            | `notAction` | Prevents from create a policy assignment at the specified scope.                                         |
| `Microsoft.Authorization/policyAssignments/*/write`                                                                          | `notAction` | Prevents from write operations related to Policy Assignments                                             |
| `Microsoft.Authorization/policyAssignments/delete`                                                                           | `notAction` | Prevents from delete a policy assignment at the specified scope                                          |
| `Microsoft.Authorization/policyAssignments/*/delete`                                                                         | `notAction` | Prevents from delete operations related to Policy Assignments                                            |
| `Microsoft.Authorization/policyDefinitions/write`                                                                            | `notAction` | Prevents from create a custom policy definition                                                          |
| `Microsoft.Authorization/policyDefinitions/delete`                                                                           | `notAction` | Prevents from delete a policy definition                                                                 |
| `Microsoft.Authorization/policySetDefinitions/write`                                                                         | `notAction` | Prevents from create a custom policy set definition                                                      |
| `Microsoft.Authorization/policySetDefinitions/delete`                                                                        | `notAction` | Prevents from delete a policy set definition                                                             |
| `Microsoft.Authorization/policyExemptions/write`                                                                             | `notAction` | Prevents from create a policy exemption at the specified scope                                           |
| `Microsoft.Authorization/policyExemptions/delete`                                                                            | `notAction` | Prevents from delete a policy exemption at the specified scope                                           |
| `Microsoft.Authorization/roleDefinitions/write`                                                                              | `notAction` | Prevents from create or update a custom role definition with specified permissions and assignable scopes |
| `Microsoft.Authorization/roleDefinitions/delete`                                                                             | `notAction` | Prevents from delete the specified custom role definition                                                |

## Management Groups

### Root-level Management Group

The Service Principal `Governance mgmt` owned by CCoE will manage Cloud-native Management Groups and subscriptions, so this Service Principal needs to have [`Microsoft.Resources/deployments`](https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsoftresources) permissions at root-level.

**RBAC**

- The Service Principal `Governance mgmt` owned by the CCoE will have the built-in role [`Automation Job Operator`](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#automation-job-operator) assigned. This role is required to get `Microsoft.Resources/deployments/*` action at root level so that new ARM deployments can be requested. ARM deployments are required at root level in order to create and manage Management Groups and Subscriptions.

### Cloud-native Management

The `Cloud-native Management` management group will be used to centralize logging and monitoring from [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).

The Service Principal `Governance mgmt` owned by CCoE will have permissions to manage this Management Group and all child Subscriptions.

**RBAC**

- The Service Principal `Governance mgmt` owned by the CCoE will have the following role assignments:
  - Custom role [`Governance Management`](#governance-management)
- The AAD Group `CCoE Contr` of the CCoE will have the following role assignments:
  - Built-in role `Reader`

### Cloud-native

The `Cloud-native` management group will be used to:
- Host all management groups and subscriptions from [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).
- Apply [Policies](#azure-policies) at cloud-native level that will apply to all cloud-native subscriptions
- Publish Custom Roles at Cloud-native level that can be assigned to any child resource

**RBAC**

- The Service Principal `Governance mgmt` owned by the CCoE will have the following role assignments:
  - Custom role [`Governance Management`](#governance-management)
- The AAD Group `CCoE Contr` of the CCoE will have the following role assignments:
  - Built-in role `Reader`

### Sandbox

The `Sandbox` management group will be used to host all sandbox subscriptions from [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).

This management group is a child management group from [Cloud-native](#cloud-native) and thus will inherit all RBAC and Policies assigned to the parent Management Group.

**RBAC**

No RBAC assignments are required at this Level

### Non-production

The `Non-production` management group will be used to host non-production subscription from [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).

This management group is a child management group from [Cloud-native](#cloud-native) and thus will inherit all RBAC and Policies assigned to the parent Management Group.

**RBAC**

No RBAC assignments are required at this Level

### Production

The `Production` management group will be used to host production subscriptions from [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).

This management group is a child management group from [Cloud-native](#cloud-native) and thus will inherit all RBAC and Policies assigned to the parent Management Group.

**RBAC**

No RBAC assignments are required at this Level

## Subscriptions

### Sandbox

One sandbox subscription can be provisioned for each Landing Zone team. See details in section [Cloud-native Landing Zone](/Foundation-Design/Cloud%2DNative-Landing-Zone.md). 

### Non-production

One or more non-production subscriptions can be provisioned for each Landing Zone team. See details in section [Cloud-native Landing Zone](/Foundation-Design/Cloud%2DNative-Landing-Zone.md). 

### Production

One production subscription will be provisioned for each Landing Zone team. See details in section [Cloud-native Landing Zone](/Foundation-Design/Cloud%2DNative-Landing-Zone.md). 

### Management

The management subscription will contain resources to centrally manage Landing-Zone workloads. See details in section [Management and monitoring](/Foundation-Design/Management-and-monitoring.md)

### Logging

The logging subscription will contain resources to centrally capture logs from Landing-Zone workloads. See details in section [Management and monitoring](/Foundation-Design/Management-and-monitoring.md)

## Azure Policies

This section describes the policies that have been set within Azure on a Management Group or Subscription level, so it applies to all child products or services, where it applies.

### Tenant root group policies policies
On the tenant root group scope the following policy/policies are in effect

| Control           | Description                                                                                                                                                        | Effect |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| Allowed locations | Locations are restricted through Resource Policies. These restrict the allowed locations at time of deployment. Allowed locations are west-europe and north-europe | Deny   |
### Cloud-native MG policies

These policies are deployed at Cloud-Native Management Group level and apply to all child resources

| Control                                                                     | Description                                                                                                                                                                                                                                                                                                                                                                                                   | Effect            |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| Restrict deployment locations                                               | Locations are restricted through Resource Policies. These restrict the allowed locations at time of deployment.                                                                                                                                                                                                                                                                                               | Deny              |
| Azure Security Center enabled                                               | Enable by default Azure Security Center on each subscription                                                                                                                                                                                                                                                                                                                                                  | DeployIfNotExists |
| Send activity and resource logs to Log Analytics in management subscription | All deployed resources will send [resource logs](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/resource-logs) and all the subscriptions will send [activity logs](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/activity-log) to the Log Analytic Workspace in the Management subscription (see [Management and monitoring](/Foundation-Design/Management-and-monitoring.md)) | DeployIfNotExists |
| Send resource logs to Landing Zone Log Analytics in logging subscription    | All deployed resources will send [resource logs](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/resource-logs) to their Landing Zone Log Analytic workspace in the Logging subscription (see [Management and monitoring](/Foundation-Design/Management-and-monitoring.md))                                                                                                                     | DeployIfNotExists |
| Send resource logs to Event Hub in logging subscription                     | All deployed resources will send [resource logs](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/resource-logs) to the Event Hub in the Logging subscription (see [Management and monitoring](/Foundation-Design/Management-and-monitoring.md))                                                                                                                                                 | DeployIfNotExists |
| Allowed resource types                                                      | A whitelist of allowed resource types. For the full list please see [Allowed resource types](https://dev.azure.com/contoso-azure/foundations/_git/foundation-automation?path=%2Fpolicy%2Fcustom-policies%2FallowedResoureTypes.json)                                                                                                                                                                         | Deny              |
| Identify uncompliant RBAC role assigned                                     | LZ Owner will allow LZ Teams to do assignments. This policy will help guarantee that all assignments are compliant                                                                                                                                                                                                                                                                                            | Audit             |


### Sandbox MG policies

These policies are deployed at Sandbox Management Group level and apply to all child resources

### Non-Production MG policies

These policies are deployed at Non-Production Management Group level and apply to all child resources

### Production MG policies

These policies are deployed at Production Management Group level and apply to all child resources

### Landing Zone Subscription policies

These policies are deployed during the creation of each Landing Zone and apply at subscription level to all child resources

# Planned work

::: query-table d2e58506-7563-4661-aec7-79b7535a7428
:::

# Configuration details

## Management Groups

| Representing              | Resource                         | Parent             | IaC module used                                                                                                              | Configuration file                                                                                                                                                                                                                                                          | Deployment pipeline                                                                                                                                                                            | Link to the deployed                                                                                                              |
| ------------------------- | -------------------------------- | ------------------ | ---------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `Cloud-native Management` | pxs-management-mg                | Tenant root group  | [managementgroup-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fmanagementgroup%2F1.0) | [Platform/pxs-management-mg/parameters/managementgroup/pxs-management-mg.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fparameters%2Fmanagementgroup%2Fpxs-management-mg.json)                                        | [Platform/pxs-management-mg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpipeline.yml)                                         | [pxs-management-mg](https://portal.azure.com/#blade/Microsoft_Azure_ManagementGroups/MenuBlade/overview/name/pxs-management-mg)   |
| `Cloud-native`            | pxs-cloudnative-mg               | Tenant root group  | [managementgroup-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fmanagementgroup%2F1.0) | [Platform/pxs-cloudnative-mg/parameters/managementgroup/pxs-cloudnative-mg.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2Fmanagementgroup%2Fpxs-cloudnative-mg.json)                                    | [Platform/pxs-cloudnative-mg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpipeline.yml)                                       | [pxs-cloudnative-mg](https://portal.azure.com/#blade/Microsoft_Azure_ManagementGroups/MenuBlade/overview/name/pxs-cloudnative-mg) |
| `Production`              | pxs-cn-p-mg                      | pxs-cloudnative-mg | [managementgroup-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fmanagementgroup%2F1.0) | [Platform/pxs-cloudnative-mg/pxs-cn-p-mg/parameters/managementgroup/pxs-cn-p-mg.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpxs-cn-p-mg%2Fparameters%2Fmanagementgroup%2Fpxs-cn-p-mg.json)                        | [Platform/pxs-cloudnative-mg/pxs-cn-p-mg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpxs-cn-p-mg%2Fpipeline.yml)             | [pxs-cn-p-mg](https://portal.azure.com/#blade/Microsoft_Azure_ManagementGroups/MenuBlade/overview/name/pxs-cn-p-mg)               |
| `Non-production`          | pxs-cn-n-mg                      | pxs-cloudnative-mg | [managementgroup-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fmanagementgroup%2F1.0) | [Platform/pxs-cloudnative-mg/pxs-cn-n-mg/parameters/managementgroup/pxs-cn-n-mg.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpxs-cn-n-mg%2Fparameters%2Fmanagementgroup%2Fpxs-cn-n-mg.json)                        | [Platform/pxs-cloudnative-mg/pxs-cn-n-mg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpxs-cn-n-mg%2Fpipeline.yml)             | [pxs-cn-n-mg](https://portal.azure.com/#blade/Microsoft_Azure_ManagementGroups/MenuBlade/overview/name/pxs-cn-n-mg)               |
| `Sandbox`                 | pxs-cn-s-mg                      | pxs-cloudnative-mg | [managementgroup-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fmanagementgroup%2F1.0) | [Platform/pxs-cloudnative-mg/pxs-cn-s-mg/parameters/managementgroup/pxs-cn-s-mg.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpxs-cn-s-mg%2Fparameters%2Fmanagementgroup%2Fpxs-cn-s-mg.json)                        | [Platform/pxs-cloudnative-mg/pxs-cn-s-mg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpxs-cn-s-mg%2Fpipeline.yml)             | [pxs-cn-s-mg](https://portal.azure.com/#blade/Microsoft_Azure_ManagementGroups/MenuBlade/overview/name/pxs-cn-s-mg)               |
|                           | *pxs-cn-sandbox-mg (deprecated)* | pxs-cloudnative-mg | [managementgroup-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fmanagementgroup%2F1.0) | [Platform/pxs-cloudnative-mg/pxs-cn-sandbox-mg/parameters/managementgrou/pxs-cn-sandbox-mg.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpxs-cn-sandbox-mg%2Fparameters%2Fmanagementgroup%2Fpxs-cn-sandbox-mg.json) | [Platform/pxs-cloudnative-mg/pxs-cn-sandbox-mg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpxs-cn-sandbox-mg%2Fpipeline.yml) | [pxs-cn-sandbox-mg](https://portal.azure.com/#blade/Microsoft_Azure_ManagementGroups/MenuBlade/overview/name/pxs-cn-sandbox-mg)   |

## RBAC role definitions and assignments

| Representing            | Resource                              | IaC module used                                                                                                              | Configuration file                                                                                                                                                                                                                                                             | Deployment pipeline                                                                                                                                      | Link to resource                                                                                                             |
| ----------------------- | ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `Governance Management` | Management Governance Administrator   | [roleDefinitions-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2FroleDefinitions%2F1.0) | [Platform/pxs-management-mg/parameters/roleDefinitions/Management-Governance-Administrator.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fparameters%2FroleDefinitions%2FManagement-Governance-Administrator.json)       | [Platform/pxs-management-mg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpipeline.yml)   | N/A                                                                                                                          |
|                         | pxs-management-mg - roleAssignments   | [managementgroup-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fmanagementgroup%2F1.0) | [Platform/pxs-management-mg/parameters/managementgroup/pxs-management-mg.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fparameters%2Fmanagementgroup%2Fpxs-management-mg.json)                                           | [Platform/pxs-management-mg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpipeline.yml)   | [pxs-management-mg](https://portal.azure.com/#blade/Microsoft_Azure_ManagementGroups/MenuBlade/iam/name/pxs-management-mg)   |
| `Governance Management` | Cloud Native Governance Administrator | [roleDefinitions-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2FroleDefinitions%2F1.0) | [Platform/pxs-cloudnative-mg/parameters/roleDefinitions/Cloud-Native-Governance-Administrator.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2FroleDefinitions%2FCloud-Native-Governance-Administrator.json) | [Platform/pxs-cloudnative-mg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpipeline.yml) | N/A                                                                                                                          |
| `LZ Owner`              | LZ Owner                              | [roleDefinitions-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2FroleDefinitions%2F1.0) | [Platform/pxs-cloudnative-mg/parameters/roleDefinitions/LZ-Owner.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpxs-cn-sandbox-mg%2Fparameters%2Froledefinition%2FLZ-Owner.json)                                        | [Platform/pxs-cloudnative-mg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpipeline.yml) | N/A                                                                                                                          |
|                         | pxs-cloudnative-mg - roleAssignments  | [managementgroup-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fmanagementgroup%2F1.0) | [Platform/pxs-cloudnative-mg/parameters/managementgroup/pxs-cloudnative-mg.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2Fmanagementgroup%2Fpxs-cloudnative-mg.json)                                       | [Platform/pxs-cloudnative-mg/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpipeline.yml) | [pxs-cloudnative-mg](https://portal.azure.com/#blade/Microsoft_Azure_ManagementGroups/MenuBlade/iam/name/pxs-cloudnative-mg) |

- `Governance Management` is deployed twice as the CCoE does not have ability to define and contole a custom role on a shared root. Hence it is deployed twice using seperate name and definitions.
## Management Subscriptions

| Resource              | IaC module used                                                                                                        | Configuration file in Repo                                                                                                                                                                                                                                                   | Deployment pipeline                                                                                                                                                                              | Link to resource                                                                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pxs-mgmt-p-ccoe-sub` | [subscription-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fsubscription%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-ccoe-sub/parameters/subscription/pxs-mgmt-p-ccoe-sub.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-ccoe-sub%2Fparameters%2Fsubscription%2Fpxs-mgmt-p-ccoe-sub.json) | [Platform/pxs-management-mg/pxs-mgmt-p-ccoe-sub/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-ccoe-sub%2Fpipeline.yml) | [pxs-mgmt-p-ccoe-sub](https://portal.azure.com/#@contoso.onmicrosoft.com/resource/subscriptions/38cc88c6-5c9c-4fd6-b332-ec5de508f048/overview) |
| `pxs-mgmt-p-log-sub`  | [subscription-1.0](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fsubscription%2F1.0) | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/parameters/subscription/pxs-mgmt-p-log-sub.json](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fparameters%2Fsubscription%2Fpxs-mgmt-p-log-sub.json)     | [Platform/pxs-management-mg/pxs-mgmt-p-log-sub/pipeline.yml](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-management-mg%2Fpxs-mgmt-p-log-sub%2Fpipeline.yml)   | [pxs-mgmt-p-log-sub](https://portal.azure.com/#@contoso.onmicrosoft.com/resource/subscriptions/94a25935-980f-4ffd-b710-7fb3bf986ae0/overview)  |  |  |  |  |

## Azure Policies

| Resource                   | IaC module used                                                                                                                          | Configuration file in Repo                                                                                                                                                                                                                        | Deployment pipeline                                                                                                                               | Link to resource                                                                                         |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `pxs-cn-roleassignment-pd` | [`policyDefinition-2.0`](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2FpolicyDefinition%2F2.0)         | [`pxs-cloudnative-mg/parameters/policyDefinitions/pxs-cn-roleassignment-pd.json`](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2FpolicyDefinitions%2Fpxs-cn-roleassignment-pd.json) | [`pxs-cloudnative-mg/pipeline.yml`](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpipeline.yml) | [Policy definitions](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Definitions) |
| `pxs-cn-rbac-pi`           | [`initiativeDefinition-2.0`](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2FinitiativeDefinition%2F2.0) | [`pxs-cloudnative-mg/parameters/initiativeDefinitions/pxs-cn-rbac-pi.json`](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2FinitiativeDefinitions%2Fpxs-cn-rbac-pi.json)             | [`pxs-cloudnative-mg/pipeline.yml`](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpipeline.yml) | [Policy definitions](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Definitions) |
| `pxs-cn-rbac-pa`           | [`policyAssignment-2.0`](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2FpolicyAssignment%2F2.0)         | [`pxs-cloudnative-mg/parameters/policyAssignments/pxs-cn-rbac-pa.json`](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2FpolicyAssignments%2Fpxs-cn-rbac-pa.json)                     | [`pxs-cloudnative-mg/pipeline.yml`](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpipeline.yml) | [Policy assignments](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Assignments) |
| `pxs-cn-deployasc-pd`      | [`policyDefinition-2.0`](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2FpolicyDefinition%2F2.0)         | [`pxs-cloudnative-mg/parameters/policyDefinitions/pxs-cn-deployasc-pd.json`](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2FpolicyDefinitions%2Fpxs-cn-deployasc-pd.json)           | [`pxs-cloudnative-mg/pipeline.yml`](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpipeline.yml) | [Policy definitions](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Definitions) |
| `pxs-cn-security-pi`       | [`initiativeDefinition-2.0`](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2FinitiativeDefinition%2F2.0) | [`pxs-cloudnative-mg/parameters/initiativeDefinitions/pxs-cn-security-pi.json`](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2FinitiativeDefinitions%2Fpxs-cn-security-pi.json)     | [`pxs-cloudnative-mg/pipeline.yml`](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpipeline.yml) | [Policy definitions](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Definitions) |
| `pxs-cn-security-pa`       | [`policyAssignment-2.0`](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2FpolicyAssignment%2F2.0)         | [`pxs-cloudnative-mg/parameters/policyAssignments/pxs-cn-security-pa.json`](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2FpolicyAssignments%2Fpxs-cn-security-pa.json)             | [`pxs-cloudnative-mg/pipeline.yml`](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fpipeline.yml) | [Policy assignments](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Assignments) |
