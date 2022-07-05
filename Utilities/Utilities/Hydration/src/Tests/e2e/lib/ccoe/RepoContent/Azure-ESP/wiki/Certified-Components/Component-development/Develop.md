[[_TOC_]]

# Overview

During the development phase, we will develop the Certified Component according to the decisions taken during the [Design](/Certified-Components/Component-development/Design.md) phase. For each Certified Component we will develop:
- ARM Templates / Idempotent scripts
- Policy Definitions and Initiatives
- `README.md` documentation file

The Infrastructure as Code can be implemented natively in Azure via ARM templates, so this will be our preferred option.

However, some Azure Services (e.g. Service Principals, Azure Active Directory Applications) cannot be deployed by using ARM Templates, so we will need to leverage custom scripts for those resources or for certain operations such as create a self-signed certificate, look up IP Address blocks from custom system, etc.

We can also include some post-deployment configuration after ARM template deployment such as performing data plane operations (e.g., copy blobs or seed database) which forces us to use scripting too.

# Checklist

- [X] Create your [Git development branch](#git-development-branch)
- [X] Create a [directory for your Certified Component](#repository-structure) in the repository
- [X] If it is an Azure service that can be deployed via ARM Template, start [developing the ARM Template](#arm-template)
- [X] If PowerShell Scripts need to be added, develop your [PowerShell Script](#prepost-deployment-scripts) under the folder `Scripts`
- [X] Develop the [Certified Component deployment script](#certified-component-deployment-script) that will read configuration files and orchestrate deployment of ARM Templates and Scripts
- [X] Develop the [Certified Component policies](#policy-definitions-initiatives-and-assignments) that will be published as part of the Certified Component
- [X] Add as many configuration files as needed to test the deployment of your ARM Templates under the folder `Tests`. Each configuration file will contain a different combination of properties to be tested and the name will follow the syntax `test-##.config.json`, where `##` is the number of test (e.g. `test-01.config.json`)
- [X] [Test locally](#test-locally) that all the configuration files added to the `Test` folder are correctly deployed.

# Guidance

## Git Development branch

As described in the [IaC repository `README.md`](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?version=GBmaster), each new module, version or fix will be developed in its own feature branch from the master, and the name of the branch will follow the convention:
`[user]/[Certified ComponentName][moduleVersion]`

## Repository structure

See the [IaC repository `README.md`](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?version=GBmaster) to learn about the repository structure

## Certified Component deployment script

According to the [Certified Components Design Principles](/Certified-Components/Design-principles.md), each Certified Component will count on a deployment script that will be in charge of reading the configuration from the configuration file, doing pre-checks on the configuration if desired, and orchestrate deployment of ARM Templates and pre/post deployment scripts.

As a reference, we can take a look to the article [Deploy resources with Resource Manager templates and Azure PowerShell](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-powershell)

## ARM Template

Based on the [Certified Component design](/Certified-Components/Component-development/Design.md), we will develop the  ARM Template that will allow us to implement each Certified Component.

See ARM Template development best practices in the [ARM Template](/Learning-resources/Infrastructure-as-Code/ARM-Templates.md) section

In the ARM Template, we will only include:
- The Resource Type that the Certified Component will deploy.
- Outputs and secrets management leveraging Key Vault when required

## Pre/post deployment scripts

When required, we can include [idempotent](/Learning-resources/Infrastructure-as-Code/IaC-Modules.md) pre or post deployment scripts.

These pre/post deployment scripts can be developed leveraging the Az PowerShell Certified Component. Learn more about this Certified Component in the [PowerShell](/Learning-resources/Infrastructure-as-Code/PowerShell.md) section.

While typically these pre/post deployment scripts have been deployed separately from the ARM Templates, a new ARM Template functionality in Preview allows us to [integrate these script as part of our ARM Template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template?tabs=CLI) using the resource type `Microsoft.Resources/deploymentScripts`.

The [Certified Component deployment script](#module-deployment-script) will be responsible of running this pre/post deployment script with the right parameters from the configuration file

## Policy definitions, initiatives and assignments

For Azure Policies, we need to consider the following assets:
- [**Policy Definition**](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure). Policy definitions describe resource compliance conditions and the effect to take if a condition is met. A condition compares a resource property field or a value to a required value. Resource property fields are accessed by using aliases. When a resource property field is an array, a special array alias can be used to select values from all array members and apply a condition to each one.
- [**Initiative Definition**](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/initiative-definition-structure). Initiatives enable you to group several related policy definitions to simplify assignments and management in a single item.
- [**Policy Assignment**](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/assignment-structure). Policy assignments are used by Azure Policy to define which resources are assigned which policies or initiatives.

Our [Governance](/Foundation-Design/Governance.md) design allows us to group custom policies and built-in policies in different Initiatives and assign these initiatives to different scopes.

![Governance overview](/.attachments/images/Foundation-Design/platform-design-governance.png)

- **Cloud-Native Management Group**. Initiatives or Policies assigned at this scope will apply to any subscriptions and child resources belonging to the [Cloud-Native Landing Zone](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).
- **Sandbox Management Group**. Initiatives or Policies assigned at this scope will apply to Sandbox subscriptions and child resources belonging to the [Cloud-Native Landing Zone](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).
- **Non-Production Management Group**. Initiatives or Policies assigned at this scope will apply to Non-Production subscriptions and child resources belonging to the [Cloud-Native Landing Zone](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).
- **Production Management Group**. Initiatives or Policies assigned at this scope will apply to Production subscriptions and child resources belonging to the [Cloud-Native Landing Zone](/Foundation-Design/Cloud%2DNative-Landing-Zone.md).

With this hierarchy, during the [Certification Process](/Certification-Process.md) we will determine what policies must be applied for each scope. Then we will code each policy in a separate configuration file (`policy.{displayName}.parameters.json`) and group the policies for each scope in an initiative configuration file (e.g. `policyset.{component-name}-cloud-native.parameters.json` will group policies that are deployed at cloud-native management group scope). Policy assignments (`policyassignment.parameters.json`) will assign the initiative at the targeted scoped.

```
IaC/
└───modules/
    └───{component-name}/
        └───{Major}.{Minor}/
            |───deploy.json
            |───README.md
            └───policies/
                |──cloud-native-mg/
                |  |──policyDefinition.{name}parameters.json
                |  |──policyDefinition.{name}parameters.json
                |  |──policyset.{component-name}-cloud-native.parameters.json
                |  └──policyassignment.parameters.json
                |──sandbox-mg/
                |  |──policyDefinition.{name}parameters.json
                |  |──policyDefinition.{name}parameters.json
                |  |──policyset.{component-name}.parameters.json
                |  └──policyassignment.parameters.json
                |──non-production-mg/
                |  |──policyDefinition.{name}parameters.json
                |  |──policyDefinition.{name}parameters.json
                |  |──policyset.{component-name}.parameters.json
                |  └──policyassignment.parameters.json
                └──production-mg/
                   |──policyDefinition.{name}parameters.json
                   |──policyDefinition.{name}parameters.json
                   |──policyset.{component-name}.parameters.json
                   └──policyassignment.parameters.json
```

Both [policy definition](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#metadata) and [initiative definition](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/initiative-definition-structure#metadata) resource types can be versioned using the `metatada` property. The Azure Policy service uses the fields `version`, `preview`, and `deprecated` properties to convey level of change to a built-in policy definition or initiative and state. The format of version is: `{Major}.{Minor}.{Patch}`. Specific states, such as deprecated or preview, are appended to the version property or in another property as a `boolean`. For more information about the way Azure Policy versions built-ins, see [Built-in versioning](https://github.com/Azure/azure-policy/blob/master/built-in-policies/README.md).

## Test locally

[ARM Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview#template-deployment) can be deployed in several ways (through the Azure Portal, Azure CLI, AzureAz PowerShell, etc).

We can use the [New-AzDeployment](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azdeployment?view=azps-3.6.1) cmdlet in PowerShell Az to deploy the ARM Template in our Resource Group in the Test Environment

See the article [Sign in with Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/authenticate-azureps?view=azps-3.6.1) to learn how to log in to Azure and test deployments of ARM Templates and PowerShell scripts locally.

# References

1. [Deploy resources with ARM templates and Azure PowerShell | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-powershell)
2. [Sign in with Azure PowerShell | Microsoft Docs](https://docs.microsoft.com/en-us/powershell/azure/authenticate-azureps?view=azps-4.4.0&viewFallbackFrom=azps-3.6.1)
3. [ARM Templates](/Learning-resources/Infrastructure-as-Code/ARM-Templates.md)
4. [Azure PowerShell](/Learning-resources/Infrastructure-as-Code/PowerShell.md)