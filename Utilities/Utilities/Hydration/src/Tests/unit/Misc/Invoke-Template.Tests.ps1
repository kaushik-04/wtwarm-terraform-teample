# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {

    Describe "[Misc] Invoke-HydraTemplate WhatIf" -Tag Build {

        $VALID_DEFINTION_FILE_NAME = 'hydrationDefinition.json'
        $definitionFilePath = "{0}\resources\$VALID_DEFINTION_FILE_NAME" -f (Split-Path $PSScriptRoot -Parent)

        $testcases = @(
            @{ Path = $definitionFilePath; Expected = $true }
        )
        It "Hydration should not throw" -TestCases $testcases {
            { Invoke-HydraTemplate -Path $path -WhatIf } | Should -Not -Throw
        }
    }

    Describe "[Misc] Invoke-HydraTemplate Mocked" -Tag Build {

        $VALID_DEFINTION_FILE_NAME = 'hydrationDefinition.json'
        $definitionFilePath = "{0}\resources\$VALID_DEFINTION_FILE_NAME" -f (Split-Path $PSScriptRoot -Parent)

        $testcases = @(
            @{ Path = $definitionFilePath; Expected = $true }
        )
        It "Should invoke hydration" -TestCases $testcases {

            Mock Connect-DevOps { return "Login Mock invoked" } -ModuleName 'Hydra'
            Mock Sync-DevOpsOrgProcessList { return $False } -ModuleName 'Hydra'
            Mock Sync-Project { return $False } -ModuleName 'Hydra'
            Mock Sync-ProjectAreaList { return $False } -ModuleName 'Hydra'
            Mock Sync-ProjectIterationList { return $False } -ModuleName 'Hydra'
            Mock Sync-ProjectTeamList { return $False } -ModuleName 'Hydra'
            Mock Sync-ProjectRepo { return $False } -ModuleName 'Hydra'
            Mock Sync-Backlog { return $False } -ModuleName 'Hydra'

            Invoke-HydraTemplate -Path $path

            Assert-MockCalled Connect-DevOps -Times 1 -ModuleName 'Hydra'
            Assert-MockCalled Sync-DevOpsOrgProcessList -Times 1 -ModuleName 'Hydra'
            Assert-MockCalled Sync-ProjectAreaList  -Times 1 -ModuleName 'Hydra'
            Assert-MockCalled Sync-Project -Times 1 -ModuleName 'Hydra'
            Assert-MockCalled Sync-ProjectIterationList  -Times 1 -ModuleName 'Hydra'
            Assert-MockCalled Sync-ProjectTeamList  -Times 1 -ModuleName 'Hydra'
            Assert-MockCalled Sync-Backlog -Times 1 -ModuleName 'Hydra'
        }
    }
}
