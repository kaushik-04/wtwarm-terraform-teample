# New-AdoPipeline PS1 User Guide

This PowerShell script will create the pipelines in Azure DevOps for testing and publishing all the modules.

The script will look for `pipeline.yml` files **in the local copy** (on your laptop) of the repository and create a build pipeline for each module found. Make sure you pulled the latest version.

The folder structure of the modules, `<moduleName>\Pipeline\pipeline.yml`, needs to be kept for each module.

## Prerequisites

- [Azue CLI 2.13.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Azure DevOps CLI extension devops 0.18.0](https://docs.microsoft.com/en-us/azure/devops/cli/?view=azure-devops)
- Repository for which the pipeline needs to be configured
- Optional: The '<ProjectName>' Build Service needs 'Edit build pipeline' permissions ([reference](https://docs.microsoft.com/en-us/azure/devops/pipelines/policies/permissions?view=azure-devops#pipeline-permissions))

> **Note** <br>
>The PAT you use to log in with using Azure CLI (az login) must logically have permission `'Edit build pipeline'` permissions ([reference](https://docs.microsoft.com/en-us/azure/devops/pipelines/policies/permissions?view=azure-devops#pipeline-permissions)) in the organization or project.

## Command syntax

```
New-AdoPipeline.ps1 [-OrganizationName] <string> [-ProjectName] <string> [-RepositoryName] <string> [-PAT] <PAT>
```

- OrganizationName: Required. The name of the Azure DevOps organization.
- ProjectName: Required. The name of the Azure DevOps project.
- RepositoryName: Required. Repository for which the pipeline needs to be configured.
- BranchName: Optional. Branch name for which the pipelines will be configured. Default: `'master'`.
- PipelineTargetPath: Optional. Path of the folder where the pipeline needs to be created. Default: `'Modules'`.
- PipelineSourcePath: Optional. Path of the pipelines yaml file(s) to be used for creating Azure Pipelines. Default is the execution path `'/.'` of this script.
- createBuildValidation: Optional. Create Pull Request Build Validation in additon.
- ModuleFilter: Optional. Choose which Modules to create pipelines for. By default, Pipelines will be created for all modules in the PipelineSourcePath .

## Example

`New-AdoPipeline -OrganizationName servicescode -ProjectName infra-as-code-source -RepositoryName Components -PAT <PAT>`

Create all pipelines for the project `'servicescode/infra-as-code-source'` using a `PAT`.
The Azure Pipelines will be configured to use the default branch `'master'` and the given repository name `'Components'`.
The Azure Pipelines will be create in the default folder path Modules.

Given the `'PipelineSourcePath'` and the default source folder pattern (`/Modules/<ModuleName>/Pipeline/pipeline.yml`) the script will browse all *.yml files in the 
and takes the `'<ModuleName>'` folder as the desired name for the Azure Pipeline to be created.

`New-AdoPipeline -OrganizationName servicescode -ProjectName infra-as-code-source -RepositoryName Components -PAT <PAT> -ModuleFilter @("ActivityLog","StorageAccount")`

Creates only the ActivityLog and StorageAccount pipelines.
