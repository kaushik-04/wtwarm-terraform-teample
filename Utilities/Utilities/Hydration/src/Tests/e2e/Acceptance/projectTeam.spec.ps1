[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $path
)

Describe "[Team] Azure DevOps Project Team Specs" {

    $HydrationDefinitionObj = ConvertFrom-Json (Get-Content -Path $path -Raw)
    $testCases = @()
    foreach ($projectObj in $HydrationDefinitionObj.projects) {
        $testCases += @{
            teams        = $projectObj.teams
            project      = $projectObj.ProjectName
            organization = $HydrationDefinitionObj.organizationName
        }
    }

    It "Should have all expected teams in project [<organization>|<project>]" -TestCases $testCases {

        param(
            [PSCustomObject[]] $teams,
            [string] $project,
            [string] $organization
        )

        $global:teams = $teams
        $global:project = $project
        $global:organization = $organization


        InModuleScope 'Hydra' {

            if ($expectedTeams = $teams) {
                $inputParameters = @{
                    Organization = $organization
                    Project      = $project
                }
                $remoteTeamsObj = Get-ProjectTeamList @inputParameters # used by test

                foreach ($expectedTeam in $expectedTeams) {

                    $matchingRemote = $remoteTeamsObj | Where-Object {
                        $_.Name -eq $expectedTeam.Name -and
                        ([String]::IsNullOrEmpty($expectedTeam.Description) -or
                            (-not [String]::IsNullOrEmpty($expectedTeam.Description) -and $_.Description -eq $expectedTeam.Description))
                    }

                    $matchingRemote | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    It "Should set team as default if configured" -TestCases $testCases {

        param (
            [PSCustomObject[]] $teams,
            [string] $project,
            [string] $organization
        )

        $inputParameters = @{
            Organization = $Organization
            Project      = $project
        }
        $projectObj = Get-Project @inputParameters

        $defaultTeam = "$project Team" # default

        # The last one in line should be the default project
        foreach ($localTeam in $teams) {
            if ($localTeam.isProjectDefault -eq $true) {
                $defaultTeam = $localTeam.Name
            }
        }

        $projectObj.defaultTeam.name | Should -Be $defaultTeam
    }

    It "Should set team settings if configured" -TestCases $testCases {

        param (
            [PSCustomObject[]] $teams,
            [string] $project,
            [string] $organization
        )

        $inputParameters = @{
            Organization = $Organization
            Project      = $project
        }
        $projectObj = Get-Project @inputParameters

        # Get project backlog level
        $remoteWitBehaviors = Get-DevOpsProcessBacklogLevelList -Organization $Organization -processId $projectObj.templateTypeId

        # test
        foreach ($localTeam in $localTeams) {
            $teamSettingsInputObject = @{
                Organization = $Organization
                Project      = $project
                Team         = $localTeam.Name
            }
            $remoteTeamSettings = Get-ProjectTeamSetting @teamSettingsInputObject

            # Working days
            if ($expectedWorkingDays = $localTeam.boardSettings.workingDays) {
                foreach ($expectedWorkday in $expectedWorkingDays) {
                    ($remoteTeamSettings.workingDays) | Should -Contain $expectedWorkday
                }
            }

            # Visibility
            if ($expectedBacklogVisibilities = $localTeam.boardSettings.backlogVisibilities) {

                foreach ($expectedVisibility in ($expectedBacklogVisibilities | Get-Member -MemberType 'NoteProperty').Name) {

                    if ($expectedVisibility -notlike "Microsoft.*") {
                        # custom
                        $witBehavior = $remoteWitBehaviors | Where-Object { $_.name -eq $expectedVisibility }
                        $remoteTeamSettings.backlogVisibilities.($witBehavior.referenceName) | Should -Be $localTeam.boardSettings.backlogVisibilities.$expectedVisibility
                    }
                    else {
                        # devops native
                        $remoteTeamSettings.backlogVisibilities.$expectedVisibility | Should -Be $localTeam.boardSettings.backlogVisibilities.$expectedVisibility
                    }
                }
            }

            # Bug handling
            if ($expectedBugsBehavior = $localTeam.boardSettings.bugsBehavior) {
                $remoteTeamSettings.bugsBehavior | Should -Be $expectedBugsBehavior
            }
        }
    }

    It "Should configure each teams area configuration correctly in project [<organization>|<project>]" -TestCases $testCases {

        param(
            [PSCustomObject[]] $teams,
            [string] $project,
            [string] $organization
        )

        $global:teams = $teams
        $global:project = $project
        $global:organization = $organization

        InModuleScope 'Hydra' {

            foreach ($localTeam in $teams) {

                if ($localTeamAreaConfig = $localTeam.boardSettings.areaConfig) {
                    $teamAreaConfigInputObject = @{
                        Organization = $organization
                        Project      = $project
                        Team         = $localTeam.Name
                    }
                    $remoteTeamAreasConfiguration = Get-ProjectTeamSettingFieldValue @teamAreaConfigInputObject

                    if ($localTeamAreaConfig.defaultValue -ne $project -and $localTeamAreaConfig.defaultValue -notlike "$project\*" -and $localTeamAreaConfig.defaultValue -notlike "$project/*") {
                        $localTeamAreaConfig.defaultValue = "{0}\{1}" -f $project, $localTeamAreaConfig.defaultValue
                    }
                    ## Available items
                    foreach ($valuesItem in $localTeamAreaConfig.values) {
                        if ($valuesItem.value -ne $project -and $valuesItem.value -notlike "$project\*" -and $valuesItem.value -notlike "$project/*") {
                            $valuesItem.value = "{0}\{1}" -f $project, $valuesItem.value
                        }
                    }

                    $remoteTeamAreasConfiguration.defaultValue | Should -Be $localTeamAreaConfig.defaultValue

                    $remoteTeamAreasConfiguration.Values.Count | Should -be $localTeamAreaConfig.values.Count -Because 'the remote number of available areas should match the local configured'
                    foreach ($availableArea in $localTeamAreaConfig.values) {
                        $matchingRemoteAvailableArea = $remoteTeamAreasConfiguration.values | Where-Object { $_.value -eq $availableArea.Value }
                        $matchingRemoteAvailableArea | Should -Not -BeNullOrEmpty

                        $matchingRemoteAvailableArea.includeChildren | Should -Be $availableArea.includeChildren
                    }
                }
            }
        }
    }

    It "Should configure each teams iteration configuration correctly in project [<organization>|<project>]" -TestCases $testCases {

        param(
            [PSCustomObject[]] $teams,
            [string] $project,
            [string] $organization
        )

        $global:teams = $teams
        $global:project = $project
        $global:organization = $organization

        InModuleScope 'Hydra' {

            foreach ($localTeam in $teams) {

                if ($localTeamIterationConfig = $localTeam.boardSettings.iterationConfig) {
                    $teamSettingsInputObject = @{
                        Organization = $Organization
                        Project      = $project
                        Team         = $localTeam.Name
                    }
                    $remoteTeamSettings = Get-ProjectTeamSetting @teamSettingsInputObject

                    if ($localTeamIterationConfig.defaultValue -match (Get-RelativeConfigData -configToken 'RegexGUID')) {
                        # test via id
                        $remoteTeamSettings.defaultIteration.id | Should -Be $localTeamIterationConfig.defaultValue
                    }
                    else {
                        # test via name
                        $remoteTeamSettings.defaultIteration.Name | Should -Be $localTeamIterationConfig.defaultValue
                    }

                    if ($localTeamIterationConfig.backlog -match (Get-RelativeConfigData -configToken 'RegexGUID')) {
                        # test via id
                        $remoteTeamSettings.backlogIteration.Id | Should -Be $localTeamIterationConfig.backlog
                    }
                    else {
                        # test via name
                        $remoteTeamSettings.backlogIteration.Name | Should -Be $localTeamIterationConfig.backlog
                    }
                }

                $remoteAvailableTeamIterationsList = Get-ProjectTeamSettingIterationList -Organization $Organization -Project $Project -Team $localTeam.Name

                $remoteAvailableTeamIterationsList.Count | Should -be $localTeamIterationConfig.values.Count -Because 'the remote number of available iterations should match the local configured'
                foreach ($availableIteration in $localTeamIterationConfig.values) {
                    $matchingRemoteAvailableIteration = $remoteAvailableTeamIterationsList | Where-Object { $_.name -eq $availableIteration }
                    $matchingRemoteAvailableIteration | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    It "Should configure each teams board column configuration correctly in project [<organization>|<project>]" -TestCases $testCases {

        param(
            [PSCustomObject[]] $teams,
            [string] $project,
            [string] $organization
        )

        $global:teams = $teams
        $global:project = $project
        $global:organization = $organization

        InModuleScope 'Hydra' {

            foreach ($localTeam in $teams | Where-Object { $_.boardSettings.design } ) {

                $backlogLevel = $localTeam.boardSettings.design.backlogLevel

                if ($expectedColumns = $localTeam.boardSettings.design.boardConfig.columns) {

                    $inputObject = @{
                        Organization = $organization
                        Project      = $project
                        team         = $localTeam.name
                        backlogLevel = $backlogLevel
                    }
                    $remoteBoardSettings = Get-ProjectTeamBoardSetting @inputObject -ErrorAction 'Stop'

                    $remoteBoardSettings.columns.count | Should -Be (($expectedColumns | Where-Object { $_.columnType -notin @('incoming','outgoing') }).Count + 2) # custom including required incoming & outgoing

                    foreach ($expectedColumn in $expectedColumns) {
                        $matchingRemote = $remoteBoardSettings.columns | Where-Object { $_.Name -eq $expectedColumn.Name }

                        if ($expectedColumn.itemsInProgressLimit) {
                            $matchingRemote.itemLimit | Should -Be $expectedColumn.itemsInProgressLimit
                        }

                        if (([PSCustomObject]$expectedColumn).Psobject.Properties.name -contains 'isSplit') {
                            $matchingRemote.isSplit | Should -Be $expectedColumn.isSplit
                        }

                        if ($expectedColumn.stateMappings) {
                            [String]::Compare(($matchingRemote.stateMappings | ConvertTo-Json), ($expectedColumn.stateMappings | ConvertTo-Json), $true) | Should -Be 0
                        }

                        if ($expectedColumn.definitionOfDone) {
                            $matchingRemote.description | Should -Be $expectedColumn.definitionOfDone
                        }
                    }
                }
            }
        }
    }

    It "Should configure each teams board row configuration correctly in project [<organization>|<project>]" -TestCases $testCases {

        param(
            [PSCustomObject[]] $teams,
            [string] $project,
            [string] $organization
        )

        $global:teams = $teams
        $global:project = $project
        $global:organization = $organization

        InModuleScope 'Hydra' {

            foreach ($localTeam in $teams | Where-Object { $_.boardSettings.design } ) {

                $backlogLevel = $localTeam.boardSettings.design.backlogLevel

                if ($expectedRows = $localTeam.boardSettings.design.boardConfig.rows) {

                    $inputObject = @{
                        Organization = $organization
                        Project      = $project
                        team         = $localTeam.name
                        backlogLevel = $backlogLevel
                    }
                    $remoteBoardSettings = Get-ProjectTeamBoardSetting @inputObject -ErrorAction 'Stop'

                    $remoteBoardSettings.rows.count | Should -Be ($expectedRows.Count + 1) # local + default

                    foreach ($expectedRow in $expectedRows) {
                        $remoteBoardSettings.rows.Name | Should -Contain $expectedRow.Name
                    }
                }
            }
        }
    }

    It "Should configure each teams board card design correctly in project [<organization>|<project>]" -TestCases $testCases {

        param(
            [PSCustomObject[]] $teams,
            [string] $project,
            [string] $organization
        )

        $global:teams = $teams
        $global:project = $project
        $global:organization = $organization

        InModuleScope 'Hydra' {

            foreach ($localTeam in ($teams | Where-Object { $_.boardSettings.design } )) {

                $backlogLevel = $localTeam.boardSettings.design.backlogLevel

                if ($expectedCardStyles = $localTeam.boardSettings.design.cardConfig.cardStyles) {

                    $cardSettingsInputObject = @{
                        Organization = $organization
                        Project      = $project
                        team         = $localTeam.name
                        backlogLevel = $backlogLevel
                    }
                    $remoteCardSettings = Get-ProjectTeamCardSetting @cardSettingsInputObject

                    $remoteCardSettings.rules.fill.count | Should -Be $expectedCardStyles.Count

                    foreach ($expectedCardStyle in $expectedCardStyles) {
                        $matchingRemote = $remoteCardSettings.rules.fill | Where-Object { $_.Name -eq $expectedCardStyle.Name }

                        if (([PSCustomObject]$expectedCardStyle).Psobject.Properties.name -contains 'isEnabled') {
                            ([System.Convert]::ToBoolean($matchingRemote.isEnabled)) | Should -Be ([System.Convert]::ToBoolean($expectedCardStyle.isEnabled))
                        }

                        $matchingRemote.filter | Should -Be (Format-ProjectTeamCardRuleCardStyleFilter -localFilter $expectedCardStyle.filter)

                        if ($expectedCardStyle.backgroundColor) {
                            $matchingRemote.settings.'background-color' | Should -Be $expectedCardStyle.backgroundColor
                        }

                        if ($expectedCardStyle.foregroundColor) {
                            $matchingRemote.settings.'title-color' | Should -Be $expectedCardStyle.foregroundColor
                        }

                        if (([PSCustomObject]$expectedCardStyle).Psobject.Properties.name -contains 'isItalic') {
                            if($expectedCardStyle.isItalic) {
                                $matchingRemote.settings.'title-font-style' | Should -Be 'italic'
                            } else {
                                $matchingRemote.settings.PSObject.Properties.Name | Should -Not -Contain 'title-font-style'
                            }
                        }

                        if (([PSCustomObject]$expectedCardStyle).Psobject.Properties.name -contains 'isBold') {
                            if($expectedCardStyle.isBold) {
                                $matchingRemote.settings.'title-font-weight' | Should -Be 'bold'
                            } else {
                                $matchingRemote.settings.PSObject.Properties.Name | Should -Not -Contain 'title-font-weight'
                            }
                        }

                        if (([PSCustomObject]$expectedCardStyle).Psobject.Properties.name -contains 'isUnderlined') {
                            if($expectedCardStyle.isUnderlined) {
                                $matchingRemote.settings.'title-text-decoration' | Should -Be 'underline'
                            } else {
                                $matchingRemote.settings.PSObject.Properties.Name | Should -Not -Contain 'title-text-decoration' -Because ('the property [isUnderlined] for item [{0}] is set to [false]' -f $expectedCardStyle.name)
                            }
                        }
                    }
                }
            }
        }
    }

    It "Should configure each teams board tags design correctly in project [<organization>|<project>]" -TestCases $testCases {

        param(
            [PSCustomObject[]] $teams,
            [string] $project,
            [string] $organization
        )

        $global:teams = $teams
        $global:project = $project
        $global:organization = $organization

        InModuleScope 'Hydra' {

            foreach ($localTeam in $teams | Where-Object { $_.boardSettings.design } ) {

                $backlogLevel = $localTeam.boardSettings.design.backlogLevel

                if ($expectedTagStyles = $localTeam.boardSettings.design.cardConfig.tagStyles) {

                    $cardSettingsInputObject = @{
                        Organization = $organization
                        Project      = $project
                        team         = $localTeam.name
                        backlogLevel = $backlogLevel
                    }
                    $remoteCardSettings = Get-ProjectTeamCardSetting @cardSettingsInputObject

                    $remoteCardSettings.rules.tagStyle.count | Should -Be $expectedTagStyles.Count

                    foreach ($expectedTagStyle in $expectedTagStyles) {
                        $matchingRemote = $remoteCardSettings.rules.tagStyle | Where-Object { $_.Name -eq $expectedTagStyle.Name }

                        $matchingRemote.settings.'background-color' | Should -Be $expectedTagStyle.Color

                        if (([PSCustomObject]$expectedTagStyle).Psobject.Properties.name -contains 'isEnabled') {
                            ([System.Convert]::ToBoolean($matchingRemote.isEnabled )) | Should -Be ([System.Convert]::ToBoolean($expectedTagStyle.isEnabled)) -Because ("tag [{0}] is to be configured to have the 'isEnabled' status [{0}]" -f $expectedTagStyle.name, $expectedTagStyle.isEnabled)
                        }
                    }
                }
            }
        }
    }
}