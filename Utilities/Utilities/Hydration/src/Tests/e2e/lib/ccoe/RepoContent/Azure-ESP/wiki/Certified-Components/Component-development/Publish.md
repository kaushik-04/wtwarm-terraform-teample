[[_TOC_]]

# Overview

During the Publish phase, we will make the Certified Component that we validated during the [Test and Package](/Certified-Components/Component-development/Test-and-Package.md) phase available to all teams in the organization. Also, we will publish the agreed policies so that they start taking effect.

As in the previous phase, will automate this phase so that all the publishing steps run automatically on our demand. This automation must allow us to follow the agreed rollout strategy as defined in section [Component Versioning ](/Certified-Components/Component-versioning.md). The rollout strategy will enable us also to rollback in case we identify any incident affecting production workloads. This strategy is commonly know as [Continuous Delivery](https://docs.microsoft.com/en-us/learn/modules/explain-devops-continous-delivery-quality/2-use-continuous-delivery-release-faster)

Continuous Delivery is a software engineering approach in which teams produce software in short cycles, ensuring that the software can be:
- Reliably released at any time
- Released manually

[Continuous Integration](/Certified-Components/Component-development/Test-and-Package.md) is a prerequisite for Continuous Delivery. Practices in place enable building and (reliably) deploying the application at any time and with high quality, from source control.

![Continuous Delivery](/.attachments/images/Learning-resources/Infrastructure-as-Code/cicd.png)

The purpose of Continuous Delivery is to:
- Build, test, and release software with greater speed and frequency
- Reduce the cost, time, and risk of delivering changes by allowing for more incremental updates to applications in production

Continuous Delivery happens when:

- Software is deployable throughout its lifecycle
- Continuous Integration as well as extensive automation are available through all possible parts of the delivery process, typically using a deployment pipeline
- It’s possible to perform push-button deployments of any version of the software to any environment on demand

# Checklist

- [X] Validate the deployment of the [Certified Component artifact](#test-certified-component-deployment) in our [environments](#environments) for IaC development.
- [X] Validate our rollout strategy for [the Azure Policies](#test-azure-policies-rollout-strategy) in our [environments](#environments) for IaC development.
- [X] Review and [update the README.md file](#update-the-readmemd-file) with all decisions taken.
- [X] Create a [Pull Request](#pull-request) to merge the Certified Component from the development branch to the `master` branch
- [X] Trigger the publishing pipeline once the Pull Request has been approved
- [X] [Announce](#announce-publishing) the release of the Certified Component

# Guidance

## Environments

Once published, Certified Components will be used to deploy and manage Infrastructure as Code for different environments.

From Certified Components perspective, any environment not designed for Certified Component development will be considered as a production environment, meaning that our published Certified Components should work well when used in development environment or in production environments. Once we publish a Certified Component.

Then we need to define our own environments for testing our Certified Components during the whole [Certified Component development](/Certified-Components/Component-development/Develop.md) cycle to be able to enable a Continuous Delivery strategy for Certified Component Development.

For our Certified Components:
- The code not merged to the `master` branch will be considered as non-production code, as described in our [versioning strategy](/Certified-Components/Component-versioning.md)
- We will [test deployment of our Certified Components](#test-IaC-module-deployment) before releasing the code to the `master` branch in a Resource Group for IaC development.

## Test Certified Component deployment

Certified Components are designed to be used from an [Azure DevOps Release Pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/release/?view=azure-devops). For that reason, before publishing an Certified Component we need to test that it is deployed in a Release Pipeline as expected.

For each Certified Component, we will create a Release Pipeline Definition under the `/Test` directory with the name `Test-[ModuleName][ModuleVersion]` (e.g. `Test-KeyVault1.0`).

This Release Definition will test the artifact generated from the development branch:
- We will add the [artifact](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/key-pipelines-concepts?view=azure-devops#artifact) resulting form the build pipeline we created in the [Test and Package](/Certified-Components/Component-development/Test-and-Package.md) phase. This artifact can be [configured to be triggered automatically](https://docs.microsoft.com/en-us/azure/devops/pipelines/release/triggers?view=azure-devops#release-triggers) on every new artifact from a development branch

We will create the following [stages](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/key-pipelines-concepts?view=azure-devops#stage):
- A `prerequisites` stage where we are going to deploy all the dependencies for the Certified Component. E.g., if our Certified Component is a Virtual Machine, it will define a Virtual Network as a dependency. We will deploy that Virtual Network in the `prerequisites` stage.
- A stage with the name `[environment name]-[resource group name]`, `environment name` is the name of the environment that we have defined as our environment for IaC testing (e.g. `IaC test`) and `resource group name` is the name of the Resource Group created for this environment. This stage will be [triggered](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started/key-pipelines-concepts?view=azure-devops#trigger) after the prerequisites environment has successfully deployed.
- A stage with the name of `remove-[environment name]-[resource group name]` where we are going to test the remove operations. This stage should be configured to be triggered manually

## Test Azure Policies rollout strategy

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

## Update the README.md file

The README.md file of the Component will be used for the [Cloud-Native Landing Zone Teams](/Foundation-Design/Cloud%2DNative-Landing-Zone.md) to understand the design decisions, learn how to use the component in their pipelines and understand the effect of the published Azure Policies.

## Pull Request

Once we are done with our Certified Component and want to make it generally available, we need to merge the changes back to the master branch. We will follow a [Pull Request](https://docs.microsoft.com/en-us/azure/devops/repos/git/pull-requests?view=azure-devops) process where a peer will review the changes that we want to add to the master branch.

## Publish Certified Component

Based on our [Certified Component design principles](/Certified-Components/Design-principles.md), our publishing strategy will consist of publishing a build artifact in the master branch that can be reused by any team.

For publishing a Certified Component we will have to:
- Create a deployment pipeline that will package and publish the Certified Component as an Azure DevOps Artifact.
- Merge the development branch to the master branch via [Pull Request](#pull-request). 

## Announce publishing

A Certified Component is driven by the requirements of one or more [Cloud-Native Landing Zone Teams](/Foundation-Design/Cloud%2DNative-Landing-Zone.md). These teams will be affected by the Policies and the decisions taken during the Certified Component lifecycle.

Announcing the release of a Certificate Component is important for these teams to start using the Component for their use cases and to understand what Azure Policies will affect their deployments.

# References

1. [Continuous Delivery](https://docs.microsoft.com/en-us/learn/modules/explain-devops-continous-delivery-quality/2-use-continuous-delivery-release-faster)
2. [Task groups for builds and releases](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/task-groups?view=azure-devops)
3. [Pull Request](https://docs.microsoft.com/en-us/azure/devops/repos/git/pull-requests?view=azure-devops)