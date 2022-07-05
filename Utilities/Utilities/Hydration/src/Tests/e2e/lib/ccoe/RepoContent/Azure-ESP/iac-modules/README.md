# Introduction 
This repository hosts the reference ARM templates and pipelines to be used during the deployment of Certified Components within the organization.

# Repository Structure
A quick view of how the repository has been structure can be seen below:

```
IaC
│   README.md   
│
└───cicd
│   │   global.variables.yml
│   │
│   └───templates
│       │   pipeline.jobs.publish.yml
│       │   pipeline.jobs.validate.yml
│       │   ...
│   
└───common
│   │
│   └───1.0
│       │
│       └───sripts
|           |   Test-TemplateWithParameterFile.ps1
│   
└───modules
    |
    └───keyvault
    |       |
    |       └───1.0
    |           |   deploy.json
    |           |   README.md
    |           |
    |           └───parameters
    |           |   |   deploy.parameters.json
    |           |   
    |           └───pipeline
    |           |   |   azure.pipeline.yml
    |           |
    |           └───tests
    |               |   arm.tests.ps1
    |               |   unit.tests.ps1
    |
    └───...
```
The purpose of each of the folders is:
- **cicd** folder contains every reusable template that will be consumed/referenced from the deployment pipeline of all modules.
- **common** folder hosts the common resources that may be needed by one/multiple modules within the repository. It acts as a centralized library.
- **modules** folder includes one folder per module. Each module is built as a combination of its ARM template, parameters file, test scripts and pipeline, organized by versions. This structure should be homogeneous along the modules.

# Branching Strategy

For any addition/edition of a module this repopository has stablished a [feature branch](https://docs.microsoft.com/en-us/azure/devops/repos/git/git-branching-guidance?view=azure-devops#use-feature-branches-for-your-work) strategy. This means that no change can be done directly in the Master branch, but a new feature branch should be created. Once the changes are ready, a Pull Request should be raised against Master.

For each [module](#repository-structure) a new branch should be created. Each branch will follow a naming convention (lower-case with dashes) so that the pull request reviewer can easily identify the work done by that person when listing the branches in this Repository:
- `users/[firstname-lastname]/[description]`

Where:
- `[firstname-lastname]` will be your first name and lastname (or alias in case you have one).
- `[description]` a brief description of the contribution you are doing. Ideally the name of the module or feature you are updating.

# Branching Policies

The following branching policies have been configured for the Master branch:
- **Require a minimum number of reviewers**. At least one reviewer needs to approve the Pull Request before merging it into Master. This reviewer should not be the same person that raised the Pull Request. Any further commits added to the Pull Request once it was already raised, will reset the approvals, meaning that the reviewer will need to approve it again.
- **Check for linked work items**. Every Pull Request should have a work item from the backlog linked to it. This way it is easier to track progress of the whole platform.
- **Check for comment resolution**. For the Pull Request to be merged, no comments should be active.
- **Build validation**. For merging the code into Master, the pipeline associated to that module needs to run successfully.

> **Note**: in order to ensure the *Build validation* everytime a new module is added to the repository, the policy needs to be updated, pointing to the pipeline of that module.

# YAML Pipeline Coding Structure

Pipeline file should be created as per the directory structure provided below as an example: 
```
Component: Keyvault   
│
└───Version: 1.0
    │
    │
    └───PipelineFolderName: Pipeline
        | 
        │__ azure.pipeline.yml

```
The pipeline (azure.pipeline.yml) should reference the following

- All **global variables** should be declared in the following YAML file under the CICD folder.
  
  **Global Variables**: /cicd/global.variables.yml

- For Validation at Stage level leverage the following YAML file: 
  
  **/cicd/templates/pipeline.jobs.validate.yml**

- For Deployment at Stage level leverage the following YAML file: 
  
  **/cicd/templates/pipeline.jobs.deploy.yml**

- For Publishing at Stage level leverage the following YAML file:
  
  **/cicd/templates/pipeline.jobs.publish.yml**

- For Removal at Stage level leverage the following YAML file: 
  
  **/cicd/templates/pipeline.jobs.remove.yml**

- ARM template for parameters **$(parametersPath)/deploy.parameters.json**