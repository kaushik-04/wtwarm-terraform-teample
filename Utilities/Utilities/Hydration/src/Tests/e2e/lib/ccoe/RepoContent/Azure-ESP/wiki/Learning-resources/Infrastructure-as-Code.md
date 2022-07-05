[[_TOC_]]

# What is Infrastructure as Code?

[Infrastructure as Code (IaC)](https://docs.microsoft.com/en-us/azure/devops/learn/what-is-infrastructure-as-code) is the management of infrastructure (networks, virtual machines, load balancers, and connection topology) in a descriptive model, using the same versioning and practices as in source code. Infrastructure as Code usually relies in a text file where the properties of the infrastructure that needs to be deployed and configured are described.

One of the core principles of Infrastructure as code is [idempotency](https://restfulapi.net/idempotent-rest-apis/). This principle is referred to REST APIs when the effect of multiple requests always have the same outcome. For an Infrastructure as Code model, idempotency will always generate the same environment every time is applied.

Infrastructure as Code and infrastructure orchestration tools are designed to automate the deployment of servers and other infrastructure. **Configuration as Code** and configuration management tools help configure the software and systems on this infrastructure that has already been provisioned.

# Why Infrastructure as Code?

Effective version control allows teams to recover quickly from problems and to improve quality by making sure the right components are integrated together. Putting all assets as code and under version control means that all changes are tracked and can be recreated at the click of a button.

**Avoid configuration/environment drift: ad hoc changes to a systems configuration that go unrecorded**

[Configuration Drift](http://kief.com/configuration-drift.html) is the phenomenon where servers in an infrastructure become more and more different from one another as time goes on, due to manual ad-hoc changes and updates, and general entropy.

There are two main methods to combat configuration drift. One is to use automated configuration tools such as Puppet or Chef and run them frequently and repeatedly to keep machines in line. The other is to rebuild machine instances frequently, so that they don’t have much time to drift from the baseline.

Over time, each environment becomes a snowflake, that is, a unique configuration that cannot be reproduced automatically. Inconsistency among environments leads to issues during deployments. With snowflakes, administration and maintenance of infrastructure involves manual processes which were hard to track and contributed to errors.

**Infrastructure as Code has become easier to implement with the usage of native cloud provider languages and tools**

Cloud Providers are managed using an APIs. For Azure, [Azure Resource Manager API](https://docs.microsoft.com/en-us/rest/api/resources/) lets you manage any object in Azure such as network cards, virtual machines or hosted databases.

The main benefits of the ARM API are that you can deploy several resources together in a single unit and that the deployments are idempotent, in that the user declares the type of resource, what name to use and which properties it should have; the ARM API will then either create a new object that matches those details or change an existing object which has the same name and type to have the same properties.

[ARM Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview) are a way to declare the objects you want, their types, names and properties in a JSON file which can be checked into source control and managed like any other code file. ARM Templates are what really gives us the ability to roll out Azure Infrastructure as code.

**Code can be kept in source control to allow auditability**

For highly regulated industries, auditing is very important. You need a way to easily review the infrastructure and how it’s going to be deployed. This declarative model is human readable. Using Infrastructure in combination with Git and Pipelines, tech risk, security and internal auditing can evolve. It can build trust to speed the approval process to get changes out the door faster.

**Achieve the full discipline of Continuous Delivery and reproducible builds**  

One of the prevailing assumptions that fans of Continuous Integration have is that [builds should be reproducible](https://martinfowler.com/bliki/ReproducibleBuild.html). By this we mean that at any point you should be able to take some older version of the system that you are working on and build it from source in exactly the same way as you did then.

**Streamline and improve communication between product engineers, content teams, and customers**

By having and sharing code in repos (publicly or privately) we can [improve communication](https://petabridge.com/blog/use-github-professionally/) and save costs across teams within the organization by:
- Reporting a bug with the project;
- Proposing a new feature or change; or
- Discussing tactical and strategic issues with other stakeholders,
- About Pull Requests - The most effective way to use pull requests is to get code out in front of other developers on your team early and often, before you’ve invested too much development time into something new. If you’re going down the wrong path or if your work is in conflict with someone else’s it’s better for everyone to have that conversation early.

# Infrastructure as Code Languages

## ARM Templates

> Learn more in section [ARM Templates](/Learning-resources/Infrastructure-as-Code/ARM-Templates.md)

[ARM Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview#template-deployment) are the native [Infrastructure as Code](https://blogs.msdn.microsoft.com/azuredev/2017/02/11/iac-on-azure-an-introduction-of-infrastructure-as-code-iac-with-azure-resource-manager-arm-template/) language for Azure, so it will usually be our main language of development.

## PowerShell

> Learn more in section [PowerShell](/Learning-resources/Infrastructure-as-Code/PowerShell.md)

Azure PowerShell is designed for managing and administering Azure resources from the command line. Use Azure PowerShell when you want to build automated tools that use the Azure Resource Manager model. 

Starting in December 2018, the [Azure PowerShell Az module](https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-3.6.1) is in general release and is now the intended PowerShell module for interacting with Azure. Az offers shorter commands, improved stability, and cross-platform support. Az also has feature parity with AzureRM, giving you an easy migration path.

# Modularizing Infrastructure as Code

> Learn more in section [IaC modules](/Learning-resources/Infrastructure-as-Code/IaC-Modules.md)

How you design Infrastructure as Code templates or scripts is entirely up to any development team and how this team wants to manage the solution.

It is possible to deploy complex infrastructure through a single template to a single resource group, but often, it makes sense to divide the deployment requirements into a set of targeted, purpose-specific templates.

Development of Infrastructure as Code and Configuration as Code can easily become complex and unmaintainable. With the [modularization](/Learning-resources/Infrastructure-as-Code/IaC-Modules.md) approach, we adapt the same principles as in software development to help Infrastructure as Code developers produce flexible and maintainable code.

# Reference Links

1. [What is Infrastructure as Code? | Microsoft Docs](https://docs.microsoft.com/en-us/azure/devops/learn/what-is-infrastructure-as-code)
2. [Infrastructure As Code | Martin Fowler](https://martinfowler.com/bliki/InfrastructureAsCode.html)
3. [What Is Idempotence? | REST API Tutorial](https://www.restapitutorial.com/lessons/idempotency.html)
4. [Idempotent REST APIs| RESTFul API](https://restfulapi.net/idempotent-rest-apis/)
5. [Configuration Drift | Kief.com](http://kief.com/configuration-drift.html)
6. [Reproducible Build | Martin Fowler](https://martinfowler.com/bliki/ReproducibleBuild.html)
7. [Microsoft Docs Contributor Guide Overview | Microsoft Docs](https://docs.microsoft.com/en-us/contribute/#review-open-prs)
8. [How to Use Github Professionally | Petabridge](https://petabridge.com/blog/use-github-professionally/)
9. [Azure Resource Manager templates overview | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview)
10. [Azure Resource Manager (ARM) Templates | Redgate](https://www.red-gate.com/simple-talk/cloud/infrastructure-as-a-service/azure-resource-manager-arm-templates/)
11. [What KPMG Learned About Infrastructure as Code: Tools, People, and Process | The New Stack](https://thenewstack.io/what-kpmg-learned-about-infrastructure-as-code-tools-people-and-process/)