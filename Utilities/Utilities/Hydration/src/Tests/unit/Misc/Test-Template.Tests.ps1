# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

Describe "[Misc] Test-HydraTemplate" -Tag Build {

    $VALID_DEFINTION_FILE_NAME = 'hydrationDefinition.json'
    $definitionFilePath = "{0}\resources\$VALID_DEFINTION_FILE_NAME" -f (Split-Path $PSScriptRoot -Parent)

    $testcases = @(
        @{ Path = $definitionFilePath; Expected = $true }
    )
    It "Should validate definition" -TestCases $testcases {

        Test-HydraTemplate $path | Should -Be $expected
    }
}

