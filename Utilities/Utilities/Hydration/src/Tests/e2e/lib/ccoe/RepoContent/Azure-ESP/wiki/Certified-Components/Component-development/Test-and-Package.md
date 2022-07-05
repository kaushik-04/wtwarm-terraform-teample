[[_TOC_]]

# Overview

During the Test and Package phase, we will test that the Certified Component that we developed during the [Develop](/Certified-Components/Component-development/Design.md) phase has the right quality. Also, we will package the Certified Component according to our [Versioning Strategy](/Certified-Components/Component-versioning.md). For each Certified Component we will test and package:
- The Certified Component into an Azure DevOps Artifact that will contain:
  - ARM Templates / Idempotent scripts
  - `README.md` documentation file 
- Policy Definitions and Initiatives

We will automate this phase so that all the testing and publishing steps run automatically with each commit and Pull Request. With this automation, we implement [Continuous Integration](https://docs.microsoft.com/en-us/learn/modules/analyze-devops-continuous-planning-intergration/3-analyze-continuous-integration). Continuous Integration is a Mindset and a Team Strategy. Continuous Integration is described as a software development practice where members of a team integrate their work frequently, usually each person integrates at least daily - leading to multiple integrations per day.

![Continuous Integration](/.attachments/images/Learning-resources/Infrastructure-as-Code/cicd.png)

Each integration is verified by an automated build (including test) to detect integration errors as quickly as possible.

When done right, this approach leads to reduced integration problems by catching them earlier in the process.

The goals of Continuous Integration are to:

- Harness [collaboration](https://docs.microsoft.com/en-us/learn/modules/characterize-devops-continous-collaboration-improvement/2-explore-continuous-collaboration)
- Enable parallel development
- Minimize integration debt
- Act as a [quality gate](https://docs.microsoft.com/en-us/learn/modules/explain-devops-continous-delivery-quality/3-explore-continuous-quality)
- [Automate everything!](https://docs.microsoft.com/en-us/learn/modules/explain-devops-continous-delivery-quality/2-use-continuous-delivery-release-faster)

# Checklist

- [X] Create the `build.yml` file that will contain the [build pipeline](#build-pipelines-for-certified-components) for the Certified Component
- [X] Develop the [Unit Tests](#unit-testing) and include those as a step in the build.yml file
- [X] Add the step to publish the Certified Component as an [Certified Component artifact](#certified-component-artifact)
- [X] Decide [rollout strategy](#rollout-strategy-for-azure-policies) for the Azure Policies and analyze the impact

# Guidance

## Build pipelines for Certified Components

In Azure DevOps, [Azure Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/?view=azure-devops) will be used for automating builds for Certified Components.

Common Activities during the automated build:
- Coding Standards Checking
- Download Dependent Packages
- Build Code
- [Unit Testing](#unit-testing)
- Code Coverage Analysis
- Cred Scan
- Static Code Analysis
- Open Source Component Scan
- In Memory Code Validation
- [Create Deployable Package](#iac-module-artifact)

For Certified Components, our build pipelines will be treated as code by using [multi-stage](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/multi-stage-pipelines-experience?view=azure-devops) [YAML pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema?view=azure-devops&tabs=schema).

## Unit Testing

Unit Testing can be implemented for ARM Templates and for PowerShell scripts using the following tools:
- [Azure Resource Manager Template Toolkit (arm-ttk)](https://github.com/Azure/arm-ttk)
- [Pester](https://pester.dev/)

Once developed, the unit testing can be added as a step in the [build pipeline for Certified Components](#build-pipelines-for-iac-modules).

## Certified Component artifact

Every time a [build pipeline](#build-pipelines-for-iac-modules) has successfully ran, we will create a [deployable package](/Certified-Components/Component-versioning.md) in the form of [build artifact](https://docs.microsoft.com/en-us/azure/devops/pipelines/artifacts/artifacts-overview?view=azure-devops).

The build artifact will guarantee to anyone reusing the artifact that the code has passed all tests implemented as steps in the build pipeline.

The deployable package in the Certified Component artifact will contain at least the following files:
- The Certified Component deployment script
- The ARM Templates
- The Pre/Post deployment Scripts

These files will allow us to use the Certified Component in a [deployment pipeline](/Certified-Components/Component-deployment.md) in azure DevOps.

Artifacts from the `master` branch will be ready for general use

Artifacts from the [feature](/Certified-Components/Component-versioning.md) branch are in development and should not be used for deployments to production environments.

## Rollout strategy for Azure Policies

Both [policy definition](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#metadata) and [initiative definition](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/initiative-definition-structure#metadata) resource types can be versioned using the `metatada` property. The Azure Policy service uses the fields `version`, `preview`, and `deprecated` properties to convey level of change to a built-in policy definition or initiative and state. The format of version is: `{Major}.{Minor}.{Patch}`. Specific states, such as deprecated or preview, are appended to the version property or in another property as a `boolean`. For more information about the way Azure Policy versions built-ins, see [Built-in versioning](https://github.com/Azure/azure-policy/blob/master/built-in-policies/README.md).

The `version` metadata property is useful to inform about the version of the policy. However, Policy definitions and initiative definitions will be updated every time they are published with they same resource `name` property. This implies:
- **Only the policy definition and initiatives in published in the latest component version will take effect** (every time we publish, we override policy definition and initiatives)
- **We can do rollback if we re-deploy a previous version** of a policy or initiative
- Once the assignment is done, **a new deployment of a policy definition or initiative will immediately take effect in the assigned scopes**.

Given these implication, naming convention for Policies and Initiatives will allow to plan for a **rollout strategy to validate the desired effect before affecting production workloads** for each new versions of the policy. 

The recommended general workflow of Azure Policy as Code looks like this diagram:

![Policy as Code workflow](https://docs.microsoft.com/en-us/azure/governance/policy/media/policy-as-code/policy-as-code-workflow.png)

The workflow above is valid for policies with an effect:
1. Policy will be released in `audit`/`auditIfNotExists` effect first.
2. All impacted resources will be identified with a warning event in the activity log.
3. For each impacted resource:
   1. The owners of the resource need to be advised about the new policy that will be released.
   2. A remediation plan needs to be agreed
   3. If a remediation plan is not possible, a [exclusion](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/scope#assignment-scopes) can be applied at assignment level.
4. The release date will be communicated to the resource owners
5. The policy is updated with the appropriate effect.
6. In case the policy impacts any unexpected resource, the previous version of the resource with policy in effect mode will be re-deployed. This will revert Policy Definition, Initiatives and Assignments to the previous `audit`/`auditIfNotExists` effect.

See section [Component versioning](/Certified-Components/Component-versioning.md) for more examples

# References

1. [Analyze Continuous Integration | Microsoft Learn](https://docs.microsoft.com/en-us/learn/modules/analyze-devops-continuous-planning-intergration/3-analyze-continuous-integration)
2.  [Pester Quick Start | pester.dev](https://pester.dev/docs/quick-start) 
3.  [What is Pester and Why Should I Care? | Microsoft Dev Blogs](https://devblogs.microsoft.com/scripting/what-is-pester-and-why-should-i-care/)
4.  [Azure DevOps artifacts | Microsoft Docs](https://docs.microsoft.com/en-us/azure/devops/pipelines/artifacts/artifacts-overview?view=azure-devops)
5.  [Predefined Build variables | Microsoft Docs](https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml)
6.  [YAML schema reference | Microsoft Docs](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema?view=azure-devops&tabs=schema)