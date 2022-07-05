[[_TOC_]]

# Overview

The Certified Component will facilitate the deployment and management of one Azure Service needed by the business for a specific purpose and according to the agreements of the [Certification Process](/Certification-Process.md). During this phase, we will take time to understand the Azure Service that we will need to automate and determine how the service must be configured.

For each Certified Component we need to analyze, document and enable operations according to the agreements of the [Certificate Process](/Certification-Process.md) that will allow to easily manage the Azure Service following the principles of [Infrastructure as Code](/Learning-resources/Infrastructure-as-Code.md).

# Checklist

- [X] Understand how the Azure service [can be automated in Azure](#resource-provider-automation-discovery)
- [X] [Design the architecture](#design-the-architecture-for-the-certified-component) for the service based on the scenarios that will be enabled with the Certified Component
- [X] Determine how the service should best be configured to meet the requirements
- [X] Parametrize in the configuration file the configuration will change depending on the target environment or deployment and needs to be parameterized
- [X] Define Inputs, Outputs and Secrets related to the service
- [X] Understand and declare dependencies (what Azure elements must exist before the service can be deployed), if any
- [X] Determine any limitation found in the service due to Azure limits or features in preview
- [X] [Document](#document-your-design) all findings and decisions taking in the `README.md` file for the Certified Component.

# Guidance

## Resource Provider automation discovery

When we need to start designing a Certified Component, it is good to take a look to how the Resource can be automated using the following strategies:
- Review the [Azure Documentation](https://docs.microsoft.com/en-us/azure/)
 for the service. Every service has an overview section where you can start learning about the purpose of the service
- The [ARM Reference](https://docs.microsoft.com/en-us/azure/templates/) documentation will tell us what properties can be configured for each version of the published Resource Providers leveraging ARM Templates
- The [Azure REST API Reference](https://docs.microsoft.com/en-us/rest/api/azure/) documentation will tell us what REST API operations can be requested for each Resource Provider. Any coding language we use will eventually raise a REST API call, so this documentation will tell what is going on in the background.
- [Azure Quickstart Templates](https://github.com/Azure/azure-quickstart-templates) can serve as an ARM Template repository with scenarios implemented by Microsoft or by the community
- [Resources portal](https://resources.azure.come/) will allow us browse throughout our deployed resources rendering only the deployed configuration instead of the graphical user interface (that is, each GET response from the REST API)

## Design the architecture for the Certified Component

Every Certified Component will be designed and implemented to meet some business scenarios with dependencies and integrations with other services / applications / Azure services.

Understanding the architecture that will be implemented in the current version of the service is key to determine the requirements for the development.

The following resources can be leveraged when designing the architecture for the Certified Component:
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Microsoft Cloud Adoption Framework for Azure](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Microsoft Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)
- [Microsoft Azure Well-Architected Review](https://docs.microsoft.com/en-us/assessments/?mode=pre-assessment&session=local)

## Document your design

Given that each Certified Component is designed and implemented with one purpose in mind and with limitations, we need to create a consistent and clear documentation so that each Certified Component can be easily understood by anyone that wants to reuse the Certified Component.

Following the [README](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/about-readmes) philosophy born in Github, we will add a README.md file to each Certified Component that will explain:
- Why the Certified Component is useful
- What the Certified Component does
- The Design decisions taken for the Certified Component
- How users can get configured the Certified Component in their pipelines
- Release notes

We can use the following resources to build a consistent and well-documented documentation:

- [About READMEs](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/about-readmes)
- [Introducing docs.microsoft.com](https://docs.microsoft.com/en-us/teamblog/introducing-docs-microsoft-com)
- [Syntax guidance for basic Markdown usage](https://docs.microsoft.com/en-us/azure/devops/project/wiki/markdown-guidance?view=azure-devops)
- [Syntax guidance for Markdown usage in Wiki](https://docs.microsoft.com/en-us/azure/devops/project/wiki/wiki-markdown-guidance?view=azure-devops)
- [Mastering Markdown](https://guides.github.com/features/mastering-markdown/)
- [Basic writing and formatting syntax](https://help.github.com/en/github/writing-on-github/basic-writing-and-formatting-syntax#styling-text)
- [Emoji Cheat Sheet](https://www.webfx.com/tools/emoji-cheat-sheet/)

# Readiness

- [Build great solutions with the Microsoft Azure Well-Architected Framework | Microsoft Learn](https://docs.microsoft.com/en-us/learn/paths/azure-well-architected-framework/)

# References

1. [Azure Documentation | Microsoft Docs](https://docs.microsoft.com/en-us/azure/)
2. [Define resources in Azure Resource Manager templates | Microsoft Docs](https://docs.microsoft.com/en-us/azure/templates/)
4. [Azure REST API Reference | Microsoft Docs](https://docs.microsoft.com/en-us/rest/api/azure/).
5. [Azure Quickstart Templates | GitHub](https://github.com/Azure/azure-quickstart-templates).
6. [Resources portal | https://resources.azure.com](https://resources.azure.come/)
7. [Azure Architecture Center | Microsoft Docs](https://docs.microsoft.com/en-us/azure/architecture/)
8. [Microsoft Cloud Adoption Framework for Azure | Microsoft Docs](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/)
9. [Microsoft Azure Well-Architected Framework | Microsoft Docs](https://docs.microsoft.com/en-us/azure/architecture/framework/)
10. [Microsoft Azure Well-Architected Review | Microsoft Docs](https://docs.microsoft.com/en-us/assessments/?mode=pre-assessment&session=local)
11. [Azure subscription and service limits, quotas, and constraints | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits)
12. [RBAC for Azure resources documentation | Microsoft Docs](https://docs.microsoft.com/en-us/azure/role-based-access-control/)
13. [Azure Resource Manager resource provider operations | Microsoft Docs](https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations)
14. [About READMEs | GitHub Docs](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/about-readmes)
15. [Introducing docs.microsoft.com | Microsoft Docs](https://docs.microsoft.com/en-us/teamblog/introducing-docs-microsoft-com)
16. [Syntax guidance for basic Markdown usage | Microsoft Docs](https://docs.microsoft.com/en-us/azure/devops/project/wiki/markdown-guidance?view=azure-devops)
17. [Mastering Markdown | Microsoft Docs](https://guides.github.com/features/mastering-markdown/)
18. [Basic writing and formatting syntax | GitHub Docs](https://docs.github.com/en/github/writing-on-github/basic-writing-and-formatting-syntax)
19. [Emoji Cheat Sheet | WebFX](https://www.webfx.com/tools/emoji-cheat-sheet/)