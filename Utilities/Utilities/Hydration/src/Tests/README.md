# Test

## Unit Test

TODO: Document this

## End-to-End test

This test process should run the hydration script in order to check if a hydration for a "fresh" project is succesful and reproducable.

### Prerequisits

1. An exsisting "test" organization
2. An exsisting "test" organization with sufficient access controle for developer
3. An existing base Project, that contians the e2e pipeline and code, e.g. [aka.ms/IacS](https://aka.ms/iacs)
4. Create a PAT in the "test" organization in order to [sign in with a Personal Access Token (PAT)](https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows#use-environment-variables)
5. Create a variable group to host the PAT in the base Project

### Sign in 

[Sign in with a Personal Access Token (PAT) - Use environment variables](https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows#use-environment-variables)

```
# set environment variable for current process
$env:AZURE_DEVOPS_EXT_PAT = 'xxxxxxxxxx'
```

### E2E Testing Process

1. PAT from Azure DevOps variable group
2. Given a test-file e.g. `Hydration/resources/tests/hydrationDefinition.json`
3. TODO: Check this: DryRun Invoke-HydraTemplate -Path $TestFile -Force -skipLogin -DryRun 
4. Execute `Invoke-HydraTemplate -Path $TestFile -Force -skipLogin`
5. Assert if given Hydration was successful in a `MY_ACCEPTANCE_TEST.spec.ps1` that gets executed in `integration.tests.ps1`


#### Acceptence Test

The file `integration.tests.ps1` is a orchestration file that executes the test procedure and invokes different specificiations. A specification is a `<TEST_CASE>.spec.ps1`

```powershell
# integration.Tests.ps1  
# ...

  # Run Hydration
  # Run the hydration using the template
  # The output can be stored, and later reused in the `spec.ps1` execution
  $result = Invoke-HydraTemplate -Path $TestFile -Force -skipLogin -DryRun 

  # Optional: Rn assertions on the returned object
  $result.output | Should -Be ...

  # Optional: Run Acceptance Test on provisioned resources
  . $PSScriptRoot/acceptance.spec.ps1 # -Parameter ...


  # Example
  . $PSScriptRoot/project.acceptance.spec.ps1 -Name $result.project.name -Org $OrgName

# ...
```

An acceptance or `.spec` file can be executed independently.

A specification should validate whether a given Azure DevOps has the specified configuration. The script validates against a given definition file.

A pseudocode `project.acceptance.spec.ps1`.

```powershell
# project.acceptance.spec.ps1
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [PSCustomObject] $HydrationDefinitionObj
)

# Some magick regarding the getting of the project to validate
$projectSUT = az devops project show --project $HydrationDefinitionObj.projectName --org ('https://dev.azure.com/{0}' -f $HydrationDefinitionObj.organizationName)  -o json
$projectSUT = $projectSUT | ConvertFrom-Json -ErrorAction Stop

$testData = @{
    remoteProject   = $projectSUT
    localDefinition = $HydrationDefinitionObj
}

Describe "Azure DevOps Project Acceptance" -Tags Acceptance {

    <# Mandatory requirement of a hydrated Project
        - Must have Description
        - Must have process
        ...
    #>
    it "should be of description <EXPLANATION>" -TestCases $TestData {

        param(
            [PSCustomObject] $remoteProject
        )

        $remoteProject.description | Should -Be $HydrationDefinition.description
    }

    # TODO: Change this and add more
    it "should be of process agile"  -TestCases $TestData {

        param(
            [PSCustomObject] $remoteProject,
            [PSCustomObject] $HydrationDefinition
        )

        $remoteProject.process | Should -Be $HydrationDefinition.process
    }

}

```
## Further Documentation

- [Mark](https://markwarneke.me/2019-08-22-Integration-Test-infrastructure-as-code#integration-test-structure
- [Example spec](https://github.com/MarkWarneke/markwarneke.github.io/blob/master/code/adls.acceptance.spec.ps1)


## Tags

Pester tags used next to `Describe "" -Tag Build { `

| Name | Description |
| --- | ---|
| Unit | A test to execut a single function execution logic, does not execute cli, everything is mocked. "Offline executable" |
| Build | A simulation of execution including the "surrounding" commands, testing the whole process (interaction of multiple functions together), executes the flow, everthin is mocked. "Offline executable" |
| Integration | An actual execution of the function. Needs to be auhtenticated with given test Azure Devops |
| Acceptance | A specification that can be tested "against" a given hydrated Azure DevOps |
| Help | A test that checks whether a given help is present on a function | 
| ScriptAnalyzer| Static analysis of the PowerShell files using PSScriptAnalyzer | 


## Folder Structure

We structure the test into `e2e` and `unit`. 

| Name | Description|
| --- | ---| 
| `e2e` | Contains script that run against an actual Azure DevOps organization | 
| `unit` | Contains all scripts that can be executed locally |


```
src
|- hydra
    |- Private
    |- Public
    |- Static
|- Tests
    |- e2e
        |- Integration
            |- Invoke-Template.Tests.ps1
            |- Project
                |- New-Project.Integration.Tests.ps1
                |- Sync-Project.Integration.Tests.ps1
                |- ...
            |- Repo
                |- Get-Repo.Integration.Tests.ps1
        |- Acceptance
            |- project.spec.ps1
            |- board.spec.ps1
            |- ...
    |- unit
        |- Project
            |- Get-Project.Tests.ps1
        |- Repo
            |- Get-Repo.Tests.ps1
```


## Pipeline

1. Job
   1. Unit -> `Invoke-Pester -Tag Unit. Build -Path "tests" `  TEST_TIME > 1 min 4all
2. Job
   1. Integration -> `Invoke-Pester -Tag Integration -Path "tests/e2e" `        TEST_TIME > 1 min 4one
   2. Acceptance  -> `Invoke-Pester -Path "tests/e2e/integration/invoke-template.Tests.ps1"`     TEST_TIME > 10 min