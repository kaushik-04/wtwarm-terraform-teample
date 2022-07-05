# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Iteration] Get-ProjectIterationList" -Tag Build {

        It "Should fetch root & child iterations" {
            $rootReturn = ConvertFrom-Json (Get-Content -Path (Join-Path $PSScriptRoot 'resources/GetProjectIterationListRoot.json') -Raw)
            $childrenReturn = ConvertFrom-Json (Get-Content -Path (Join-Path $PSScriptRoot 'resources/GetProjectIterationListTree.json') -Raw)
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like "*classificationnodes/iterations*" } -MockWith { return $rootReturn } -Verifiable
            Mock Invoke-RESTCommand -ParameterFilter { $uri -like ("*classificationnodes?ids={0}*" -f $rootReturn.Id) } -MockWith { return $childrenReturn } -Verifiable
    
            $children = Get-ProjectIterationList -Organization "ADO-Hydration" -Project "Hydration Unit Test" 
            $children.Count | Should -Be $childrenReturn.Count

            # All mocks should be invoked as defined
            Should -InvokeVerifiable
        }
    }
}