# Onboarding script user guide

This PowerShell script will create the new Azure Devops project and repositories in a new organization, to host the IaCS modules and solutions for an MCS delivery

## Command syntax

```powershell
.\New-IaCSProject.ps1 [-OrganizationName] <String> [[-ProjectName] <String>] [[-ProcessTemplate] <String>] [[-SourceControlType]
     <String>] [[-SubscriptionId] <String>] [[-ResourceGroupName] <String>] [[-Location] <String>] [<CommonParameters>]
```

- OrganizationName: the name of the Azure DevOps organization to create
- ProjectName: the name of the Azure DevOps project to create. Defaults to 'IaCS'
- ProcessTemplate: the process template type of the Azure DevOps project to create (Agile / Basic / CMMI / Scrum). Defaults to 'Agile'
- SourceControlType: the source control type of the Azure DevOps project to create (Git / TFVC). Defaults to 'Git'
- SubscriptionId: the Id of the Azure subscription to be used when creating the related Azure resources. Defaults to the current subscription in the context
- ResourceGroupName: the name of the resource group to be used when creating the related Azure resources. Defaults to 'Azure-DevOps-IaCs'
- Location: the Azure region location to be used when creating the related Azure resources (IMPORTANT: Azure DevOps organizations can be created currenlty only in the folowing regions: Australia East, Brazil South, Canada Central, Central US, East Asia, East US 2, South India, UK South, West Europe, West US 2). Defaults to 'West Europe'

Example:

```powershell
.\New-IaCSProject -OrganizationName FabrikamLtd -ProjectName InfraAsCode -Template Basic -SubscriptionId '01234567-89ab-cdef-0123-456789abcdef' -Location 'East US 2'
```