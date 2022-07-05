[[_TOC_]]

# General guidelines

Based on learnings from the software development practices mentioned in section [IaC Modules](/Learning-resources/Infrastructure-as-Code/IaC-Modules.md), we need to take into account the following principles when developing Certified Components

1. Each Certified Component will be scoped to just one single [Azure Resource or Azure Resource Provider](/Learning-resources/Infrastructure-as-Code/IaC-Modules.md#single-responsibility).
2. Each Certified Component will define one or more [idempotent](/Learning-resources/Infrastructure-as-Code/IaC-Modules.md#idempotent-development) operations that will allow to manage the scoped Azure Resource.
3. Each Certified Component must read the declarative configuration from one [configuration file](/Learning-resources/Infrastructure-as-Code/IaC-Modules.md#declarative-syntax) following the [Azure Resource Manager (ARM) template parameters file](/Learning-resources/Infrastructure-as-Code/ARM-Templates.md) syntax.
4. Each Certified Component will contain an [orchestration script](/Learning-resources/Infrastructure-as-Code/IaC-Modules.md#orchestration-logic) that will read the attributes from the declarative configuration file and orchestrate the deployment of the required ARM Templates, pre and/or post deployment scripts.
5. Each Certified Component must implement at least two operations: deploy, remove. The deploy operation must have an idempotent behavior and most of the operations should be achievable by modifying the parameters file of this operation.
6. For each Certified Component, only the properties that need to change between environments will be offered as attributes in the configuration file. The rest of the configuration will remain in the template of the Certified Component. This will help keep the different environments as similar as possible preventing from environment drift.
7. Each Certified Component must have a [README document](/Learning-resources/Infrastructure-as-Code/IaC-Modules.md#packaging-and-sharing) with an overview of the scoped Azure resource and information related to each available operations (dependencies, limitations, parameters, examples of valid parameters, outputs).
8. Certified Components will be [packaged and published](/Learning-resources/Infrastructure-as-Code/IaC-Modules.md#packaging-and-sharing) so that they can be reused by other teams.

## Single Responsibility

Each Certified Component will follow the [**S**OLID](/Learning-resources/Infrastructure-as-Code/IaC-Modules.md#why-infrastructure-as-code-modules?) [**S**ingle Responsibility Principle](https://medium.com/@severinperez/writing-flexible-code-with-the-single-responsibility-principle-b71c4f3f883f) by which each Certified Component will deploy only on one single Azure Resource Type.

This means that we will develop Certified Components for Network Interfaces, Public IP Addresses, Virtual Networks, Storage Accounts, Virtual Machines...

![Certified Component Approach](/.attachments/images/Learning-resources/Infrastructure-as-Code/iac-modules-single-responsibility.png)

## Declarative syntax

With Infrastructure as Code we can achieve version control of the configuration model for all our environments by implementing [idempotent](#idempotent-development) logic in our scripts and following a declarative syntax to configure target environments using well-documented code formats.

![Declarative configuration](/.attachments/images/Learning-resources/Infrastructure-as-Code/declarative-configuration.png)

Having the configuration of all our environments described with a declarative syntax and version controlled in our source code will let us take advantage of the [main benefits of the Infrastructure as Code](/Learning-resources/Infrastructure-as-Code.md#why-infrastructure-as-code) discipline:
- Avoid configuration/environment drift
- Enable auditability
- Achieve the full discipline of Continuous Delivery and reproducible builds
- Streamline and improve communication between product engineers, content teams, and customers

We will refer to the files containing the configuration for a Certified Component as **configuration files**, and they will all follow the declarative syntax.

## Idempotent development

> Learn more in the section [Develop](/Certified-Components/Component-development/Develop.md)

One of the core principles of Infrastructure as code is [idempotency](https://restfulapi.net/idempotent-rest-apis/). This principle is referred to REST APIs when the effect of multiple requests always have the same outcome.

To implement idempotency in our Certified Components, each Certified Component will be developed in such a way that, given a configuration, it will always generate the same configuration in the target resource or environment every time the Certified Component is applied. This means that an idempotent Certified Component receiving the configuration below, will:

1. If the app service with name `appservice01` does not exist, the idempotent script will deploy it with the described configuration
2. If the app service with name `appservice01` already exists,the idempotent script will change the configuration of the app service and adapt it to the described configuration.
 
Notice that with the idempotent approach, certain operations such as scaling will be made simply by modifying the right configuration property (e.g. `AppServicePlanInstances` from `2` to `3` for scaling out) and redeploying the Certified Component.

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "AppServiceName": {
      "value": "appservice01"
    },
    "AppServicePlanName": {
      "value": "windowsappserviceplan01"
    },
    "AppServicePlanLocation": {
      "value": "West Europe"
    },
    "AppServicePlanInstances": {
      "value": 3
    },
    "AppServicePlanTier": {
      "value": "Standard"
    }
  }
}
```

How to achieve this will depend heavily on the language chosen for developing the Certified Components.
- [Azure Resource Manager (ARM) templates](/Learning-resources/Infrastructure-as-Code/ARM-Templates.md) are the Azure native declarative syntax that allows to define and deploy Azure infrastructure and configuration. **This is the preferred language for implementing Infrastructure as Code** as Resource Manager [converts the template into idempotent REST API operations](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview#template-deployment-process).
- [Azure PowerShell Az module](/Learning-resources/Infrastructure-as-Code/PowerShell.md) is designed for managing and administering Azure Resource Manager resources from the command line. Azure PowerShell can be used:
  - As part of Azure Resource Manager templates with a new resource type called [`Microsoft.Resources/deploymentScripts`](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template)
  - As a separate deployment step, before or after the deployment of an ARM Template, to add some automation steps that cannot be achieved using ARM Template syntax.
- Azure Command Line Interface (CLI)

## Secrets management

Dealing with Infrastructure as Code means that we need to protect what we put in our code. Specifically, we should try to avoid having sensitive values such as passwords, keys or credentials in plain text in our files.

So, how can we deal with sensitive values in our Certified Components? That will depend on the specific resource, but we there are a few techniques that we can use to avoid hardcoded sensitive values in the repository:

- Integrate Key Vault in ARM templates
- Integrate Key Vault with Azure DevOps
- Integrate Key Vault in the module deployment logic
- Avoid credentials management by using Managed Identities

> Learn more in section [Secrets management](/Certified-Components/Design-principles/Secrets-management.md)

# References

1. [Writing Flexible Code with the Single Responsibility Principle | Medium](https://medium.com/@severinperez/writing-flexible-code-with-the-single-responsibility-principle-b71c4f3f883f)
2. [Idempotent REST APIs | REST API Tutorial](https://restfulapi.net/idempotent-rest-apis/)
3. [What are ARM templates? | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview)
4. [Use deployment scripts in templates | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template)
11. [Template types & usage | Microsoft Docs](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops)