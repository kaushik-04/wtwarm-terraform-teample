---
Module Name: Hydra
Module Guid: ab5aa98c-325d-4df2-8e0a-1a19ef561be8
Download Help Link: [Hydra](https://dev.azure.com/servicescode/infra-as-code-source/_git/Components?path=%2FUtilities%2FHydration%2Fdocs)
Help Version: 0.0.0
Locale: en-US
---

# Hydra Module
## Description


The `Hydra` PowerShell module is used to rehydrate a given Azure DevOps project.
I uses a configuration based approach, similar to an ARM template.
The module implements a ordered collection of Azure cli commands to achieve the rehydration.

As the hydration is opinionated, we are execting a defined configuration file.
The default configuration file can then be changed and adopted to customers needs - providing a flexible approach.

TODO: #67790 A blueprint hydration template file is beeing provided as a reference to the module. 
A hydration template can also be created from scratch, given that it alignes to the schema (`Get-HydraSchema` and `Test-HydraTemplate).

The currentenly implemented test hydration file looks like this:

```json
{
    "$schema": "../Hydra/Hydra.Schema.json",
    "projectName": "Hydration",
    "organizationName": "ADO-Hydration",
    "description": "Hydration",
    "process": "Agile",
    "sourceControl": "git",
    "visibility": "private",
    "repositoryName" : "Hydration-Components",
    "areaPaths": [
        {
            "name": "CCoE Cloud Solutions Team"
        },
        {
            "name": "CCoE Cloud Platform Team"
        },
        {
            "name": "CCoE Security Champions"
        },
        {
            "name": "CCoE Cloud Operations Champions"
        },
        {
            "name": "CCoE DevOps Enablement Office"
        },
        {
            "name": "Customer Application Teams",
            "children": [
                {
                    "name": "Customer Application Team 3",
                    "children": []
                },
                {
                    "name": "CCoE Cloud Solutions Team 4",
                    "children": []
                }
            ]
        }
    ],
    "iterationPaths": [
		{
            "name": "Sprint 0",
            "attributes":
            {
                "startDate": "2020-12-14",
                "finishDate": "2020-12-28"
            }
		},
		{
            "name": "Sprint 1",
			"children":[
				{
                    "name": "Sprint 1.1",
                    "attributes":
                    {
                        "startDate": "2021-01-04",
                        "finishDate": "2021-01-11"
                    }
				},
				{
                    "name": "Sprint 1.2",
                    "attributes":
                    {
                        "startDate": "2021-01-12",
                        "finishDate": "2021-01-18"
                    }
				}
			]
		},
		{
            "name": "Sprint 3"
		}
    ],
    "teams": [
		{
        	"name": "Hydration Team",
            "description": "The default project team."
        },
        {
        	"name": "CCoE Cloud Solutions Team"
        },
        {
        	"name": "CCoE Cloud Platform Team"
        },
        {
            "name": "CCoE Security Champions"
        },
        {
            "name": "CCoE Cloud Operations Champions"
        },
        {
            "name": "CCoE DevOps Enablement Office"
        }
    ]
}
```

The configuration will be aligned to configure the resources outlined in the diagram displayed in the [Wiki ccoe-hydration-0.1](https://servicescode.visualstudio.com/infra-as-code-source/_wiki/wikis/Wiki/4888/Cloud-Center-of-Excellence?anchor=ccoe-hydration-0.1) 

To get started the user has to create a hydration template based on the schema using `Get-HydraSchema`.
Next the template is tested against the schema using `Test-HydraTemplate`.
Laslty, the configuration will be read by `Invoke-HydraTemplate` and executed using different functions to invoke the changes on Azure DevOps.

```bash
cd ./Utilities/Hydration 
Import-Module ./src/Hydra
Get-Command -Module Hydra 
```

Next, you need to create the hydration file. 
There is a test file for reference here: [`mawarnek.hydration.json`](../resources/tests/mawarnek.hydration.json).
The existing file needs to be edited or copied, change the [`organizationName` on Line 4](https://servicescode.visualstudio.com/infra-as-code-source/_git/Components?path=%2FUtilities%2FHydration%2Fresources%2Ftests%2Fmawarnek.hydration.json&version=GBmaster&line=4&lineEnd=5&lineStartColumn=1&lineEndColumn=1&lineStyle=plain&_a=contents) to the DevOps organization to be hydrated.


Then you can use `Invoke-HydraTemplate -Path $PathToHydrationFile`
e.g: `Invoke-HydraTemplate -Path ./resourcs/tests/mawarnek.hydration.json`.

You probably want to login using `az login` first, then you can use Invoke-AzHydarteTemplate `-SkipLogin`. `SkipLogin` won't ask you for a PAT and takes your user access permission to Azure DevOps.

## Hydra Cmdlets
### [Get-HydraSchema](Get-HydraSchema.md)

Returns the used Hydration Schema to validate the configuration file against.


### [Test-HydraTemplate](Test-HydraTemplate.md)

Test given definition file against the schema.

### [Invoke-HydraTemplate](Invoke-HydraTemplate.md)

Invokes the hydration given the definition file.
Creates Azure DevOps resources based on a hydration definition file that matches a given schema.

1. Run `Get-AzHydrationSchema` and create a definition file based on the given JSON schema you can find an example in [hydrationDefinition.json](../src/Tests/hydrationDefinition.json)
2. Run `Test-AzHydrationTemplate` to validate the create definition template against the schema
3. Run `Invoke-AzHydrationTemplate` to run the actual hydration
4. Login to Azure DevOps
    1. The user is prompted to [login with a personal access token](https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows). 
    1. This login can be avoided using the `-SkipLogin` parameter. Make sure to be logged in using `az login` before using the `-SkipLogin` option.
