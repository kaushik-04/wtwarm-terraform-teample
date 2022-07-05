# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Project] New-Project tests" -Tag Build {

        It "Should create new Project with description" {

            $Organization = "contoso"
            $projectToCreate = @{
                Name              = "Module Playground"
                Description       = "Module Playground description"
                SourceControlType = "git"
                TemplateTypeId    = 123
                Visibility        = "Private"
            }

            Mock Invoke-RESTCommand -ParameterFilter {
                $method -eq 'POST' -and
                (ConvertFrom-Json $body).Name -eq $projectToCreate.Name -and
                (ConvertFrom-Json $body).description -eq $projectToCreate.Description -and
                (ConvertFrom-Json $body).capabilities.versioncontrol.sourceControlType -eq $projectToCreate.SourceControlType -and
                (ConvertFrom-Json $body).capabilities.processTemplate.templateTypeId -eq $projectToCreate.TemplateTypeId -and
                (ConvertFrom-Json $body).visibility -eq $projectToCreate.visibility
            } -Verifiable

            $Project = @{
                Organization     = $Organization
                projectsToCreate = @($projectToCreate)
            }
            { New-Project @Project -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}
