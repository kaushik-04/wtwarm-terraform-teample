# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))
$FunctionHelpTestExceptions = Get-Content -Path "$PSScriptRoot\resources\Test.Exceptions.txt"

Describe "[ScriptAnalyzer] Should not violate best practices" -Tag ScriptAnalyzer {

    $Rules = Get-ScriptAnalyzerRule
    $scripts = Get-ChildItem $ModuleBase -Include *.ps1, *.psm1, *.psd1 -Recurse | Where-Object {
        (Split-Path $_.FullName -Parent) -notmatch 'Tests'
    }

    $testCases = [System.Collections.ArrayList]@()
    foreach ($Script in $scripts) {
        foreach ($rule in $rules) {
            if ($FunctionHelpTestExceptions -contains $rule.RuleName) { continue }
            $testCases += @{
                scriptName = Split-Path $Script -LeafBase
                scriptPath = $Script
                ruleName   = $rule
            }
        }
    }
    It "rule [<ruleName>]" -TestCases $testcases {

        param(
            [string] $scriptName,
            [string] $scriptPath,
            [string] $ruleName
        )
        $result = (Invoke-ScriptAnalyzer -Path $scriptPath -IncludeRule $ruleName) 
        if (-not $result) { 
            $result = @() 
            $reason = ""
        } else {
            $reason = ("Rule [{0}] was violated because script [{1}] has [{2}] at line(s) [{3}]" -f $RuleName, $scriptName, $result[0].Message, ($result.Line -join ','))
        }
        $result.Count | Should -Be 0 -Because $reason
    }
}

Describe "[Misc] Exported functions evaluation" -Tag Build {

    $moduleManifestPath = Join-Path $moduleBase "$ModuleName.psd1"
    $manifest = Import-PowerShellDataFile $moduleManifestPath
    $commandPrefix = $manifest.DefaultCommandPrefix

    # Get the actually exported functions by the module
    $actualFunctions = (Get-Module -Name $ModuleName).ExportedFunctions
    
    # Build the expected functions from the public folder
    $plainPublicFunctions = (Get-ChildItem -Path "$ModuleBase\Public" -Filter '*.ps1').BaseName
    $functionTestCases = @()
    foreach ($func in $plainPublicFunctions) {
        $functionParts = $func.Split('-')
        $expectedFunction = "{0}-{1}{2}" -f $functionParts[0], $commandPrefix , $functionParts[1]
        $functionTestCases += @{ 
            expectedFunction = $expectedFunction
            actualFunctions  = $actualFunctions
        }
    }

    # Run the tests
    It "Correct export of <expectedFunction>" -TestCases $functionTestCases {

        param(
            [string] $expectedFunction,
            [System.Object] $actualFunctions
        )

        $actualFunctions.ContainsKey($expectedFunction) | Should -Be $true
    }
}