# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $moduleName {

    $moduleName = 'Hydra'
    $FunctionHelpTestExceptions = Get-Content -Path "$PSScriptRoot\resources\Test.Exceptions.txt"

    # TestCases are splatted to the script so we need hashtables
    Write-Verbose "Searching Module $moduleName for commands"

    # only public
    # $commands = Get-Command -Module $moduleName -CommandType Cmdlet, Function

    # public + private
    $commands = (Get-Module -Name $moduleName).Invoke( { Get-Command -Module $moduleName })

    $commandNames = $commands | Foreach-Object {
        if ($FunctionHelpTestExceptions -contains $commandName) { continue } ## may not be correct check with a functionthat needs exceptions
        @{
            Name = $_.Name
        }
    }

    Describe "[Help] Help of <Name>" -ForEach $commandNames -Tag Help {

        $help = Get-Help -Name $Name -ErrorAction SilentlyContinue
        $testCase = $help | Foreach-Object {
            @{
                name        = $_.details.name
                Synopsis    = $_.Synopsis
                Description = $_.Description
                Example     = ($_.Examples.Example | Select-Object -First 1).Code
            }
        }
        It "Should have a Synopsis" -TestCases $testCase {
            $Synopsis | Should -Not -BeNullOrEmpty
        }

        # If help is not found, synopsis in auto-generated help is the syntax diagram
        It "Should not be auto-generated" -TestCases $testCase {
            $Synopsis | Should -Not -BeLike '*`[`<CommonParameters`>`]*'
        }

        $testCase = $help | Foreach-Object {
            @{
                name        = $_.details.name
                Description = $_.details.description.text
                Example     = ($_.Examples.Example | Select-Object -First 1).Code
            }
        }
        It "Should have a Description" -TestCases $testCase {
            $Description | Should -Not -BeNullOrEmpty
        }

        $testCase = $help | Foreach-Object {
            @{
                name        = $_.details.name
                CodeExample = ($_.Examples.Example | Select-Object -First 1).Code
                Example     = ($_.Examples.Example | Select-Object -First 1).Code
            }
        }
        It "Should have a CodeExample" -TestCases $testCase {
            $CodeExample | Should -Not -BeNullOrEmpty
        }
    }
}