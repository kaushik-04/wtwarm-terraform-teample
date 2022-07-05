# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent))

InModuleScope $ModuleName {

    $global:areaConfigPaths = @(
        @{ path = Join-Path $PSScriptRoot 'resources\hydrationDefinitionBefore.json' },
        @{ path = Join-Path $PSScriptRoot 'resources\hydrationDefinitionAfter.json' }
    )

    BeforeAll {
        Write-Verbose "BeforeAll: Test setup start" -Verbose
        $definition = ConvertFrom-Json (Get-Content -path $areaConfigPaths[0].path -Raw)

        if ($project = Get-Project -organization $definition.organizationName -project $definition.projects[0].projectName) {
            Write-Verbose ("BeforeAll: Remove project [{0}]" -f $definition.projects[0].ProjectName) -Verbose
            Remove-Project -organization $definition.organizationName -project $project
            Start-Sleep 5 # Wait for propagation
        }

        Write-Verbose ("BeforeAll: Create project [{0}]" -f $definition.projects[0].ProjectName) -Verbose
        $templateTypeId = (Get-DevOpsProcessList -Organization $definition.organizationName | Where-Object { $_.Name -eq $definition.projects[0].process }).Id
        $newProjectInputObject = @{
            Organization     = $definition.organizationName
            projectsToCreate = @(@{
                    name              = $definition.projects[0].projectName
                    description       = $definition.projects[0].description
                    sourceControlType = $definition.projects[0].sourceControl
                    templateTypeId    = $templateTypeId
                    process           = $definition.projects[0].process
                    visibility        = $definition.projects[0].visibility
                })
        }
        New-Project @newProjectInputObject -ErrorAction 'Stop'

        Start-Sleep 5 # Wait for propagation
        Write-Verbose "BeforeAll: Test setup end" -Verbose
    }

    Describe "[Area] [<path.Split('\')[-1]>] Integration tests" -Tag Integration -ForEach $areaConfigPaths {

        It "Should not throw during area hydration" {

            $hydraConfig = ConvertFrom-Json (Get-Content -Path $path -Raw)

            $inputParameters = @{
                localAreaPaths    = $hydraConfig.projects[0].areaPaths
                Organization      = $hydraConfig.organizationName
                Project           = $hydraConfig.projects[0].projectName
                removeExcessItems = $true
                DryRun            = $false
            }
            { Sync-ProjectAreaList @inputParameters -ErrorAction 'Stop' } | Should -Not -Throw
        }

        $acceptanceFolder = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath Acceptance
        . "$acceptanceFolder\projectArea.spec.ps1" -path $path
    }

    AfterAll {
        Write-Verbose "AfterAll: Test teardown start" -Verbose
        $definition = ConvertFrom-Json (Get-Content -path $areaConfigPaths[0].path -Raw)
        if ($project = Get-Project -organization $definition.organizationName -project $definition.projects[0].ProjectName) {
            Write-Verbose ("AfterAll: Remove project [{0}]" -f $definition.projects[0].ProjectName) -Verbose
            Remove-Project -organization $definition.organizationName -project $project
        }
        Write-Verbose "AfterAll: Test teardown end" -Verbose
    }
}