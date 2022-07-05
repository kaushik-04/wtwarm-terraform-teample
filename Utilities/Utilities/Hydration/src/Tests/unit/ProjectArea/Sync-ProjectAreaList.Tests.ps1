# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {

    Describe "[Area] Sync-ProjectAreaList" -Tag Build {

        It "Should remove & add all areas as expected" {

            # Load data
            $localProjectDataPath = Join-Path $PSScriptRoot 'resources\SyncProjectAreaListLocal.json'
            $localProjectData = ConvertFrom-Json (Get-Content -Path $localProjectDataPath -Raw)

            $remoteProjectDataRootPath = Join-Path $PSScriptRoot 'resources\SyncProjectAreaListRemoteRoot.json'
            $remoteProjectDataRoot = ConvertFrom-Json (Get-Content -Path $remoteProjectDataRootPath -Raw)

            $remoteProjectDataTreePath = Join-Path $PSScriptRoot 'resources\SyncProjectAreaListRemoteTree.json'
            $remoteProjectDataTree = ConvertFrom-Json (Get-Content -Path $remoteProjectDataTreePath -Raw)

            # Get data mocks
            Mock Invoke-RESTCommand -MockWith { return $remoteProjectDataRoot } -ParameterFilter { $uri -like "*classificationnodes/areas*" -and $method -eq 'GET' } -Verifiable
            Mock Invoke-RESTCommand -MockWith { return $remoteProjectDataTree } -ParameterFilter { $uri -like ("*classificationnodes?ids={0}*" -f $remoteProjectDataRoot.id) -and $method -eq 'GET' } -Verifiable

            # Delete area mocks
            # Auto-Deletes 61, 62, 71 & 711 as they are childitems of deleted parents
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Areas/{0}*" -f [uri]::EscapeDataString('Area 4')) -and $method -eq 'DELETE' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Areas/{0}*" -f [uri]::EscapeDataString('Area 5')) -and $method -eq 'DELETE' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Areas/{0}*" -f [uri]::EscapeDataString('Area 6')) -and $method -eq 'DELETE' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Areas/{0}/{1}*" -f [uri]::EscapeDataString('Area 7'), [uri]::EscapeDataString('Area 71')) -and $method -eq 'DELETE' } -Verifiable

            # Create area mocks
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*/classificationnodes/Areas*" -and ($body -like "*New Team 1*") -and $method -eq 'POST' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*/classificationnodes/Areas*" -and ($body -like "*New Team 2*") -and $method -eq 'POST' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*/classificationnodes/Areas*" -and ($body -like "*New Team 3*") -and $method -eq 'POST' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Areas/{0}*" -f [uri]::EscapeDataString('New Team 3')) -and ($body -like "*New Team 31*") -and $method -eq 'POST' } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*/classificationnodes/Areas/{0}/{1}*" -f [uri]::EscapeDataString('New Team 3'), [uri]::EscapeDataString('New Team 31')) -and ($body -like "*New Team 311*") -and $method -eq 'POST' } -Verifiable
            $inputObject = @{
                localAreaPaths    = $localProjectData.AreaPaths
                Organization      = $localProjectData.OrganizationName
                Project           = $localProjectData.ProjectName
                removeExcessItems = $true
                DryRun            = $false
            }
            { Sync-ProjectAreaList @inputObject -ErrorAction 'Stop' } | Should -Not -Throw

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}