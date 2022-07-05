[[_TOC_]]

# Overview

Azure Pipelines will be the place to combine the [Configuration files](/Certified-Components/Component-deployment/Edit-the-configuration-file.md) with the [published Certified Components](/Certified-Components.md) to manage all our [Infrastructure as Code](/Learning-resources/Infrastructure-as-Code.md).

# Checklist

- [X] Create the [YAML pipeline](#create-the-yaml-pipeline).
- [x] Add the step to [download the Certified Component artifact](#download-certified-component-artifact)
- [X] Add the step to [deploy the Certified Component to Azure](#deploy-the-certified-component-to-azure)

# Guidance

## Create the YAML pipeline

Same as with our [configuration files](/Certified-Components/Component-deployment/Edit-the-configuration-file.md), our [Release Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/release/?view=azure-devops) need to be readable so that we can easily find, manage, deploy and redeploy our infrastructure when desired.

We can follow these guidelines when designing for a Release Pipeline for infrastructure:
- Infrastructure will typically have a lifecycle different than the application code. For this reason, the infrastructure related to an workload will be managed in a Release Definition separate from the Release Definition for the workload code.
- Within each Release Definition for the infrastructure, we will create a [stage](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/stages?view=azure-devops&tabs=classic) for each environment that we are going to manage.
- Withing each stage, each resource that needs to be deployed will be configured as a step using the Task Group related to the module that allows to configure the resource.

## Download Certified Component artifact

tbd

## Deploy the Certified Component to Azure

tbd

## Remove infrastructure as code from pipelines

Although not frequent, in some occasions will will want to remove pieces of our infrastructure. For instance, for testing environments we will want to run some tests over some infrastructure and remove this infrastructure once the test has run.

This will allow us to optimize costs and maintain a health environment.

For this goals, we can implement:
- Release pipelines that will empty resource groups on a scheduled basis.
- For each release pipeline for infrastructure management, create stages to deprovision infrastructure using the remove operations implemented within each Certified Component.

# References

1. [Infrastructure as Code](/Learning-resources/Infrastructure-as-Code.md)
2. [Certified Component Design Principles](/Certified-Components/Design-principles.md)
3. [Repository strategy for Certified Components deployment](/Certified-Components/Component-versioning.md)
4. [Add stages, dependencies, & conditions](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/stages?view=azure-devops&tabs=classic)