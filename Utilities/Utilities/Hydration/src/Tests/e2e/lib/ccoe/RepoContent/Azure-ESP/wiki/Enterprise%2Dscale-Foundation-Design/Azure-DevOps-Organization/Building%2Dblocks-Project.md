[[_TOC_]]

# Overview

The Building-blocks project is owned by the **CCoE Team**. This team owns and implements the [Foundation Platform Architecture](/Foundation-Design.md), defines the design for all individual platform topics and makes platform capabilities available using mature DevOps practices such as Infrastructure as Code and Configuration as Code for the platform. It drives the automated deployment through release pipelines.

This team is also responsible for the Development and Publishing of the [Certified Components](/Certified-Components.md) following the [Certification Process](/Certification-Process.md).

This enables a variety of workloads to be hosted on public cloud and conform to the Security Control Framework.

The main activities of this team could be summarized in: 

1. Deploying new platforms for the Application teams
2. Defining new set of policy definitions and assignments based on the new security baselines defined for new components
3. Adapting the platform scripts to include this policies during the environments creation
4. Remediate existing environments with new policies when needed.
5. Adapting the compliance dashboard to include new certified components.
6. Monitoring applications' ADO project to adapt for needs/requirements.
7. Continuously improves and mature the platform by making more platform capabilities available for workloads and the certified components, while confirming that the Security Control and Service Management Frameworks are adopted
8. Design, development and lifecycle management of certified components that are compliant with the latest Security Control Framework controls, while following the Infrastructure as Code principles. These certified components are published in a service catalog for self-service consumption by customer DevOps Teams, also known as Platform Teams.

> Learn about Azure DevOps in section [Learning Resources > Azure > Azure DevOps](/Learning-resources/Azure/Azure-DevOps.md)

![Overview of Azure DevOps organization](/.attachments/images/Foundation-Design/platform-design-ado-organization.png)

> NOTE: the diagram can be modified using the Visio file on [Teams GRP MCS Cloud-native Engagement > Agile Delivery](https://teams.microsoft.com/_?lm=deeplink&lmsrc=homePageWeb&cmpid=WebSignIn#/conversations/Agile%20Delivery?threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&ctx=channel) > Files > [01 - Design Documents](https://contoso.sharepoint.com/sites/GRP_001608-AgileDelivery/Shared%20Documents/Forms/AllItems.aspx?RootFolder=%2Fsites%2FGRP%5F001608%2DAgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20%2D%20Design%20Documents&FolderCTID=0x01200001544C4EB547E84DB41D1C6FCCD4BEA9) > [PXS - Diagrams.vsdx](https://teams.microsoft.com/l/file/6F59E176-935C-450C-B8A0-A23AB3831B4C?tenantId=e7ab81b2-1e84-4bf7-9dcb-b6fec01ed138&fileType=vsdx&objectUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20-%20Design%20Documents%2FPXS%20-%20Diagrams.vsdx&baseUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery&serviceName=teams&threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&groupId=348f9039-5718-417a-8e56-85e2957e26be)

# Design Decisions

## RBAC Strategy

| Group name | Permissions | Membership | RBAC Strategy
| - | - | - | -
| **Contributors** | Has permissions to contribute fully to the project code base and work item tracking. The main permissions they don't have or those that manage or administer resources. | By default, **the team group created when you create a project is added to this group**, and any user you add to the team will be a member of this group. In addition, any team you create for a project will be added to this group by default, unless you choose a different group from the list. | Leave default configuration
| **Readers** | Has permissions to view project information, the code base, work items, and other artifacts but not modify them. | Assign to members of your organization who you want to provide view-only permissions to a project. These users will be able to view backlogs, boards, dashboards, and more, but not add or edit anything. Typically, these are members who aren't granted an access level ([Basic, Stakeholder, or other level](https://docs.microsoft.com/en-us/azure/devops/organizations/security/access-levels?view=azure-devops)) within the organization or on-premises deployment. who want to be able to view work in progress | [`CCoE Readers` AAD Group](/Foundation-Design/Identity-and-access-management.md).
| **Project Administrators** | Has permissions to administer all aspects of teams and project, although they can't create team projects. | Assign to users who manage user permissions, create or edit teams, modify team settings, define area an iteration paths, or customize work item tracking. | [`CCoE Admins` AAD Group](/Foundation-Design/Identity-and-access-management.md). Members of this team will only be allowed to make changes via PIM.
| ***{team name}*** | Has permissions to contribute fully to the project code base and work item tracking. The default Team group is created when you create a project, and by default is added to the **Contributors** group for the project. Any new teams you create will also have a group created for them and added to the Contributors group. | Add members of the team to this group. | [`CCoE Contr` AAD Group](/Foundation-Design/Identity-and-access-management.md).
| **Project Valid Users** | Has permissions to access the project. | Contains all users and groups that have been added anywhere within the project. You cannot modify the membership of this group. | Leave default configuration
| **Build Administrators** | Has permissions to administer build resources and build permissions for the project. Members can manage test environments, create test runs, and manage [build pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/what-is-azure-pipelines?view=azure-devops). | By default, **Contributors** are added as members of this group | Leave default configuration
| **Release Administrators** | Has permissions to manage all release operations. This group is defined after the first [release pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/release/?view=azure-devops) is created. Valid for TFS-2017 and later versions. | Assign to users who define and manage release pipelines.  | Leave default configuration
| **Endpoint Creators**  | Has permissions to create [Service Connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#create-a-service-connection). This group is defined after the first Service Connection has been created | By default, **Contributors and Project Administrators** are members of this group | Leave default configuration
| **Endpoint Administrators** | Has permissions to manage [Service Connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#create-a-service-connection). This group is defined after the first Service Connection has been created | By default, **Project Administrators** are members of this group | Leave default configuration

## Repository strategy

In building-blocks, we will manage repositories for different purposes:
- `Platform` repository contains the configuration, parameter and pipeline files used for deploying and configuring the [Foundational Platform Architecture](/Foundation-Design.md) and Landing Zones within the organization. This repository will reuse ARM templates and pipelines from `IaC` repository.
- `IaC` hosts the reusable ARM templates and pipelines to be used during the deployment of Certified Components and Foundational Platform within the organization via Infrastructure as Code.
- `Wiki` will be used as the sing-source-of-truth and agreements for the team. It will contain all agreed designs, documentation and ways of working

## Branching strategy

For all repos, we will keep the branch strategy simple. Build your strategy from these three concepts:
- Use **feature branches** for all new features and bug fixes.
- Merge feature branches into the `master` branch using **pull requests**.
- Keep a high quality, up-to-date `master` branch.

![Feature branch strategy](https://docs.microsoft.com/en-us/azure/devops/repos/git/media/branching-guidance/featurebranching.png?view=azure-devops)

## Service Connections

Service Connections in building-blocks will allow to manage the entire Foundation Platform via Pipelines and Infrastructure as Code. We will use the following Service Connections
- Service Connection linked to [`Governance Mgmt` Service Principal](/Foundation-Design/Identity-and-access-management.md)
  - This Service Connection will be used in the `Platform` repository to deploy and manage azure-related resources from the [Foundation Platform](/Foundation-Design.md) and [Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).
  - This Service Connection will be used in the `IaC` repository to [deploy and manage Azure Policies](/Certified-Components/Component-publishing.md) specific to certified components.
  - [`CCoE Contr` AD Group](/Foundation-Design/Identity-and-access-management.md) will have rights to `Use` this service connection
  - [`CCoE Admins` AD Group](/Foundation-Design/Identity-and-access-management.md) will have rights to `Administer` this service connection
- Service Connection linked to [`AAD Mgmt` Service Principal](/Foundation-Design/Identity-and-access-management.md)
  - This Service Connection will be used in the `Platform` repository to deploy and manage azure active directory-related resources from the [Foundation Platform](/Foundation-Design.md) and [Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).
  - [`CCoE Contr` AD Group](/Foundation-Design/Identity-and-access-management.md) will have rights to `Use` this service connection
  - [`CCoE Admins` AD Group](/Foundation-Design/Identity-and-access-management.md) will have rights to `Administer` this service connection
- Service Connection linked to [`LZ Sandbox` Service Principal](/Foundation-Design/Identity-and-access-management.md).
  - This Service Connection will be used in the `IaC` repository to [develop and test Certified Components](/Certified-Components/Component-publishing.md).
  - [`CCoE Contr` AD Group](/Foundation-Design/Identity-and-access-management.md) will have rights to `Use` this service connection
  - [`CCoE Admins` AD Group](/Foundation-Design/Identity-and-access-management.md) will have rights to `Administer` this service connection

## Artifacts for Certified Components

See section [Certified Components](/Certified-Components.md)

# Planned work

::: query-table a1474b0c-bef6-413e-986d-d6e1e9ab53c3
:::

# Configuration details