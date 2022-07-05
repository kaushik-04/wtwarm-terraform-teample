
# Acceptence Test

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