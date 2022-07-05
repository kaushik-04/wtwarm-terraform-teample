# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent))

InModuleScope $ModuleName {

    $global:projectConfigPaths = @(
        @{ path = Join-Path $PSScriptRoot 'resources\hydrationDefinitionBefore.json' },
        @{ path = Join-Path $PSScriptRoot 'resources\hydrationDefinitionAfter.json' }
    )

    BeforeAll {
        Write-Verbose "BeforeAll: Test setup start" -Verbose
        $generalDefinition = ConvertFrom-Json (Get-Content -path $projectConfigPaths[0].path -Raw)

        $projectNames = @()
        foreach ($path in $projectConfigPaths.path) {
            $definition = ConvertFrom-Json (Get-Content -Path $path -Raw)
            $projectNames += $definition.projects.projectName
        }
        $projectNames = $projectNames | Select-Object -Unique

        foreach ($projectName in $projectNames) {
            if ($project = Get-Project -organization $generalDefinition.organizationName -project $projectName) {
                Remove-Project -organization $generalDefinition.organizationName -project $project
            }
        }

        $inputParameters = @{
            localProcesses    = $generalDefinition.Processes
            Organization      = $generalDefinition.organizationName
            removeExcessItems = $false
            DryRun            = $false
        }
        Sync-DevOpsOrgProcessList @inputParameters -ErrorAction 'Stop'

        Write-Verbose "BeforeAll: Test setup end" -Verbose
    }

    Describe "[Project] [<path.Split('\')[-1]>] Integration tests" -Tag Integration -ForEach $projectConfigPaths {


        $hydraConfig = ConvertFrom-Json (Get-Content -Path $path -Raw)
        $testCases = @()
        foreach ($projectObj in $hydraConfig.projects) {
            $testCases += @{
                projectObj       = $projectObj
                organizationName = $hydraConfig.organizationName
                DryRun           = $false
            }
        }

        It "Project creation [<organizationName>|<projectObj.projectname>] should not throw" -TestCases $testCases {

            param(
                [PSCustomObject] $projectObj,
                [string] $organizationName,
                [bool] $DryRun
            )

            $localProject = @{
                id                = '-1'
                name              = $projectObj.projectName
                description       = $projectObj.description
                sourceControlType = $projectObj.sourceControl
                templateTypeId    = (Get-DevOpsProcessList -Organization $organizationName | Where-Object { $_.Name -eq $projectObj.process }).Id
                visibility        = $projectObj.visibility
            }
            $inputParameters = @{
                Organization  = $organizationName
                localProjects = $localProject
                DryRun        = $DryRun
                Verbose       = $true
            }
            { Sync-Project @inputParameters -ErrorAction 'Stop' } | Should -Not -Throw
        }

        $acceptanceFolder = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath Acceptance
        . "$acceptanceFolder\project.spec.ps1" -path $path
    }

    AfterAll {
        Write-Verbose "AfterAll: Test teardown start" -Verbose
        $generalDefinition = ConvertFrom-Json (Get-Content -path $projectConfigPaths[0].path -Raw)

        $projectNames = @()
        foreach ($path in $projectConfigPaths.path) {
            $definition = ConvertFrom-Json (Get-Content -Path $path -Raw)
            $projectNames += $definition.projects.projectName
        }
        $projectNames = $projectNames | Select-Object -Unique

        foreach ($projectName in $projectNames) {
            if ($project = Get-Project -organization $generalDefinition.organizationName -project $projectName) {
                Remove-Project -organization $generalDefinition.organizationName -project $project
            }
        }

        $remoteProcesses = Get-DevOpsProcessList -Organization $generalDefinition.organizationName
        $processNames = $generalDefinition.Processes.Name

        if ($processesToRemove = $remoteProcesses | Where-Object { $_.type -ne 'system' -and $_.name -in $processNames }) {
            $removeProcessInputObject = @{
                Organization      = $generalDefinition.organizationName
                processesToRemove = $processesToRemove
            }
            Remove-DevOpsProcessRange @removeProcessInputObject
        }

        Write-Verbose "AfterAll: Test teardown end" -Verbose
    }
}