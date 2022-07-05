[[_TOC_]]

# Overview

Certified components consists of different assets.
- **Azure DevOps Artifact**. Each component will have a reusable idempotent pre-approved script or ARM template that can be used in an Azure DevOps Pipeline and a README.md file package as an Azure DevOps artifact.
- **Azure Policies**. Each component will have a set of Azure Policies that take effect in all the [Cloud-Native Landing Zones](/Foundation-Design/Cloud%2DNative-Landing-Zone.md) and guarantee or enforce that the Azure Products are configured as defined in the Policy rules.

All assets mentioned above will follow a versioning strategy that will help release software often and consistently and avoid breaking backward compatibility.

# Overall versioning strategy

> Packages are [immutable](https://docs.microsoft.com/en-us/azure/devops/artifacts/artifacts-key-concepts?view=azure-devops#immutability) – this means once you publish a particular version of a package to a feed, that version number is permanently reserved. You cannot upload a newer revision package with that same version number, or delete it and upload a new package at the same version.

When creating packages in continuous integration and delivery scenarios, it's important to convey three pieces of information: the **nature of the change**, the **risk of the change**, and the **quality of the change**.

![Versioning strategy for packages](https://docs.microsoft.com/en-us/azure/devops/artifacts/concepts/media/release-views-quality-nature.png)

The **nature and the risk of the change both pertain to the change itself**, that is, what you set out to do, they're both known at the outset of the work. If you're introducing new features, making updates to existing features, or patching bugs; this is the nature of your change. If you're still making changes to the API portion of your application; this is one facet of the risk of your change. Many NuGet users use [Semantic Versioning (SemVer)](https://semver.org/) notation to convey these two pieces of information. SemVer is a widely used standard and does a good job of communicating this type of information.

The **quality of the change** isn't generally known until the validation process is complete. This comes after your change is built and packaged. Because of this detail, it's not feasible to communicate the quality in the version number, which is specified during packaging and before validation

As general guidance, in the case of certified components:
- **Nature of Change: `{Major}.{Minor}.{Patch}`**.
  1. `{Major}` version will be incremented every time a new requirement is identified and will drive to a new [Certification Process](/Certification-Process.md) due to any limitation of the current version of the component. New requirements can be of the following types.
  2. `{Minor}` version will be incremented every time a bug or update is identified and the component can be updated without affecting the agreements of the [Certification Process](/Certification-Process.md).
  3. `{Patch}` will be calculated based on timestamp for those assets that will be produced as a result of a pipeline (e.g. artifact). This will allow to publish several versions of the same artifact during packaging and before validation.
- **Quality of change**. Quality of change will be used to determine the source branch where the artifact is coming from. Our  branching strategy indicates that code in `master` or `main` have been validated and is ready for production scenarios.

E.g. version `1.01.2021011201-master` indicates that:
- Major: 1. The component has gone through Certification Process one time
- Minor: 1. One update has been made to the component without affecting agreements of the Certification Process
- Patch: 2021011201. The component was released the 12th of January 2021, and it is the first revision produced that day.
- Quality: master. The component comes from the master branch and thus has passed all validations/reviews.

# Repository

The `IaC` repository will be the first where the new version of the component will start. The IaC repository is designed to become a [Inner Source](https://innersourcecommons.org/) repository and allow contributions from other teams inside contoso, so versioning at repository level is important to drive a good governance. We have two tools to manage versioning at Repository level:
1. Directory structure. The repository is organized in folders that follow component versioning strategy with `{Major}` and `{Minor}` versions only.
2. Branching strategy. The branching strategy followed allows to only accept code in the `master` or `main` branch after validation and Pull Request approval. That means the code in the `master` / `main` branch is stable.

In the `IaC` repository, each component will be placed under the `/modules` directory (see [README.md](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC)):

```
IaC/
└───modules/
    |
    └───{component-name}/
    |       |
    |       └───{Major}.{Minor}/
    |           |   deploy.json
    |           |   README.md
    |           └   ...
```

Code in `master` / `main` branch can be considered to be stable.

Versioning strategy for Repository will be then:
- **Nature of Change: `{Major}.{Minor}`**.
  1. `{Major}` version will be incremented every time a new requirement is identified and will drive to a new [Certification Process](/Certification-Process.md) due to any limitation of the current version of the component. New requirements can be of the following types.
  2. `{Minor}` version will be incremented every time a bug or update is identified and the component can be updated without affecting the agreements of the [Certification Process](/Certification-Process.md).
- **Quality of change**.
  1. `master` branch is always in a state that has been validated and released.
  2. Any other branch contain code in development that has not been validated and cannot be used.

E.g. version `1.01` in the `master` branch indicates that:
- Major: `1`. The component has gone through Certification Process one time
- Minor: `01`. One update has been made to the component without affecting agreements of the Certification Process
- Quality: `master`. The component comes from the master branch and thus has passed all validations/reviews.

# Azure Artifacts

The workflow to be follow to generate artifacts packages is as below

![Artifacts workflow](https://cloudblogs.microsoft.com/industry-blog/wp-content/uploads/industry/sites/22/2019/06/dev-workflow.png)

1. Developer pulls the latest changes from the `master` branch on to their local machine.
2. The developer then creates a feature branch from `master`. e.g `feature\my-awesome-feature`
3. Makes the changes to the code and commits the changes in feature branch.
4. As soon as the commit is made and synced with Azure DevOps, Azure DevOps CI pipeline triggers.
5. CI build creates the NuGet package, versions it (tag NuGet package alpha)
6. Pushes the package to Artifacts.
7. The developer now consumes the latest alpha NuGet package from Artifacts and tests it locally.
8. Once the developer is satisfied, they are ready to make the pull request to merge the changes from the feature branch to the stable `master` branch.
9. Makes PR (pull request) to `master`, allowing others to validate and provide review comments if any.
10. Now CI build triggers for the `master` branch.
11. CI build compiles the code and validates changes.
12. Once the build is successful, the new NuGet package from `master` (without alpha tag) is pushed to the Artifacts feed.

Versioning strategy for Artifacts will be then:
- **Nature of Change: `{Major}.{Minor}`**.
  1. `{Major}` version will be incremented every time a new requirement is identified and will drive to a new [Certification Process](/Certification-Process.md) due to any limitation of the current version of the component. New requirements can be of the following types.
  2. `{Minor}` version will be incremented every time a bug or update is identified and the component can be updated without affecting the agreements of the [Certification Process](/Certification-Process.md).
  3. `{Patch}` will be calculated by the publishing pipeline based on timestamp. This will allow to publish several versions of the same artifact during packaging and before validation.
- **Quality of change**.
  1. `master` indicates that the artifact is coming from the `master` branch and then has been validated and released.
  2. Any other tag indicates that the artifact is coming from a feature branch that has not been validated and should not be used.

E.g. version `1.1.0` indicates that:
- Major: `1`. The artifact has gone through Certification Process one time.
- Minor: `1`. One deprecated feature update has been made to the component without affecting agreements of the Certification Process.
- Patch: `1`. One bug has been fixed without affecting agreements of the Certification Process.
- Quality: `empty`. The component comes from the master branch and thus has passed all validations/reviews.

# Azure Policies

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

With this hierarchy, during the [Certification Process](/Certification-Process.md) we will determine what policies must be applied for each scope. Then we will code each policy in a separate configuration file and group the policies for each scope in an initiative configuration file. Policy assignments will assign the initiative at the targeted scopes. All files in the structure follow the [naming convention](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/808/Naming-Conventions) which is structured in a canonical way, with a free text segment, where information about the policy and its use will be visible.

```
IaC/
└───modules/
    └───{component-name}/
        └───{Major}.{Minor}/
            |───deploy.json
            |───README.md
            └───policies/
                |──policyDefinitions/
                |  |──{policyName#1}.json
                |  └──{policyName#2}.json
                |──initiativeDefinitions/
                |  |──{initiativeName#1}.json
                |  └──{initiativeName}.json
                └──policyAssignment/
                   └──assignments.json

```

Both [policy definition](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#metadata) and [initiative definition](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/initiative-definition-structure#metadata) resource types can be versioned using the `metatada` property. The Azure Policy service uses the fields `version`, `preview`, and `deprecated` properties to convey level of change to a built-in policy definition or initiative and state. The format of version is: `{Major}.{Minor}.{Patch}`. Specific states, such as deprecated or preview, are appended to the version property or in another property as a `boolean`. For more information about the way Azure Policy versions built-ins, see [Built-in versioning](https://github.com/Azure/azure-policy/blob/master/built-in-policies/README.md).

## Rollout strategy

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

Let's see with an example.

E.g. Key Vault Certified Component 1.0 `audit` when `enablePurgeProtection` is set to `false`. For Key Vault Certified Component 2.0, the policy must `deny` deployments when `enablePurgeProtection` is set to `false`.

Key Vault 1.0 containing the following policies:

```
key-vault/
└───1.0/
    |───deploy.json
    |───README.md
    └───policies/
        |──policyDefinition/
        |  |──pxs-cn-kvt-rbac-pd.json
        |  |──pxs-cn-kvt-purge-pd.json
        |  |──pxs-cn-kvt-privateEndpoint-pd.json
        |  └──pxs-cn-kvt-sku-pd.json
        |──initiativeDefinitions/
        |  └──pxs-cn-kvt-pi.json
        └──policyAssignment/
            └──assignments.json
```

Where:

**policyDefinition/pxs-cn-kvt-purge-pd.json** allows to create and publish the Policy Definition for validation of purge protection. This Policy will be assignable at Cloud-Native Management Group scope and all child resources.

Example: [IaC/modules/keyvault/1.0/policies/policyDefinitions/pxs-cn-kvt-purge-pd.json](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fkeyvault%2F1.0%2Fpolicies%2FpolicyDefinitions%2Fpxs-cn-kvt-purge-pd.json)

**policyInitiative/pxs-cn-kvt-pi.json** allows to group all Policy Definitions for Cloud-Native Mangement Group. This Initiative will be assignable at Cloud-Native Management Group scope and all child resources.

Example: [IaC/modules/keyvault/1.0/policies/initiativeDefinitions/pxs-cn-kvt-pi.json](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fkeyvault%2F1.0%2Fpolicies%2FinitiativeDefinitions%2Fpxs-cn-kvt-pi.json)

**policyAssignment/parameters.json** allows assign the Initiative at Cloud-Native Management Group scope. With this assignment, all policies in the Initiative will start to take the configure effect.

Example: [IaC/modules/keyvault/1.0/policies/policyAssignments/assignments.json](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fkeyvault%2F1.0%2Fpolicies%2FpolicyAssignments%2Fassignments.json)

For Key Vault 2.0, the decision is to force purge protection to be enabled for any key vault. Given that the current policy is already deployed:
1. All impacted Key Vaults will already be identified given the audit effect of Key Vault 1.0
2. For each impacted Key Vault:
   1. The owners of the Key Vaults need to be advised about the new policy that will be released
   2. A remediation plan needs to be agreed
   3. If a remediation plan is not possible, the agreed [exclusions](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/scope#assignment-scopes) are applied at assignment level
3. The release date is communicated to the Platform Teams
4. The policy is released with the appropriate effect and exclusions.
5. In case the policy impacts any unexpected resource, version 1.0 of the Key Vault is re-deployed.

Key Vault 2.0 will have the following files:

```
key-vault/
|───1.0/
|   |───deploy.json
|   |───README.md
|   └───policies/
|       |──policyDefinitions/
|       |  └──pxs-cn-kvt-purge-pd.json
|       |──policyInitiatives/
|       |  └──pxs-cn-kvt-pi.json
|       └──policyAssignment/
|           └──assignment.json
└───2.0/
    |───deploy.json
    |───README.md
    └───policies/
        |──policyDefinitions/
        |  └──pxs-cn-kvt-purge-pd.json
        |──policyInitiatives/
        |  └──pxs-cn-kvt-pi.json
        └──policyAssignment/
            └──assignment.json
```

Where the applicable files, the versioning fields will be used to align the policy with the version of the component:


## Evaluate the impact of a new Azure Policy definition

> Read article [Evaluate the impact of a new Azure Policy definition](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/evaluate-impact)

Azure Policy is a powerful tool for managing your Azure resources to business standards and to meet compliance needs. When people, processes, or pipelines create or update resources, Azure Policy reviews the request. When the policy definition effect is Modify, Append or DeployIfNotExists, **Policy alters the request or adds to it**. When the policy definition effect is Audit or AuditIfNotExists, Policy causes an Activity log entry to be created for new and updated resources. And **when the policy definition effect is Deny, Policy stops the creation or alteration of the request**.

These outcomes are exactly as desired when you know the policy is defined correctly. However, **it's important to validate a new policy works as intended before allowing it to change or block work**. The validation must ensure only the intended resources are determined to be non-compliant and no compliant resources are incorrectly included (known as a false positive) in the results.

The recommended approach to validating a new policy definition is by following these steps:

- Tightly define your policy
- Audit your existing resources
- Audit new or updated resource requests
- Deploy your policy to resources
- Continuous monitoring

# References

- [Versioning](https://docs.microsoft.com/en-us/dotnet/standard/library-guidance/versioning)
- [Perfecting Continuous Delivery of NuGet packages for Azure Artifacts](https://cloudblogs.microsoft.com/industry-blog/en-gb/technetuk/2019/06/18/perfecting-continuous-delivery-of-nuget-packages-for-azure-artifacts/)
- [Policy Definition Structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#metadata)
- [Evaluate the impact of a new Azure Policy definition](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/evaluate-impact)
- [Design Azure Policy as Code workflows](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-as-code)
- [Built-in Azure Policies versioning](https://github.com/Azure/azure-policy/blob/master/built-in-policies/README.md)