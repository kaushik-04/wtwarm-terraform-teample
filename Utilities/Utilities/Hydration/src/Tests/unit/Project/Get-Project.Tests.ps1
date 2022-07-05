# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {

    Describe "[Project] Get-Project tests" -Tag Build {

        It "Should fetch project details" {
            $rootReturn = ConvertFrom-Json (Get-Content -Path (Join-Path $PSScriptRoot 'resources/GetProjectRoot.json') -Raw)
            $propertiesReturn = ConvertFrom-Json (Get-Content -Path (Join-Path $PSScriptRoot 'resources/GetProjectProperties.json') -Raw)
            $sourceControlTypeGit = $propertiesReturn.value | Where-Object Name -eq 'System.SourceControlGitEnabled'
            if ($sourceControlTypeGit.value) {
                $sourceControlType = 'Git'
            }
            else {
                $sourceControlType = 'Tfvc'
            }
            $templateTypeId = ($propertiesReturn.value | Where-Object name -eq 'System.ProcessTemplateType').value

            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*projects/*" } -MockWith { return $rootReturn } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*projects/{0}/properties*" -f $rootReturn.Id) } -MockWith { return $propertiesReturn } -Verifiable

            $remoteProject = Get-Project -Organization "ADO-Hydration" -Project "Hydration Unit Test"
            $remoteProject | Should -Not -BeNullOrEmpty

            if (-not [String]::IsNullOrEmpty($rootReturn.name)) {
                $remoteProject.name | Should -Be $rootReturn.name
            }
            if (-not [String]::IsNullOrEmpty($rootReturn.description)) {
                $remoteProject.description | Should -Be $rootReturn.description
            }
            if (-not [String]::IsNullOrEmpty($sourceControlType)) {
                $remoteProject.SourceControlType | Should -Be $sourceControlType
            }
            if (-not [String]::IsNullOrEmpty($templateTypeId)) {
                $remoteProject.templateTypeId | Should -Be $templateTypeId
            }
            if (-not [String]::IsNullOrEmpty($rootReturn.visibility)) {
                $remoteProject.visibility | Should -Be $rootReturn.visibility
            }

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}