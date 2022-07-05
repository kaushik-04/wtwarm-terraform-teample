# Load module and dependencies
. ("{0}\helper\Shared.ps1" -f (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))

InModuleScope $ModuleName {
    Describe "[Area] Resolve-ProjectAreaFormatted Tests" -Tag Unit {

        It "Should resolve expected local relations" {

            $testData = ConvertFrom-Json (Get-Content -Path (Join-Path $PSScriptRoot 'resources\ResolveProjectAreaFormattedLocal.json') -Raw)

            # Trigger resolve
            $flatAreaList = Resolve-ProjectAreaFormatted -Areas $testData -project 'Module Playground'

            $relationStringProperty = 'GEN_RelationString'            
            
            $flatAreaList.$relationStringProperty.count | Should -Be 10
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-CCoE Cloud Solutions Team'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-CCoE Cloud Platform Team'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-CCoE Security Champions'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-CCoE Cloud Operations Champions'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-CCoE DevOps Enablement Office'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-Customer Application Teams'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-Customer Application Teams-[_Child_]-Customer Application Team 3'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-Customer Application Teams-[_Child_]-Customer Application Team 3-[_Child_]-Subchild2'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-Customer Application Teams-[_Child_]-CCoE Cloud Solutions Team 4'
        }

        It "Should resolve expected remote relations" {

            $testData = ConvertFrom-Json (Get-Content -Path (Join-Path $PSScriptRoot 'resources\ResolveProjectAreaFormattedRemote.json') -Raw)

            # Trigger resolve
            $flatAreaList = Resolve-ProjectAreaFormatted -Areas $testData

            $relationStringProperty = 'GEN_RelationString'
            
            $flatAreaList.$relationStringProperty.count | Should -Be 9
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-CCoE Cloud Solutions Team'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-CCoE Cloud Platform Team'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-CCoE Security Champions'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-CCoE Cloud Operations Champions'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-CCoE DevOps Enablement Office'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-Customer Application Teams'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-Customer Application Teams-[_Child_]-Customer Application Team 3'
            $flatAreaList.$relationStringProperty | Should -Contain 'Module Playground-[_Child_]-Customer Application Teams-[_Child_]-CCoE Cloud Solutions Team 4'
        }
    }
}