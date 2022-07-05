# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

Describe "[Misc] General project validation: $moduleName" -Tag Build {

    # TestCases are splatted to the script so we need hashtables
    $scripts = Get-ChildItem $moduleRoot -Include *.ps1, *.psm1, *.psd1 -Recurse
    $testCase = $scripts | Foreach-Object { @{file = $_ } }

    It "Script <file> should be valid powershell" -TestCases $testCase {
        
        param(
            [System.IO.FileSystemInfo] $file
        )
        
        $file.fullname | Should -Exist

        $contents = Get-Content -Path $file.fullname -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref] $errors)
        $errors.Count | Should -Be 0
    }

    $testCase = @{
        ModuleBase = $ModuleBase
        ModuleName = $ModuleName
    }

    It "Module '$ModuleName' can import cleanly" -TestCases $testCase {
        { Import-Module (Join-Path $ModuleBase "$ModuleName.psd1") -force } | Should -Not -Throw
    }
}