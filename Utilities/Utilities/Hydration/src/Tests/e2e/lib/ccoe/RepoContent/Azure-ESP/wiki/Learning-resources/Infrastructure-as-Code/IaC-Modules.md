[[_TOC_]]

# What is an Infrastructure as Code module?

A module is a reusable combination of [Infrastructure as Code](/Learning-resources/Infrastructure-as-Code.md) templates and scripts that will let you manage your infrastructure in Azure through one or more idempotent operations (create, remove, etc.). Each module will target a single [Azure Resource Provider](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types).

![Module Approach](/.attachments/images/Learning-resources/Infrastructure-as-Code/iac-modules-single-responsibility.png)

The modules can be developed using different programming languages such as [ARM Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview), [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/what-is-azure-cli?view=azure-cli-latest), [Azure Powershell](https://docs.microsoft.com/en-us/powershell/azure/?view=azps-3.5.0), languages compatible with the [Azure Unified SDK](https://azure.microsoft.com/en-us/downloads/) or any combination of these languages. Each module will be published to Azure DevOps as [Azure DevOps Build Artifacts](https://docs.microsoft.com/en-us/azure/devops/pipelines/artifacts/artifacts-overview?view=azure-devops), and the deployment steps will be simplified through the creation of [Task Groups](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/task-groups?view=azure-devops).

![Module deployment](/.attachments/images/Learning-resources/Infrastructure-as-Code/iac-modules-azure-devops-deployment.png)

The modules are consumed in [Azure DevOps Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/index?view=azure-devops) using a declarative [parameters file following ARM Template syntax](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/parameter-files). Azure DevOps Pipelines run on [Azure Pipelines Agents](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops&tabs=browser) that can be Microsoft-hosted or self-hosted by your organization. Modules will log in to Azure use a Service Principal identity configured as an Azure Resource Manager [Service Connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml).

# Why Infrastructure as Code modules?

How you design Infrastructure as Code templates is entirely up to you and how you want to manage your solution. You can deploy your complex infrastructure through a single template to a single resource group, but often, it makes sense to divide your deployment requirements into a set of targeted, purpose-specific templates.

Development of Infrastructure as Code and Configuration as Code can easily become complex and unmaintainable. With the modules approach, we adapt the same principles as in software development to help Infrastructure as Code developers produce flexible and maintainable code.

**SOLID Principles and Maintainable Code**

[SOLID](https://medium.com/@severinperez/writing-flexible-code-with-the-single-responsibility-principle-b71c4f3f883f) principles are intended to help developers write clean, well-structured, and easily-maintainable code. The ideas prescribed by SOLID adherents have been widely adopted in the software community, and agree with them or not, they’re a useful set of principles from which to draw best practices. Moreover, SOLID has been thoroughly integrated into a broader set of Agile development practices and understanding them is thus a virtual requirement in the modern software industry.

SOLID is an acronym for a set of five software development principles:
- The [**S**ingle Responsibility Principle](https://medium.com/@severinperez/writing-flexible-code-with-the-single-responsibility-principle-b71c4f3f883f) — Classes should have a single responsibility and thus only a single reason to change. We follow this principle in our modules by making sure that each module focuses only on one single Resource Provider. This means that we will different modules for Network Interfaces, Public IP Addresses, Virtual Networks, Storage Accounts, Virtual Machines...
- The [**O**pen/Closed Principle](https://medium.com/@severinperez/maintainable-code-and-the-open-closed-principle-b088c737262) — Classes and other entities should be open for extension but closed for modification. We follow this principle to determine our Module Versioning approach. Each published version of a module will contain code that is “open for extension”, which means that new behavior - such as new operations or new properties - can be added without breaking deployments that are currently using that version of the module, and will also contain code “closed for modification” that cannot be changed once implemented due to breaking logic. In scenarios where we need to modify code "closed for modification", we release a new version of the module instead.
- The [**L**iskov Substitution Principle](https://medium.com/@severinperez/making-the-most-of-polymorphism-with-the-liskov-substitution-principle-e22609866429) — Objects should be replaceable by their subtypes. This principle cannot be adopted by Infrastructure as Code since inheritance does not apply.
- The [**I**nterface Segregation Principle](https://medium.com/@severinperez/avoiding-interface-pollution-with-the-interface-segregation-principle-5d3859c21013) — Interfaces should be client specific rather than general. Same as with Liskov Substitution Principle, the Interface Segregation Principle cannot be adopted since Interfaces are not applicable to Infrastructure as Code.
- The [**D**ependency Inversion Principle](https://medium.com/@severinperez/effective-program-structuring-with-the-dependency-inversion-principle-2d5adf11f863) — Depend on abstractions rather than concretions. This principle takes care about the manner in which you structure your program entities, and the way in which they interact with one another. Our modules represent pieces of Infrastructure as entities, and the only dependencies that we will find are dependencies on other infrastructure items. For instance, a Virtual Machine needs a Virtual Network and certain RBAC  permissions assigned to the identity deploying the Virtual Machine upfront to be deployed, then the module for Virtual Machines will depend on the module for Virtual Networks. Since we cannot use Interfaces to define abstractions, we need to use documentation to explain the dependencies or pre-requisites for each module.

**Twelve-Factor methodology for software-as-a-service apps**

The [Twelve-Factor](https://12factor.net/) methodology synthesizes all of our experience and observations on a wide variety of software-as-a-service apps in the wild and can be applied to apps written in any programming language, and which use any combination of backing services (database, queue, memory cache, etc). The format is inspired by Martin Fowler’s books Patterns of Enterprise Application Architecture and Refactoring. Software-as-a-service apps:
- Use declarative formats for setup automation, to minimize time and cost for new developers joining the project;
- Have a clean contract with the underlying operating system, offering maximum portability between execution environments;
- Are suitable for deployment on modern cloud platforms, obviating the need for servers and systems administration;
- Minimize divergence between development and production, enabling continuous deployment for maximum agility;
- Can scale up without significant changes to tooling, architecture, or development practices.

We take principles from the Twelve Factor methodology for two reasons:
1. The infrastructure managed by our modules will eventually host software-as-a-service apps. Then, our modules need to meet the properties of these kind of applications.
2. We must treat our modules as infrastructure-as-a-service developments. Then we need to follow the properties of these kind of applications during the development of our modules.

The Twelve Factors:
1. **[Codebase](https://12factor.net/codebase)**. One codebase tracked in revision control, many deploys. For our modules we will be use a single codebase that will publish each module as shared code as reusable libraries -Azure DevOps Artifacts and Task Groups-. A different codebase will be used to deploy the Infrastructure to Azure.
2. **[Dependencies](https://12factor.net/dependencies)**. Explicitly declare and isolate dependencies. Dependencies will be declared via README file for each module.
3. **[Config](https://12factor.net/config)**. Store config in the environment. The parameters of our modules will include Application Configuration that varies between environments.
4. **[Backing services](https://12factor.net/backing-services)**. Treat backing services as attached resources. There will be modules for specific backing services in Azure such as SQL Databases or Storage Accounts. With the modules approach, we will enable the deployment and management of backing services as distinct resources.
5. **[Build, release, run](https://12factor.net/build-release-run)**. Strictly separate build and run stages. The target of our modules is the Release phase for the infrastructure, then they will force a strict separation between build and run stages.
6. **[Processes](https://12factor.net/processes)**. Execute the app as one or more stateless processes. This principle can be taken into account for the design of modules related to computing services with configuration related to processes.
7. **[Port binding](https://12factor.net/port-binding)**. Export services via port binding. This principle can be taken into account for the design of modules related to computing services with configuration related to webserver containers and port binding.
8. **[Concurrency](https://12factor.net/concurrency)**. Scale out via the process model. This principle can be taken into account for the design of modules related to computing services with configuration related to processes.
9. **[Disposability](https://12factor.net/disposability)**. Maximize robustness with fast startup and graceful shutdown. This principle can be taken into account for the design of modules related to computing services with configuration related to processes.
10. **[Dev/prod parity](https://12factor.net/dev-prod-parity)**. Keep development, staging, and production as similar as possible. The goal of our modules is to facilitate this principle by which environments can be kept as similar as possible, preventing from configuration draft. Only the attributes that need to change between environments will be offered as parameters.
11. **[Logs](https://12factor.net/logs)**. Treat logs as event streams. This principle can be taken into account for the design of modules related to computing services with configuration related to processes.
12. **[Admin processes](https://12factor.net/admin-processes)**. Run admin/management tasks as one-off processes. Modules will implement administration operations that run against a release, using the same codebase and config as any process running for release.

# References

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