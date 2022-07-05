. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {

    Describe "[Misc] Get-VerifiedHydrationDefinition" -Tag Build {

        $VALID_DEFINTION_FILE_NAME = 'hydrationDefinition.json'
        $definitionFilePath = "{0}\resources\$VALID_DEFINTION_FILE_NAME" -f (Split-Path $PSScriptRoot -Parent)

        $testcases = @(
            @{
                Path = $definitionFilePath
            }
        )
        It "Should prase a valid file" -TestCases $testcases {
            $parse = @{
                Path = $Path
            }
            $definitionObject = Get-VerifiedHydrationDefinition @parse

            $definitionObject | Should -Not -BeNullOrEmpty
        }
    }
}
