# Platform repo

[[_TOC_]]

## Introduction

This repository contains the configuration, parameter and pipeline files used for deploying and configuring Landing Zones within the organization.

## Repository structure

Overview of the repository structure:

``` txt
Platform (root)
|   .gitignore
│   README.md
│   tenant.variables.yml
|
└───teams
|   └───<teamname>
|   |   |   pipeline.yml
|   |   └───parameters
|   |       └───<resourceTypeName>
|   |       |       <resourceName>.json
|   |       └───<resourceTypeName>
|   |               <resourceName>.json
|   └───<teamname>
|       |   pipeline.yml
|       └───parameters
|           └───<resourceTypeName>
|           |       <resourceName>.json
|           └───<resourceTypeName>
|                   <resourceName>.json
|
└───.global
|       global.variables.yml
|
└───parameters
|   └───<resourceTypeName>
|   |       <resourceName>.json
|   └───<resourceTypeName>
|           <resourceName>.json
|
└───<managementGroupName>
|   |   pipeline.yml
|   |   mg.variables.yml
|   └───parameters
|   |   └───<resourceTypeName>
|   |   |       <resourceName>.json
|   |   └───<resourceTypeName>
|   |           <resourceName>.json
|   |
│   └───<childManagementGroupName>
|   |   |   pipeline.yml
|   |   |   mg.variables.yml
|   |   └───parameters
|   |   |   └───<resourceTypeName>
|   |   |   |       <resourceName>.json
|   |   |   └───<resourceTypeName>
|   |   |           <resourceName>.json
|   │   |
|   |   └───<subscriptionName>
|   |   |   |   pipeline.yml
|   |   |   |   sub.variables.yml
|   |   |   └───parameters
|   |   |   |   └───<resourceTypeName>
|   |   |   |   |       <resourceName>.json
|   |   |   |   └───<resourceTypeName>
|   |   |   |   |       <resourceName>.json
|   |   |   |   └───...
|   |   |   |
|   |   |   └───<resourceGroupName>
|   |   |   |   |   pipeline.yml
|   |   |   |   |   rg.variables.yml
|   |   |   |   └───parameters
|   |   |   |       └───<resourceTypeName>
|   |   |   |       |       <resourceName>.json
|   |   |   |       └───<resourceTypeName>
|   |   |   |       |       <resourceName>.json
|   |   |   |       └───...
|   |   |   └───...
|   |   └───...
|   └───...
└───...
    
```

Description of folder structure:

- The 'Teams folder' is for establishment of new teams and resources they need that do not fit within the Azure resource hierarchy.
  - Each teams folder contains all the resources thats needed for the establishment of the team, i.e. AAD Groups, ADO projects, etc.
  - Each teams folder contains a pipeline folder that handles the deployment and configuration of the resources in the teams folder.
- The folder structure mimics the resource structure and hierarchy in Azure.
- All folders, including root, follow the same structure having a variables.yml file, pipeline.yml file  and a parameter folder for storing parameter and configuration files. These files are separated into folders per resource type.
  - The parameter files in the parameter folders are named the same as the resource it defines.
- In addition, the folders include one or multiple folders representing child objects.
  - First level is tenant settings and pipelines, this level can contain management group and subscription folders.
  - Management group folders can contain child management group or subscription folders.
  - Subscription folders can contain only resource group folders.
  - Resource group folders only contain the default set of files and folders.

Variable files:

- Variable files for each resource level inherits settings and variables from the level above using [template variables](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops#variable-reuse).
- global.variables.yml in the .global folder contains all global values and defaults.
- tenant.variables.yml references the global.variables.yml file and includes tenant specific variables.
- mg.variables.yml references the tenant.variables.yml file and includes management group specific variables.
- sub.variables.yml references the parent mg.variables.yml file and includes subscription specific variables.
- rg.variables.yml references the parent sub.variables.yml file and includes resource group specific variables.

Pipeline files:

- References the variable file in the same folder they are in.
- Can reference another repo containing components/modules, such as the 'IaC' repo.
- Can reuse templates for managing deployment, validation and removal of resources.

Parameter folders and files:

- Each level of resource in the folder structure contains a parameters folder. This folder is for storing parameter and configuration files which are used together with reusable components/modules from other repos.
- Each component/module that is configured has its own subfolder where the actual files are stored.

## Branching Strategy

This repository uses a [feature branch strategy](https://docs.microsoft.com/en-us/azure/devops/repos/git/git-branching-guidance?view=azure-devops#use-feature-branches-for-your-work) (aka topic branch strategy), where no change is ever done directly on the Master branch, but on a feature/topic branch. Each feature/topic branch has a limited lifespan and should be attempted to be merged into master once the changes are ready. To merge changes into master, a Pull Request is raised. Once the PR is accepted and the merge is completed, the feature/topic branch is disposed.

Each feature/topic branch shall be named as follows:

``` txt
users/[firstname-lastname]/[description]
```

During pull requests, the pull request reviewer can easily identify the work done by that person when listing the branches in this repository.

Note the following about the naming convention:

- All text is in lower-case with dashes replacing spaces.
- `[firstname-lastname]` will be the devs first name and lastname (or the devs alias).
- `[description]` is a brief description of the contribution the brnach contains. Ideally the name of the resources which is being updated.

## Policies

### Branch Policies

The following branching policies have been configured for the master branch:

- **Require a minimum number of reviewers**
  - Minimum number or reviewers: **1**
  - Prohibit the most recent pusher from approving their own changes.
  - When new changes are pushed: **reset all approval votes**
- **Check for linked work items**
  - Required. Note: Every Pull Request should have a work item from the backlog linked to it. This way it is easier to track progress of the whole platform.
- **Check for comment resolution**
  - Required. For the Pull Request to be merged, no comments should be active.
- **Limit merge types**
  - Only allow Squash merge. This creates a linear history by condensing the source branch commits into a single new commit on the target branch.

### Build Validation

Not configured

### Status Checks

Not configured

### Autimatically included reviewers

Not configured

# YAML Pipeline Coding Structure

Pipeline file should be created as per the directory structure provided below as an example: 
```
ManagementGroupName
│
└───pxs-cloudnative-mg
    │
    │
    └───pipeline.yml

```
The pipeline (pipeline.yml) should reference the following

- All **global variables** should be declared in the following YAML file under the CICD folder.
  
  **Global Variables**: /global.variables.yml


- For Validation at Stage level leverage the following YAML file: 
  
  **/cicd/templates/pipeline.jobs.validate.yml@IaC**

- For Deployment at Stage level leverage the following YAML file: 
  
  **/cicd/templates/pipeline.jobs.deploy.yml@IaC**
- The parameters that need to be provided are:
	moduleNmae:
	modulPath:
	displayName:
	parameterFilePaths: 
	checkoutRepositories:

- ARM template for parameters **$(parametersPath)/deploy.parameters.json**