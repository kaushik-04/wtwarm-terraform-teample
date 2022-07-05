[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [PSCustomObject[]]$paths,
    [Parameter(Mandatory = $false)]
    [bool] $cleanupE2Eproject = $false
)

# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

$global:paths = $paths
$global:cleanupE2Eproject = $cleanupE2Eproject

InModuleScope $ModuleName {

    BeforeAll {
        Write-Verbose "BeforeAll: Test setup start" -Verbose
        $generalDefinition = ConvertFrom-Json (Get-Content -path $paths[0].path -Raw)

        $projectNames = @()
        foreach ($path in $paths.path) {
            $definition = ConvertFrom-Json (Get-Content -Path $path -Raw)
            $projectNames += $definition.projects.projectName
        }
        $projectNames = $projectNames | Select-Object -Unique

        foreach ($projectName in $projectNames) {
            if ($project = Get-Project -organization $generalDefinition.organizationName -project $projectName) {
                Remove-Project -organization $generalDefinition.organizationName -project $project
            }
        }


        $processNames = @()
        foreach ($path in $paths.path) {
            $definition = ConvertFrom-Json (Get-Content -Path $path -Raw)
            $processNames += $definition.Processes.Name
        }
        $processNames = $processNames | Select-Object -Unique

        $remoteProcesses = Get-DevOpsProcessList -Organization $generalDefinition.organizationName
        if ($processesToRemove = $remoteProcesses | Where-Object { $_.type -ne 'system' -and $_.name -in $processNames }) {
            $removeProcessInputObject = @{
                Organization      = $generalDefinition.organizationName
                processesToRemove = $processesToRemove
            }
            Remove-DevOpsProcessRange @removeProcessInputObject
        }

        Write-Verbose "BeforeAll: Test setup end" -Verbose
    }

    Describe "[<path.Split('/')[-1]>] Azure DevOps Hydration" -Tag Acceptance -ForEach $paths {

        It "Pre-Deployment dry run should not throw an exception" {
            Write-Verbose '## ============================================================ ##' -Verbose
            Write-Verbose '##     Pre-Deployment dry run should not throw an exception     ##' -Verbose
            Write-Verbose '## ============================================================ ##' -Verbose
            Write-Verbose ("Pre-Deployment dry run - [{0}]" -f (Split-Path $path -Leaf)) -Verbose
            { Invoke-HydraTemplate -path $path -skipLogin -removeExcessItems -DryRun -Verbose -ErrorAction 'Stop' } | Should -Not -Throw
            Start-Sleep 30
        }

        It "Deployment should not throw an exception" {
            Write-Verbose '## ================================================ ##' -Verbose
            Write-Verbose '##     Deployment should not throw an exception     ##' -Verbose
            Write-Verbose '## ================================================ ##' -Verbose
            Write-Verbose ("Deployment - [{0}]" -f (Split-Path $path -Leaf)) -Verbose
            { Invoke-HydraTemplate -path $path -skipLogin -removeExcessItems -Verbose -ErrorAction 'Stop' } | Should -Not -Throw
            Start-Sleep 30
        }

        It "Post-Deployment dry run should not show any changes (manual check)" {
            Write-Verbose '## ====================================================== ##' -Verbose
            Write-Verbose '##     Post-Deployment dry run should show no changes     ##' -Verbose
            Write-Verbose '## ====================================================== ##' -Verbose
            Write-Verbose ("Post-Deployment dry run - [{0}]" -f (Split-Path $path -Leaf)) -Verbose
            { Invoke-HydraTemplate -path $path -skipLogin -removeExcessItems -DryRun -Verbose -ErrorAction 'Stop' } | Should -Not -Throw
            Start-Sleep 30
        }

        $acceptanceFolder = Join-Path (Split-Path $PSScriptRoot -Parent) -ChildPath Acceptance

        . "$acceptanceFolder\project.spec.ps1" -path $path
        . "$acceptanceFolder\projectTeam.spec.ps1" -path $path
        . "$acceptanceFolder\projectArea.spec.ps1" -path $path
        . "$acceptanceFolder\backlog.spec.ps1" -path $path
        . "$acceptanceFolder\projectRepo.spec.ps1" -path $path
    }

    AfterAll {
        Write-Verbose "AfterAll: Test teardown start" -Verbose

        if ($cleanupE2Eproject) {
            $generalDefinition = ConvertFrom-Json (Get-Content -Path $paths[0].path -Raw)

            $projectNames = @()
            foreach ($path in $paths.path) {
                $definition = ConvertFrom-Json (Get-Content -Path $path -Raw)
                $projectNames += $definition.projects.projectName
            }
            $projectNames = $projectNames | Select-Object -Unique

            foreach ($projectName in $projectNames) {
                if ($project = Get-Project -organization $generalDefinition.organizationName -project $projectName) {
                    Remove-Project -organization $generalDefinition.organizationName -project $project
                }
            }

            $processNames = @()
            foreach ($path in $paths.path) {
                $definition = ConvertFrom-Json (Get-Content -Path $path -Raw)
                $processNames += $definition.Processes.Name
            }
            $processNames = $processNames | Select-Object -Unique

            $remoteProcesses = Get-DevOpsProcessList -Organization $generalDefinition.organizationName
            if ($processesToRemove = $remoteProcesses | Where-Object { $_.type -ne 'system' -and $_.name -in $processNames }) {
                $removeProcessInputObject = @{
                    Organization      = $generalDefinition.organizationName
                    processesToRemove = $processesToRemove
                }
                Remove-DevOpsProcessRange @removeProcessInputObject
            }
            Write-Verbose "AfterAll: Test teardown End" -Verbose
        }
    }
}