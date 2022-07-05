The components for Terraform modules are published as artifacts for Pipeline Orchestrated deployments (See "Solutions" repo).  The following is necessary preparation work
when moving this code to a new ADO project.  Moving code to a new ADO project is likely necessary because your solutions will need to access an Azure Artifact feed.
This feed is not publicly accessible.

# Getting Started in a new ADO project
1. Create a repo for all module code.  If this repo is cloned and the path is not changed, you should not need to adjust any strings.  If you change the folder structure of the repo, you may need to modify files in /Modules/Terraform/*.yaml and /Modules/Terraform/.global/PipelineTemplates/scripts/*.sh
2. Edit modules/terraform/.global/PipelineLibrary/Pipeline.Version.yaml to point to the desired Azure Artifact feed
3. Create a new pipeline for each modulename/Pipelines/Pipeline.yaml.  This will build artifacts of the module
4. Select a sample solution from the Solutions repo and follow the included Readme.md