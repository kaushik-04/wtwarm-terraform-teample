[[_TOC_]]

# What is Azure DevOps?

[Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/user-guide/what-is-azure-devops?view=azure-devops) provides developer services to support teams to plan work, collaborate on code development, and build and deploy applications.

::: video
<iframe width="560" height="315" src="https://www.youtube.com/embed/JhqpF-5E10I" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
:::

Azure DevOps provides integrated features that you can access through your web browser or IDE client. You can use one or more of the following services based on your business needs:
- Azure Repos provides Git repositories or Team Foundation Version Control (TFVC) for source control of your code
- Azure Pipelines provides build and release services to support continuous integration and delivery of your apps
- Azure Boards delivers a suite of Agile tools to support planning and tracking work, code defects, and issues using Kanban and Scrum methods
- Azure Test Plans provides several tools to test your apps, including manual/exploratory testing and continuous testing
- Azure Artifacts allows teams to share Maven, npm, and NuGet packages from public and private sources and integrate package sharing into your CI/CD pipelines

You can also use collaboration tools such as:
- Customizable team dashboards with configurable widgets to share information, progress, and trends
- Built-in wikis for sharing information
- Configurable notifications
- Azure DevOps supports adding extensions and integrating with other popular services, such as: Campfire, Slack, Trello, UserVoice, and more, and developing your own custom extensions.

# Azure DevOps Organization

With an [Azure DevOps organization](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/organization-management?view=azure-devops), you gain access to the platform in which you can do the following:
- Collaborate with others to develop applications by using our cloud service
- Plan and track your work as well as code defects and issues
- Set up continuous integration and deployment
- Integrate with other services by using service hooks
- Obtain additional features and extensions
- Create one or more projects to segment work.

## Organization-level Security

Azure DevOps is pre-configured with default [security groups](https://docs.microsoft.com/en-us/azure/devops/organizations/security/about-security-identity?view=azure-devops#security-groups-and-permissions). Default permissions are assigned to the default security groups. You can populate these groups by using individual users.

Azure DevOps controls access through these three inter-connected functional areas:
- **Membership management** supports adding individual Windows user accounts and groups to default security groups. Also, you can create Azure DevOps security groups. Each default group is associated with a set of default permissions. All users added to any security group are added to the Valid Users group. A valid user is someone who can connect to the project.
- **Permission management** controls access to specific functional tasks at different levels of the system. Object-level permissions set permissions on a file, folder, build pipeline, or a shared query. Permission settings correspond to Allow, Deny, Inherited allow, Inherited deny, and Not set. To learn more about inheritance, see About permissions and groups.
- **Access level management** controls access to features provided via the web portal, the web application for Azure DevOps. Based on what has been purchased for a user, administrators set the user's access level to Basic, VS Enterprise (previously Advanced), or Stakeholder.

When you create an organization or project collection in Azure DevOps, the system creates [collection-level groups](https://docs.microsoft.com/en-us/azure/devops/organizations/security/permissions?view=azure-devops&tabs=preview-page#collection-level-groups) that have permissions in that collection. You can not remove or delete the built-in collection-level groups.

The following Groups are used to manage permissions at organization level:

| Group name | Permissions | Membership
| - | - | -
| Project Collection Administrators | Has permissions to perform all operations for the collection. | Contains the Local Administrators group (BUILTIN\Administrators) for the server where the application-tier services have been installed. Also, contains the members of the CollectionName/Service Accounts group. **This group should be restricted to the smallest possible number of users who need total administrative control over the collection**. For Azure DevOps, assign to administrators who customize work tracking.
| Project Collection Build Administrators | Has permissions to administer build resources and permissions for the collection. | Limit this group to the smallest possible number of users who need total administrative control over build servers and services for this collection.
| Project Collection Build Service Accounts | Has permissions to run build services for the collection. | Limit this group to service accounts and groups that contain only service accounts. This is a legacy group used for XAML builds. Use the Project Collection Build Service ({your organization}) user for managing permissions for current builds.
| Project Collection Proxy Service Accounts | Has permissions to run the proxy service for the collection. | Limit this group to service accounts and groups that contain only service accounts.
| Project Collection Service Accounts | Has service level permissions for the collection and for Azure DevOps Server. | Contains the service account that was supplied during installation. This group should contain only service accounts and groups that contain only service accounts. By default, this group is a member of the Administrators group.
| Project Collection Test Service Accounts | Has test service permissions for the collection. | Limit this group to service accounts and groups that contain only service accounts.
| Project Collection Valid Users | Has permissions to access team projects and view information in the collection. | Contains all users and groups that have been added anywhere within the collection. You cannot modify the membership of this group.
| Security Service Group | Used to store users who have been granted permissions, but not added to any other security group. Don't assign users to this group. If you are removing users from all security groups, check if you need to remove them from this group.

# Azure DevOps Project

[Azure DevOps Projects](https://docs.microsoft.com/en-us/azure/devops-project/overview) makes it easy to get started on Azure. It helps you launch your favorite app on the Azure service of your choice in just a few quick steps from the Azure portal.

DevOps Projects sets up everything you need for developing, deploying, and monitoring your application. You can use the DevOps Projects dashboard to monitor code commits, builds, and deployments, all from a single view in the Azure portal.
## Project-level permissions

You manage [project-level permissions](https://docs.microsoft.com/en-us/azure/devops/organizations/security/permissions?view=azure-devops&tabs=preview-page#project-level-permissions) from the web portal admin context or using the TFSSecurity command-line tool. Project Administrators are assigned all project-level permissions. Other project-level groups are assigned a subset of these permissions.

## Project-level Default Security Groups

For each project that you create, the system creates the followings [project-level groups](https://docs.microsoft.com/en-us/azure/devops/organizations/security/permissions?view=azure-devops&tabs=preview-page#project-level-permissions). These groups are assigned project-level permissions.

| Group name | Permissions | Membership |
| - | - | -
| **Contributors** | Has permissions to contribute fully to the project code base and work item tracking. The main permissions they don't have or those that manage or administer resources. | By default, the team group created when you create a project is added to this group, and any user you add to the team will be a member of this group. In addition, any team you create for a project will be added to this group by default, unless you choose a different group from the list. |
| **Readers** | Has permissions to view project information, the code base, work items, and other artifacts but not modify them. | Assign to members of your organization who you want to provide view-only permissions to a project. These users will be able to view backlogs, boards, dashboards, and more, but not add or edit anything. Typically, these are members who aren't granted an access level ([Basic, Stakeholder, or other level](https://docs.microsoft.com/en-us/azure/devops/organizations/security/access-levels?view=azure-devops)) within the organization or on-premises deployment. who want to be able to view work in progress. |
| **Project Administrators** | Has permissions to administer all aspects of teams and project, although they can't create team projects. | Assign to users who manage user permissions, create or edit teams, modify team settings, define area an iteration paths, or customize work item tracking. |
| ***{team name}*** | Has permissions to contribute fully to the project code base and work item tracking. The default Team group is created when you create a project, and by default is added to the Contributors group for the project. Any new teams you create will also have a group created for them and added to the Contributors group. | Add members of the team to this group. |
| **Project Valid Users** | Has permissions to access the project. | Contains all users and groups that have been added anywhere within the project. You cannot modify the membership of this group. |
| **Build Administrators** | Has permissions to administer build resources and build permissions for the project. Members can manage test environments, create test runs, and manage [build pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/what-is-azure-pipelines?view=azure-devops). | By default, Contributors are added as members of this group  |
| **Release Administrators** | Has permissions to manage all release operations. This group is defined after the first [release pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/release/?view=azure-devops) is created. Valid for TFS-2017 and later versions. | Assign to users who define and manage release pipelines. |
| **Endpoint Creators**  | Has permissions to create [Service Connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#create-a-service-connection). This group is defined after the first Service Connection has been created | By default, Contributors and Project Administrators are members of this group
| **Endpoint Administrators** | Has permissions to manage [Service Connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#create-a-service-connection). This group is defined after the first Service Connection has been created | By default, Project Administrators are members of this group

## Service Connections

You will typically need to connect to external and remote services to execute tasks in a job. For example, you may need to connect to your Microsoft Azure subscription, to a different build server or file server, to an online continuous integration environment, or to services you install on remote computers.

You can define [service connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml) in Azure Pipelines that are available for use in all your tasks.

Service connections are created at project scope. A service connection created in one project is not visible in another project.

# References

1. [What is Azure DevOps?](https://docs.microsoft.com/en-us/azure/devops/user-guide/what-is-azure-devops?view=azure-devops)
2. [About organization management in Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/organization-management?view=azure-devops)
3. [About security and identity](https://docs.microsoft.com/en-us/azure/devops/organizations/security/about-security-identity?view=azure-devops)
4. [Default permissions and access for Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/organizations/security/permissions-access?view=azure-devops)
5. [Add AD/Azure AD users or groups to a built-in security group](https://docs.microsoft.com/en-us/azure/devops/organizations/security/add-ad-aad-built-in-security-groups?toc=%2Fazure%2Fdevops%2Fsecurity-access-billing%2Ftoc.json&bc=%2Fazure%2Fdevops%2Fsecurity-access-billing%2Fbreadcrumb%2Ftoc.json&view=azure-devops&tabs=preview-page)
6. [Create a project in Azure DevOps and TFS](https://docs.microsoft.com/en-us/azure/devops/organizations/projects/create-project?view=azure-devops&tabs=preview-page)
7. [Overview of Azure DevOps Projects](https://docs.microsoft.com/en-us/azure/devops-project/overview)
8. [Permissions, users, and groups in Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/organizations/security/permissions?view=azure-devops&tabs=preview-page#project-level-groups)
9. [Default permissions and access for Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/organizations/security/permissions-access?view=azure-devops)
10. [Service connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml)