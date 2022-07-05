[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $path
)


Describe "[Project] Azure DevOps Project Specs" {

    $HydrationDefinitionObj = ConvertFrom-Json (Get-Content -Path $path -Raw)
    $testCases = @()
    foreach ($projectObj in $HydrationDefinitionObj.projects) {
        $testCases += @{
            projectObj       = $projectObj
            organizationName = $HydrationDefinitionObj.organizationName
        }
    }

    It "Should have all expected properties for project [<organizationName>|<projectObj.projectname>]" -TestCases $testCases {

        param(
            [PSCustomObject] $projectObj,
            [string] $organizationName
        )

        $global:projectObj = $projectObj
        $global:organizationName = $organizationName

        InModuleScope 'Hydra' {

            $inputParameters = @{
                Organization = $organizationName
                Project      = $projectObj.projectName
            }
            $remoteProject = Get-Project @inputParameters

            if (-not ($templateTypeId = $projectObj.$templateTypeId)) {
                $templateTypeId = (Get-DevOpsProcessList -Organization $organizationName | Where-Object { $_.Name -eq $projectObj.process }).Id
            }

            $remoteProject | Should -Not -BeNullOrEmpty

            if (-not [String]::IsNullOrEmpty($projectObj.description)) {
                $remoteProject.description | Should -Be $projectObj.description
            }
            if (-not [String]::IsNullOrEmpty($projectObj.sourceControl)) {
                $remoteProject.SourceControlType | Should -Be $projectObj.sourceControl
            }
            if (-not [String]::IsNullOrEmpty($templateTypeId)) {
                $remoteProject.templateTypeId | Should -Be $templateTypeId -Because ('the project [{0}] template ID [{1}] should match the expected [{2}|{3}]' -f $remoteProject.name, $remoteProject.templateTypeId, $templateTypeId, $projectObj.process)
            }
            if (-not [String]::IsNullOrEmpty($projectObj.visibility)) {
                $remoteProject.visibility | Should -Be $projectObj.visibility
            }
        }
    }
}
