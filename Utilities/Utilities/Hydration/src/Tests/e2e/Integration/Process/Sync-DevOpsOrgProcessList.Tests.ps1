# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent))

InModuleScope $ModuleName {

    $global:processConfigPaths = @(
        @{ path = Join-Path $PSScriptRoot 'resources\hydrationDefinitionBefore.json' },
        @{ path = Join-Path $PSScriptRoot 'resources\hydrationDefinitionAfter.json' }
    )

    BeforeAll {
        Write-Verbose "BeforeAll: Test setup start" -Verbose
        $generalDefinition = ConvertFrom-Json (Get-Content -path $processConfigPaths[0].path -Raw)
        $remoteProcesses = Get-DevOpsProcessList -Organization $generalDefinition.organizationName

        $processNames = @()
        foreach ($path in $processConfigPaths) {
            $definition = ConvertFrom-Json (Get-Content -path $path.path -Raw)
            $processNames += $definition.Processes.Name
        }
        $processNames = $processNames | Select-Object -Unique

        if ($processesToRemove = $remoteProcesses | Where-Object { $_.type -ne 'system' -and $_.name -in $processNames }) {
            $removeProcessInputObject = @{
                Organization      = $generalDefinition.organizationName
                processesToRemove = $processesToRemove
            }
            Remove-DevOpsProcessRange @removeProcessInputObject
        }
        Start-Sleep 5 # Wait for propagation
        Write-Verbose "BeforeAll: Test setup end" -Verbose
    }

    Describe "[Process] [<path.Split('\')[-1]>] Integration tests" -Tag Integration -ForEach $processConfigPaths {

        It "Should not throw during process hydration" {

            $hydraConfig = ConvertFrom-Json (Get-Content -Path $path -Raw)

            $inputParameters = @{
                localProcesses    = $hydraConfig.Processes
                Organization      = $hydraConfig.organizationName
                removeExcessItems = $true
                DryRun            = $false
            }
            { Sync-DevOpsOrgProcessList @inputParameters -ErrorAction 'Stop' } | Should -Not -Throw
        }

        start-sleep 10 # wait for propagation

        $acceptanceFolder = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath Acceptance
        . "$acceptanceFolder\process.spec.ps1" -path $path
    }

    AfterAll {
        Write-Verbose "AfterAll: Test teardown start" -Verbose
        $generalDefinition = ConvertFrom-Json (Get-Content -path $processConfigPaths[0].path -Raw)
        $remoteProcesses = Get-DevOpsProcessList -Organization $generalDefinition.organizationName

        $processNames = @()
        foreach ($path in $processConfigPaths) {
            $definition = ConvertFrom-Json (Get-Content -path $path.path -Raw)
            $processNames += $definition.Processes.Name
        }
        $processNames = $processNames | Select-Object -Unique

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