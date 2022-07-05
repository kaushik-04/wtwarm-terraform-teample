[[_TOC_]]
# Overview

[Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/user-guide/what-is-azure-devops?view=azure-devops) provides developer services to support teams to plan work, collaborate on code development, and build and deploy applications.

> Learn about Azure DevOps in section [Learning Resources > Azure > Azure DevOps](/Learning-resources/Azure/Azure-DevOps.md)

![Overview of Azure DevOps organization](/.attachments/images/Foundation-Design/platform-design-ado-organization.png)

> NOTE: the diagram can be modified using the Visio file on [Teams GRP MCS Cloud-native Engagement > Agile Delivery](https://teams.microsoft.com/_?lm=deeplink&lmsrc=homePageWeb&cmpid=WebSignIn#/conversations/Agile%20Delivery?threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&ctx=channel) > Files > [01 - Design Documents](https://contoso.sharepoint.com/sites/GRP_001608-AgileDelivery/Shared%20Documents/Forms/AllItems.aspx?RootFolder=%2Fsites%2FGRP%5F001608%2DAgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20%2D%20Design%20Documents&FolderCTID=0x01200001544C4EB547E84DB41D1C6FCCD4BEA9) > [PXS - Diagrams.vsdx](https://teams.microsoft.com/l/file/6F59E176-935C-450C-B8A0-A23AB3831B4C?tenantId=e7ab81b2-1e84-4bf7-9dcb-b6fec01ed138&fileType=vsdx&objectUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20-%20Design%20Documents%2FPXS%20-%20Diagrams.vsdx&baseUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery&serviceName=teams&threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&groupId=348f9039-5718-417a-8e56-85e2957e26be)

# Design decisions

## Organization strategy.

The current ADO architecture of contoso consists of **one organization and multiple projects**. Having one unique organization and multiple projects simplifies the access management and keeps everything centralized. For increasing jobs parallelization within the projects, it is possible to buy more jobs on demand.

## Azure Active Directory synchronization

- The current ADO organization is connected to the contoso directory to allow access only for contoso users.

## RBAC strategy

Azure DevOps is pre-configured with default [security groups](https://docs.microsoft.com/en-us/azure/devops/organizations/security/about-security-identity?view=azure-devops#security-groups-and-permissions). Default permissions are assigned to the default security groups. You can populate these groups by using individual users. However, for ease of management, it's easier if you populate these groups by using Azure AD or AD security groups. This method enables you to manage group membership and permissions more efficiently across multiple computers.

Azure DevOps controls access through these three inter-connected functional areas:
- **Membership management** supports adding individual Windows user accounts and groups to default security groups. Also, you can create Azure DevOps security groups. Each default group is associated with a set of default permissions. All users added to any security group are added to the Valid Users group. A valid user is someone who can connect to the project.
- **Permission management** controls access to specific functional tasks at different levels of the system. Object-level permissions set permissions on a file, folder, build pipeline, or a shared query. Permission settings correspond to Allow, Deny, Inherited allow, Inherited deny, and Not set. To learn more about inheritance, see About permissions and groups.
- **Access level management** controls access to features provided via the web portal, the web application for Azure DevOps. Based on what has been purchased for a user, administrators set the user's access level to Basic, VS Enterprise (previously Advanced), or Stakeholder.

Each functional area uses groups to simplify management across the deployment. You add users and groups through the web administration context. Permissions are automatically set based on the security group that you add users to, or based on the object, project, collection, or server level to which you add groups. On the other hand, access level management controls access for all users and groups at the server level.

![Azure DevOps Control Access](/.attachments/images/Foundation-Design/azure-devops-control-access.png)

### Organization Owner

The organization owner can provide permissions at any level within the organization or project.

- The [`CCoE Admins` AAD Group](/Foundation-Design/Identity-and-access-management.md) will become Organization Owner. Members of this team will only be allowed to make changes via PIM.

### Organization-level Security Groups

When you create an organization or project collection in Azure DevOps, the system creates [collection-level groups](https://docs.microsoft.com/en-us/azure/devops/organizations/security/permissions?view=azure-devops&tabs=preview-page#collection-level-groups) that have permissions in that collection. You can not remove or delete the built-in collection-level groups.

The following Groups are used to manage permissions at organization level:

| Group name | Permissions | Membership | RBAC Strategy
| - | - | - | -
| Project Collection Administrators | Has permissions to perform all operations for the collection. | Contains the Local Administrators group (BUILTIN\Administrators) for the server where the application-tier services have been installed. Also, contains the members of the CollectionName/Service Accounts group. **This group should be restricted to the smallest possible number of users who need total administrative control over the collection**. For Azure DevOps, assign to administrators who customize work tracking. | [`CCoE Admins` AAD Group](/Foundation-Design/Identity-and-access-management.md). Members of this team will only be allowed to make changes via PIM.<br/>[`building-blocks Build Service (contoso-azure)`](#service-accounts). This Service Account will be used to configure ADO Projects via Infrastructure as Code
| Project Collection Build Administrators | Has permissions to administer build resources and permissions for the collection. | Limit this group to the smallest possible number of users who need total administrative control over build servers and services for this collection. | Leave default configuration
| Project Collection Build Service Accounts | Has permissions to run build services for the collection. | Limit this group to service accounts and groups that contain only service accounts. This is a legacy group used for XAML builds. Use the Project Collection Build Service ({your organization}) user for managing permissions for current builds. | Leave default configuration
| Project Collection Proxy Service Accounts | Has permissions to run the proxy service for the collection. | Limit this group to service accounts and groups that contain only service accounts. | Leave default configuration
| Project Collection Service Accounts | Has service level permissions for the collection and for Azure DevOps Server. | Contains the service account that was supplied during installation. This group should contain only service accounts and groups that contain only service accounts. By default, this group is a member of the Administrators group. | Leave default configuration
| Project Collection Test Service Accounts | Has test service permissions for the collection. | Limit this group to service accounts and groups that contain only service accounts. | Leave default configuration
| Project Collection Valid Users | Has permissions to access team projects and view information in the collection. | Contains all users and groups that have been added anywhere within the collection. You cannot modify the membership of this group. | Leave default configuration
| Security Service Group | Used to store users who have been granted permissions, but not added to any other security group. | Don't assign users to this group. If you are removing users from all security groups, check if you need to remove them from this group. | Leave default configuration

### Service Accounts

At run-time, each job in a pipeline may access other resources in Azure DevOps. For example, a job may:
- Check out source code from a Git repository
- Add a tag to the repository
- Access a feed in Azure Artifacts
- Upload logs from the agent to the service
- Upload test results and other artifacts from the agent to the service
- Update a work item

Azure Pipelines uses job access tokens to perform these tasks. A [job access token](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/access-tokens?view=azure-devops&tabs=yaml) is a security token that is dynamically generated by Azure Pipelines for each job at run time. The agent on which the job is running uses the job access token in order to access these resources in Azure DevOps. You can control which resources your pipeline has access to by controlling how permissions are granted to job access tokens.

Azure DevOps uses two built-in identities to execute pipelines.

- A **collection-scoped identity**, which has access to all projects in the collection (or organization for Azure DevOps Services). The collection-scoped identity name has the following format:
  - `Project Collection Build Service ({OrgName})`
- A project-scoped identity, which has access to a single project. The project-scoped identity name has the following format:
  - `{Project Name} Build Service ({Org Name})`

The token's permissions are derived from:
1. Job [authorization scope](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/access-tokens?view=azure-devops&tabs=classic#job-authorization-scope) 
2. The [permissions set on project or collection build service account](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/access-tokens?view=azure-devops&tabs=classic#manage-build-service-account-permissions).


The following decisions will affect Service Accounts:
- For contoso, [job authorization scope will have the scope of access limited to current project](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/access-tokens?view=azure-devops&tabs=classic#job-authorization-scope) for non-release and release pipelines (Organization settings > Pipelines > Settings).
- If any project-scoped identity may not have permissions to a resource, additional access can be granted with the following considerations:
  - The build service account on which you can manage permissions will only be created after you run the pipeline once. Make sure that you already ran the pipeline once.
  - Select Manage security in the overflow menu on Pipelines page.
  - Under Users, select Your-project-name Build Service (your-collection-name).
  - Make any changes to the pipelines-related permissions for this account.
  - Navigate to organization settings for your Azure DevOps organization (or collection settings for your project collection).
  - Select Permissions under Security.
  - Under the Users tab, look for Your-project-name build service (your-collection-name).
  - Make any changes to the non-pipelines-related permissions for this account.
  - Since Your-project-name Build Service (your-collection-name) is a user in your organization or collection, you can add this account explicitly to any resource - for e.g., to a feed in Azure Artifacts.
- Service Account for [Building-blocks project](/Foundation-Design/Azure-DevOps-Organization/Building%2Dblocks-Project.md) will belong to Project Collection Administrator Group 


## Projects Strategy

[Azure DevOps Projects](https://docs.microsoft.com/en-us/azure/devops-project/overview) makes it easy to get started on Azure. It allows to deploy and manage Azure services via code in just a few quick steps.

- One project owned by the CCoE will be used for the management of the [Foundation Platform](/Foundation-Design.md) via Azure DevOps Pipelines and Service Connections. See [Building-blocks project](/Foundation-Design/Azure-DevOps-Organization/Building%2Dblocks-Project.md)
- One project will be provisioned for each team responsible of a [Cloud-Native Landing Zone](/Foundation-Design/Cloud%2DNative-Landing-Zone.md). See [Landing Zone Team project](/Foundation-Design/Azure-DevOps-Organization/Landing-Zone-Team-Project.md)

## Monitoring

[Audit logs](https://docs.microsoft.com/en-us/azure/devops/organizations/audit/azure-devops-auditing?view=azure-devops&tabs=preview-page) contain many changes that occur throughout an Azure DevOps organization. Changes occur when a user or service identity within the organization edits the state of an artifact. Audit events can be the following occurrences:
- permissions changes
- deleted resources
- branch policy changes
- accessing the auditing feature
- and much more

Auditing is turned on by default for all Azure DevOps Services organizations. You can't turn auditing off, which ensures that you never miss an actionable event. Events get stored for 90 days and then they’re deleted.

We will configure Audit streaming for Azure DevOps to the management environment. Audit streams represent a pipeline that flows audit events from your Azure DevOps organization to a stream target. Every half hour or less, new audit events are bundled and streamed to your targets. Currently, the following stream targets are available for configuration:
- [Splunk](https://docs.microsoft.com/en-us/azure/devops/organizations/audit/auditing-streaming?view=azure-devops#set-up-a-splunk-stream) – Connect to on-premises or cloud-based Splunk.
- [Azure Monitor Log](https://docs.microsoft.com/en-us/azure/devops/organizations/audit/auditing-streaming?view=azure-devops#set-up-an-azure-monitor-log-stream) - Send auditing logs to Azure Monitor Logs. Logs stored in Azure Monitor Logs can be queried and have alerts configured. Look for the table named AzureDevOpsAuditing. You can also connect Azure Sentinel to your workspace.
- [Azure Event Grid](https://docs.microsoft.com/en-us/azure/devops/organizations/audit/auditing-streaming?view=azure-devops#set-up-an-event-grid-stream) – For scenarios where you want your auditing logs to be sent somewhere else, whether inside or outside of Azure, you can set up an Azure Event Grid connection.

The contoso Azure DevOps Organization will send logs to the Log Analytics in the Management Subscription. See [Management and monitoring](/Foundation-Design/Management-and-monitoring.md).

# Planned work

::: query-table a1474b0c-bef6-413e-986d-d6e1e9ab53c3
:::

# Configuration details

## Azure DevOps Organization

| Resource | Purpose | Configuration file in Repo | Deployment pipeline | Link to resource
| - | - | - | - | -
| https://dev.azure.com/contoso-azure | Azure DevOps organization to host all projects following the Cloud-Native Landing Zone approach | n/a | n/a | [https://dev.azure.com/contoso-azure/](https://dev.azure.com/contoso-azure/)

## Azure Active Directory Synchronization

| Resource | Purpose | Configuration file in Repo | Deployment pipeline | Link to resource
| - | - | - | - | -
| Azure Active Directory synchronization | The Azure DevOps Organization is connected to the contoso directory so that only members of contoso AD can access Azure DevOps | n/a | n/a | [https://dev.azure.com/contoso-azure/_settings/organizationAad](https://dev.azure.com/contoso-azure/_settings/organizationAad)

## Organization Owner

| Resource | Purpose | Configuration file in Repo | Deployment pipeline | Link to resource
| - | - | - | - | -
| `https://dev.azure.com/contoso-azure`/ | Has permissions to administer the entire organization and projects. [`CCoE Admins` AAD Group](/Foundation-Design/Identity-and-access-management.md). Members of this team will only be allowed to make changes via PIM. | n/a | n/a | [https://dev.azure.com/contoso-azure/](https://dev.azure.com/contoso-azure/_settings/organizationOverview)

## Organization-level Permissions

Permissions settings: [https://dev.azure.com/contoso-azure/_settings/groups](https://dev.azure.com/contoso-azure/_settings/groups)

| Resource | Purpose | Configuration file in Repo | Deployment pipeline | Link to resource
| - | - | - | - | -
| `[contoso-azure]\Project Collection Administrators` | Has permissions to perform all operations for the collection. [`CCoE Admins` AAD Group](/Foundation-Design/Identity-and-access-management.md). Members of this team will only be allowed to make changes via PIM. | n/a | n/a | [[contoso-azure]\Project Collection Administrators](https://dev.azure.com/contoso-azure/_settings/groups?subjectDescriptor=vssgp.Uy0xLTktMTU1MTM3NDI0NS04NjYzMjM1MTItMTE2NjA5MTg0My0yOTE4NDg1OTI0LTk2ODI3NTk5MS0wLTAtMC0wLTE)

## Azure DevOps Projects

| Resource | Purpose | Configuration file in Repo | Deployment pipeline | Link to resource
| - | - | - | - | -
| `https://dev.azure.com/contoso-azure/building-blocks` | Team Project for management of [Cloud-native Foundational Platform](/Foundation-Design.md), [Cloud Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md) and [Certified Components](/Certified-Components.md). See section [Building-blocks Project](/Foundation-Design/Azure-DevOps-Organization/Building%2Dblocks-Project.md) | n/a | n/a | [https://dev.azure.com/contoso-azure/building-blocks](https://dev.azure.com/contoso-azure/building-blocks)
| `https://dev.azure.com/contoso-azure/bdp-platform` | Team Project for management of Landing Zone of the Data Platform Team. See section [Landing Zone Team](/Foundation-Design/Azure-DevOps-Organization/Landing-Zone-Team-Project.md) | n/a | n/a | [https://dev.azure.com/contoso-azure/building-blocks](https://dev.azure.com/contoso-azure/building-blocks)