# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent))

InModuleScope $ModuleName {

    $global:repoConfigPaths = @(
        @{ path = Join-Path $PSScriptRoot 'resources\hydrationDefinitionBefore.json' },
        @{ path = Join-Path $PSScriptRoot 'resources\hydrationDefinitionAfter.json' }
    )

    BeforeAll {
        Write-Verbose "BeforeAll: Test setup start" -Verbose
        $definition = ConvertFrom-Json (Get-Content -path $repoConfigPaths[0].path -Raw)

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

        if ([String]::IsNullOrEmpty($env:AZURE_DEVOPS_EXT_PAT)) {
            # For execution outside of a pipeline
            Write-Verbose ("BeforeAll: Cleanup PATs") -Verbose
            $existingPats = Get-DevOpsPATList -organization $definition.organizationName
            foreach ($relevantPAT in ($existingPats | Where-Object { $_.displayName -eq (Get-RelativeConfigData -configToken 'DEVOPS_PAT_NAME') })) {
                Remove-DevOpsPAT -organization $definition.organizationName -AuthorizationId $relevantPAT.authorizationId
            }
        }

        Start-Sleep 5 # Wait for propagation
        Write-Verbose "BeforeAll: Test setup end" -Verbose
    }

    Describe "[Repo] [<path.Split('\')[-1]>] Integration tests" -Tag Integration -ForEach $repoConfigPaths {

        It "Should not throw during repo hydration" {

            $hydraConfig = ConvertFrom-Json (Get-Content -Path $path -Raw)

            foreach ($projectObj in $hydraConfig.projects) {
                $inputParameters = @{
                    localRepos        = $projectObj.repositories
                    ConfigurationRoot = "$PSScriptRoot/resources"
                    Organization      = $hydraConfig.organizationName
                    Project           = $projectObj.projectName
                    removeExcessItems = $true
                    DryRun            = $false
                    Verbose           = $true
                }
                { Sync-ProjectRepo @inputParameters -ErrorAction 'Stop' } | Should -Not -Throw
            }
        }

        $acceptanceFolder = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath Acceptance
        . "$acceptanceFolder\projectRepo.spec.ps1" -path $path
    }

    AfterAll {
        Write-Verbose "AfterAll: Test teardown start" -Verbose
        $definition = ConvertFrom-Json (Get-Content -path $repoConfigPaths[0].path -Raw)
        if ($project = Get-Project -organization $definition.organizationName -project $definition.projects[0].ProjectName) {
            Write-Verbose ("AfterAll: Remove project [{0}]" -f $definition.projects[0].ProjectName) -Verbose
            Remove-Project -organization $definition.organizationName -project $project
        }

        if ([String]::IsNullOrEmpty($env:AZURE_DEVOPS_EXT_PAT)) {
            # For execution outside of a pipeline
            Write-Verbose ("AfterAll: Cleanup PATs") -Verbose
            $existingPats = Get-DevOpsPATList -organization $definition.organizationName
            foreach ($relevantPAT in ($existingPats | Where-Object { $_.displayName -eq (Get-RelativeConfigData -configToken 'DEVOPS_PAT_NAME') })) {
                Remove-DevOpsPAT -organization $definition.organizationName -AuthorizationId $relevantPAT.authorizationId
            }
        }

        Write-Verbose "AfterAll: Test teardown end" -Verbose
    }
}