# DRAFT: Technical Design for the Hydration

See Design in [Wiki](https://servicescode.visualstudio.com/infra-as-code-source/_wiki/wikis/Wiki/4888/Cloud-Center-of-Excellence)

## Decisions

- Programming Languages [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-70?view=powershell-7) (.ps1)
- Library: [Azure CLI](https://docs.microsoft.com/en-us/CLI/azure/install-azure-CLI)

PowerShell allowes to create sophisticated modules and object oriented programming.

```powershell
# test.ps1

$teamName = "Solution Architecture"
az devops team create --name $teamName ...
```

PowerShell also allows to reuse the abstraction of Azure CLI. As well as be flexible to run no abstraction for a REST-call with 
`Invoke-WebMethod`.

Azure CLI is beeing used in favor of the AzureRM PowerShell Module as it offers more functionallity.

## Idea

Create a configuration file that is based on how to rehydrate the Azure DevOps.
We want to have a declarative configuration based approach, as a collection of script would just implement the Azure CLI steps.
 
As the hydration is opinionated we need to provide a default configuration anyway to start.
The default configuration can then be changed and adopted to customers needs - providing a flexible approach.

We start with simple with the project definition e.g.

```json
{
    "$schema": "...",
    "resources": {
        "organizations": [
            {
                "name": "ADO-Hydration",
                "projects": [
                    {
                        "name": "Hydration",
                        "description": "Hydration",
                        "process": "Agile",
                        "sourceControl": "git",
                        "visibility": "public",
                    }
                ]

                // ....
            }
        ]
    }
}
```

The configuration will be aligned to look like the diagram displayed here: [Wiki ccoe-hydration-0.1](https://ADO-Hydration.visualstudio.com/Hydration/_wiki/wikis/Wiki/4888/Cloud-Center-of-Excellence?anchor=ccoe-hydration-0.1) 

The configuration will be read by a command and executed using different functions to invoke the changes on Azure DevOps.

Given the following command:

```sh
az devops project create --name
                         [--description]
                         [--detect {false, true}]
                         [--open]
                         [--org]
                         [--process]
                         [--source-control {git, tfvc}]
                         [--visibility {private, public}]
```


```powershell
# ./create-Project.ps1

# Read the configuration
$path = Join-Path $PSScriptRoot 'draft.object.schema.json'
$content = Get-Content -Path $path -Raw
$json = ConvertFrom-Json $content


# Parse the configuration and for each project
Write-Host $json.resources.organizations[0].name
$project = $json.resources.organizations[0].projects[0]

write-host $project

# Create a project
$projectClass = @{
    Name           = "Hydration" 
    Description    = "Hydration" 
    Process        = "Agile" 
    SourceControl  = "git" 
    Visibility     = public
    AreaPaths      = []
    IterationPaths = []
}
az devops project create --name $projectClass.Name ....
```

The script can be wrapped into a PowerShell module in order to have a command like `New-Project`

```powershell
# Modular approach, each "part" of DevOps can be hydrated independently
New-Project -ConfigurationFile $ConfigurationFile

# The whole DevOps could be rehydrated completely using something like this:
Invoke-HydraTemplate -ConfigurationFile $ConfigurationFile
```

### Drawbacks

Given a configuration file, you need to stick to a schema.
We have to define a schema for the configuration. Need to create something to validate, check and maintain it.

The editor experience could be bad, as we deal with a lot of json potentially. (VScode extension...)

## Principles

We will stick to the following principles: 

- **Idempotent**  is the property where a deployment command always sets the target environment into the same configuration, regardless of the environment’s starting state.
- **Modular**, each hydration step should be able to be executed independently of another, e.g. just projects
- **Declarative**, we want to stick to the ARM Template like configuration, as close as possible

## Design

As an enduser, I want to be able to rehydrate my Azure DevOps modular like the following. Turning all scrips into a module with prefix e.g. `Hydra`.

```powershell
New-HydraOrganization -PAT $pat -ParameterFile $ParameterFile
New-HydraTeam
New-HydraProject
New-HydraRepository
```

Should be also available via one command that combines all steps.

```powershell
Invoke-HydraTemplate -PAT $pat -ParameterFile $ParameterFile
```

Should be also available to run within a docker container to not need to install dependencies. 

```shell
docker -v /app:/VSTSCONFIG.JSON -e PAT=$PAT -run
```


## Considerations

Secrets e.g. the Personal Access Token (PAT `$pat`)

- There might be secrets that are not allowed in the file.
- Secrets should be provided to the command directly if needed, otherwise we need to fetch them from key vault.
- think about the 'PowerShell 7' secret-module.

## Code Structure

We want to create a PowerShell module that is versioned and distributable.
The code will thus be structured like:

```sh
src
- Hydra # Must match the PowerShell module name, in order to be able to be imported
- Tests # Tests that validate modules functionality
```

## Others

### Use Module public functions

```powershell
Import-Module './src/Hydra/Hydra.psd1' -force
Get-command -Module 'Hydra'
```

### Import and list internal functions:

```powershell
$module = Import-Module './src/Hydra/Hydra.psd1' -force
$module.Invoke({Get-Command -Module 'Hydra'})
```

### Access internal functions in tests:

Use the Pester feature `InModuleScope`

```PowerShell
InModuleScope "<ModuleName>" {
     Describe "<TestDescription>" {
         <PrivateFunctionInvocation>
     }
}
```