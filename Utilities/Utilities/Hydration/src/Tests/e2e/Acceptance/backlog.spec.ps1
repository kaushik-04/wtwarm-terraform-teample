[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $path
)

Describe "[Backlog] Azure DevOps Project Backlog Specs" {

    $HydrationDefinitionObj = ConvertFrom-Json (Get-Content -Path $path -Raw)
    $testCases = @()
    foreach ($projectObj in $HydrationDefinitionObj.projects) {
        foreach ($backlogDefinition in $projectObj.backlogs) {

            $defintionBase = Split-Path $path -Parent
            $localBacklogDataPath = Join-Path $defintionBase $backlogDefinition.relativeBacklogFilePath

            $testCases += @{
                projectObj           = $projectObj
                organizationName     = $HydrationDefinitionObj.organizationName
                localBacklogDataPath = $localBacklogDataPath
            }
        }
    }

    It "Should have no divergence of expected properties in project [<organizationName>|<projectObj.projectname>]" -TestCases $testCases {

        param (
            [string] $localBacklogDataPath,
            [string] $organizationName,
            [PSCustomObject] $projectObj
        )

        # Get & format local data
        $localBacklogData = Import-BacklogCompatibleCSV $localBacklogDataPath
        Resolve-BacklogLocalFormatted -localBacklogData $localBacklogData

        # Get & format remote data
        $remoteBacklogData = Get-BacklogItemsCreated -Project $projectObj.projectName -Organization $organizationName -fetchDetails -expandCategory 'Relations'
        Resolve-BacklogRemoteFormatted -remoteBacklogData $remoteBacklogData

        $remoteBacklogData.Count | Should -Be $localBacklogData.Count

        # Test properties
        foreach ($localBacklogItem in $localBacklogData) {

            $matchingRemote = $remoteBacklogData | Where-Object { $_.GEN_relationString -eq $localBacklogItem.GEN_RelationString }

            ($matchingRemote.fields.('{0}' -f (Get-BacklogPropertyCounterpart -localPropertyName 'Title'))) | Should -Be $localBacklogItem.title
            ($matchingRemote.fields.('{0}' -f (Get-BacklogPropertyCounterpart -localPropertyName 'Work Item Type'))) | Should -Be $localBacklogItem.'Work Item Type'

            if ($localBacklogItem.state) {
                ($matchingRemote.fields.('{0}' -f (Get-BacklogPropertyCounterpart -localPropertyName 'State'))) | Should -Be $localBacklogItem.state
            }
            else {
                ($matchingRemote.fields.('{0}' -f (Get-BacklogPropertyCounterpart -localPropertyName 'State'))) | Should -Be 'New'
            }

            if ($localBacklogItem.'Area Path') {
                ($matchingRemote.fields.('{0}' -f (Get-BacklogPropertyCounterpart -localPropertyName 'Area Path'))) | Should -Be $localBacklogItem.'Area Path'
            }
            else {
                ($matchingRemote.fields.('{0}' -f (Get-BacklogPropertyCounterpart -localPropertyName 'Area Path'))) | Should -Be $projectObj.projectName
            }

            if ($localBacklogItem.'Iteration Path') {
                ($matchingRemote.fields.('{0}' -f (Get-BacklogPropertyCounterpart -localPropertyName 'Iteration Path'))) | Should -Be $localBacklogItem.'Iteration Path'
            }
            else {
                ($matchingRemote.fields.('{0}' -f (Get-BacklogPropertyCounterpart -localPropertyName 'Iteration Path'))) | Should -Be $projectObj.projectName
            }

            if ($localBacklogItem.Description) {
                ($matchingRemote.fields.('{0}' -f (Get-BacklogPropertyCounterpart -localPropertyName 'Description'))) | Should -Be $localBacklogItem.Description
            }
        }
    }

    It "Should have no divergence of expected relations in project [<organizationName>|<projectObj.projectname>]" -TestCases $testCases {

        param (
            [string] $localBacklogDataPath,
            [string] $organizationName,
            [PSCustomObject] $projectObj
        )

        $global:localBacklogDataPath = $localBacklogDataPath
        $global:organizationName = $organizationName
        $global:projectObj = $projectObj

        InModuleScope 'Hydra' {

            $localBacklogData = Import-BacklogCompatibleCSV $localBacklogDataPath

            # Generate Local Relation Strings
            Resolve-BacklogLocalFormatted -localBacklogData $localBacklogData

            # Generate Remote Relation Strings
            if ($remoteBacklogData = Get-BacklogItemsCreated -Project $projectObj.projectName -Organization $organizationName -fetchDetails -expandCategory 'Relations') {
                Resolve-BacklogRemoteFormatted -remoteBacklogData $remoteBacklogData
            }

            $localRelationStrings = ($localBacklogData.GEN_RelationString) ? $localBacklogData.GEN_RelationString : @()
            $remoteRelationStrings = ($remoteBacklogData.GEN_RelationString) ? $remoteBacklogData.GEN_RelationString : @()

            (Compare-Object $localRelationStrings $remoteRelationStrings).Count | Should -Be 0
        }
    }
}