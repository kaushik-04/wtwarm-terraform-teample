<#
.SYNOPSIS
Create or delete ADO Project Teams

.DESCRIPTION
Create or delete ADO Project Teams

.PARAMETER localTeams
Mandatory. The teams to create, update or remove

.PARAMETER Organization
Mandatory. The organization to create the teams in. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to create the teams in. E.g. 'Module Playground'

.PARAMETER removeExcessItems
Optional. Control whether or not to remove teams that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-ProjectTeamList -organization 'contoso' -project 'Module Playground' -localTeams @(@{ name = 'team1'; description = 'desc1'})

Sync the defined team 'team1' with the ones in project [contoso|Module Playground]
#>
function Sync-ProjectTeamList {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localTeams,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    process {
        $SyncProcessingStartTime = Get-Date

        ################
        #   Get Data   #
        ################

        # Get project
        if ($remoteProject = Get-Project -Project $project -Organization $Organization) {
            # Get project backlog level
            $remoteWitBehaviors = Get-DevOpsProcessBacklogLevelList -Organization $Organization -processId $remoteProject.templateTypeId
        }
        # Get & format remote teams
        $remoteTeams = Get-ProjectTeamList -Organization $Organization -Project $Project

        ####################
        #   Update Teams   #
        ####################

        $teamsToUpdate = [System.Collections.ArrayList]@()

        foreach ($remoteTeam in $remoteTeams) {

            $matchingLocal = $localTeams | Where-Object {
                $_.Id -eq $remoteTeam.Id -or # Either we provided the exact guid as an id
                $_.Id -eq $remoteTeam.Name -or # Or we provide the name as the id (works too)
                ([String]::IsNullOrEmpty($_.id) -and $_.Name -eq $remoteTeam.Name)  # Or we did not provide the ID so we just match the name
            }
            if ($matchingLocal) {
                if ($propertiesToUpdate = Get-ProjectTeamPropertiesToUpdate -localTeam $matchingLocal -remoteTeam $remoteTeam) {
                    # Update team
                    $updateObject = @{ id = $remoteTeam.Id }
                    foreach ($propertyToUpdate in $propertiesToUpdate) {
                        $updateObject[$propertyToUpdate] = $matchingLocal.$propertyToUpdate
                        $updateObject["Old $propertyToUpdate"] = $remoteTeam.$propertyToUpdate

                        if ($DryRun) {
                            # Simulate change
                            $remoteTeam.$propertyToUpdate = $matchingLocal.$propertyToUpdate
                        }
                    }
                    $null = $teamsToUpdate.Add([PSCustomObject]$updateObject)
                }
            }
        }

        if ($teamsToUpdate.Count -gt 0) {
            $setTeamsInputObject = @{
                Organization  = $Organization
                Project       = $Project
                teamsToUpdate = $teamsToUpdate
                DryRun        = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("Update of [{0}] teams from project [{1}]" -f $teamsToUpdate.Count, $Project), "Initiate")) {
                Set-ProjectTeamRange @setTeamsInputObject
            }

            if (-not $DryRun) {
                # Refresh remote data
                $remoteTeams = Get-ProjectTeamList -Organization $Organization -Project $Project
            }
        }
        else {
            Write-Verbose "No teams to update"
        }

        ####################
        #   Create Teams   #
        ####################

        if ($teamsToCreate = $localTeams | Where-Object { $_.Name -notin $remoteTeams.Name }) {
            $newProjectInputObject = @{
                Organization  = $Organization
                Project       = $Project
                teamsToCreate = $teamsToCreate
                DryRun        = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("Creation of [{0}] teams in project [{1}]" -f $teamsToCreate.Count, $Project), "Initiate")) {
                New-ProjectTeamRange @newProjectInputObject
            }

            if (-not $DryRun) {
                # Refresh remote data
                $remoteTeams = Get-ProjectTeamList -Organization $Organization -Project $Project
            }
        }
        else {
            Write-Verbose "No teams to create"
        }

        ########################
        #   Sync Team Config   #
        ########################
        foreach ($localTeam in $localTeams) {

            $remoteTeam = $remoteTeams | Where-Object {
                $_.Id -eq $localTeam.Id -or # Either we provided the exact guid as an id
                $_.Id -eq $localTeam.Name -or # Or we provide the name as the id (works too)
                ([String]::IsNullOrEmpty($localTeam.id) -and $_.Name -eq $localTeam.Name)  # Or we did not provide the ID so we just match the name
            }

            if (-not $remoteTeam) {
                if ($dryRun) {
                    $remoteTeam = @{
                        id   = '0'
                        name = $localTeam.name
                    }
                }
                else {
                    Write-Error ("No team by identifier [{0}] was found in project [{1}]" -f ((-not [String]::IsNullOrEmpty($localTeam.Name)) ? $localTeam.Name : $localTeam.Id) , $Project)
                    continue
                }
            }

            $remoteTeamSettings = Get-ProjectTeamSetting -Organization $Organization -Project $Project -Team $remoteTeam.Name -DryRun:$DryRun

            # Default team
            if ($localTeam.isProjectDefault -eq $true -and $remoteProject.defaultTeam.name -ne $localTeam.Name) {
                $setDefaultTeamInputObject = @{
                    teamToSet    = $remoteTeam
                    Organization = $Organization
                    Project      = $project
                    DryRun       = $dryRun
                }
                if ($PSCmdlet.ShouldProcess(("Team [{0}] as default for [{1}]" -f $remoteTeam.Name, $project), "Set")) {
                    Set-ProjectTeamProjectDefault @setDefaultTeamInputObject
                }
            }

            # General settings
            $getTeamSettingsInputObject = @{
                localTeam          = $localTeam
                remoteTeam         = $remoteTeam
                remoteTeamSettings = $remoteTeamSettings
                remoteWitBehaviors = $remoteWitBehaviors
            }
            if ($settingsToUpdate = Get-ProjectTeamSettingsToUpdate @getTeamSettingsInputObject) {
                $setTeamSettingsInputObject = @{
                    remoteTeam       = $remoteTeam
                    settingsToUpdate = $settingsToUpdate
                    Organization     = $Organization
                    Project          = $project
                    DryRun           = $dryRun
                }
                if ($PSCmdlet.ShouldProcess(("Team [{0}|{1}] settings" -f $remoteTeam.Name, $project), "Set")) {
                    Set-ProjectTeamSetting @setTeamSettingsInputObject
                }
            }

            # Area settings
            if ($localTeam.boardSettings.areaConfig) {
                $syncAreaConfigInputObject = @{
                    localTeamAreaConfig = $localTeam.boardSettings.areaConfig
                    remoteTeam          = $remoteTeam
                    Organization        = $Organization
                    Project             = $project
                    removeExcessItems   = $removeExcessItems
                    DryRun              = $dryRun
                }
                if ($PSCmdlet.ShouldProcess(("Area-Path Configuration for team [{0}]" -f $remoteTeam.Name), "Sync")) {
                    Sync-ProjectTeamAreaConfig @syncAreaConfigInputObject
                }
            }

            # Iteration settings
            if ($localTeam.boardSettings.iterationConfig) {
                $syncInterationConfigInputObject = @{
                    localTeamIterationConfig = $localTeam.boardSettings.iterationConfig
                    remoteTeam               = $remoteTeam
                    Organization             = $Organization
                    Project                  = $project
                    removeExcessItems        = $removeExcessItems
                    remoteTeamSettings       = $remoteTeamSettings
                    DryRun                   = $dryRun
                }
                if ($PSCmdlet.ShouldProcess(("Iteration-Path Configuration for team [{0}]" -f $remoteTeam.Name), "Sync")) {
                    Sync-ProjectTeamIterationConfig @syncInterationConfigInputObject
                }
            }

            # Board settings
            # --------------
            foreach ($backlogDesignConfig in $localTeam.boardSettings.design) {

                # Board style specific settings
                if ($backlogDesignConfig.cardConfig.PSObject.Properties.name -contains 'cardStyles' -or $backlogDesignConfig.cardConfig.PSObject.Properties.name -contains 'tagStyles') {

                    $cardSettingsInputObject = @{
                        Organization = $Organization
                        Project      = $project
                        team         = $remoteTeam.Name
                        backlogLevel = $backlogDesignConfig.backlogLevel
                    }
                    $remoteCardSettings = Get-ProjectTeamCardSetting @cardSettingsInputObject

                    # Sync card rules (card style + tag style)
                    $syncCardRuleConfigInputObject = @{
                        localCardConfig         = $backlogDesignConfig.cardConfig
                        team                    = $remoteTeam.Name
                        backlogLevel            = $backlogDesignConfig.backlogLevel
                        remoteCardStyleSettings = $remoteCardSettings
                        Organization            = $Organization
                        Project                 = $project
                        removeExcessItems       = $removeExcessItems
                        DryRun                  = $dryRun
                    }
                    if ($PSCmdlet.ShouldProcess(("Card rule configuration for team [{0}]" -f $remoteTeam.Name), "Sync")) {
                        Sync-ProjectTeamCardRuleConfig @syncCardRuleConfigInputObject
                    }
                }

                # Board format specific settings
                if ($backlogDesignConfig.boardConfig.PSObject.Properties.name -contains 'columns' -or $backlogDesignConfig.boardConfig.PSObject.Properties.name -contains 'rows') {

                    $boardSettingsInputObject = @{
                        Organization = $Organization
                        Project      = $project
                        team         = $remoteTeam.Name
                        backlogLevel = $backlogDesignConfig.backlogLevel
                    }
                    $remoteBoardSettings = Get-ProjectTeamBoardSetting @boardSettingsInputObject

                    # Sync columns
                    if ($backlogDesignConfig.boardConfig.PSObject.Properties.name -contains 'columns') {
                        $syncBoardColumnConfigInputObject = @{
                            localColumnConfig   = $backlogDesignConfig.boardConfig.columns
                            team                = $remoteTeam.Name
                            backlogLevel        = $backlogDesignConfig.backlogLevel
                            remoteBoardSettings = $remoteBoardSettings
                            Organization        = $Organization
                            Project             = $project
                            removeExcessItems   = $removeExcessItems
                            DryRun              = $dryRun
                        }
                        if ($PSCmdlet.ShouldProcess(("Board Column Configuration for team [{0}]" -f $remoteTeam.Name), "Sync")) {
                            Sync-ProjectTeamBoardColumnConfig @syncBoardColumnConfigInputObject
                        }
                    }

                    # Sync rows
                    if ($backlogDesignConfig.boardConfig.PSObject.Properties.name -contains 'rows') {
                        $syncBoardRowConfigInputObject = @{
                            localRowConfig      = $backlogDesignConfig.boardConfig.rows
                            team                = $remoteTeam.Name
                            backlogLevel        = $backlogDesignConfig.backlogLevel
                            remoteBoardSettings = $remoteBoardSettings
                            Organization        = $Organization
                            Project             = $project
                            removeExcessItems   = $removeExcessItems
                            DryRun              = $dryRun
                        }
                        if ($PSCmdlet.ShouldProcess(("Board Row Configuration for team [{0}]" -f $remoteTeam.Name), "Sync")) {
                            Sync-ProjectTeamBoardRowConfig @syncBoardRowConfigInputObject
                        }
                    }
                }
            }
        }

        ####################
        #   Remove Teams   #
        ####################
        if ($removeExcessItems) {
            $teamsToRemove = [System.Collections.ArrayList]@()
            foreach ($remoteTeam in $remoteTeams) {
                if (-not ($localTeams | Where-Object { $_.Name -eq $remoteTeam.Name })) {
                    # Remove team
                    $null = $teamsToRemove.Add([PSCustomObject]@{
                            id   = $remoteTeam.Id
                            name = $remoteTeam.name
                        }
                    )
                }
            }

            if ($teamsToRemove.Count -gt 0) {
                $newProjectInputObject = @{
                    Organization  = $Organization
                    Project       = $Project
                    teamsToRemove = $teamsToRemove
                    DryRun        = $DryRun
                }
                if ($PSCmdlet.ShouldProcess(("Removal of [{0}] teams from project [{1}]|{2}]" -f $teamsToRemove.Count, $Organization, $Project), "Initiate")) {
                    Remove-ProjectTeamRange @newProjectInputObject
                }

                if (-not $DryRun) {
                    # Refresh remote data
                    $remoteTeams = Get-ProjectTeamList -Organization $Organization -Project $Project
                }
            }
            else {
                Write-Verbose "No teams to remove"
            }
        }

        $elapsedTime = (get-date) - $SyncProcessingStartTime
        $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
        Write-Verbose ("Project team sync took [{0}]" -f $totalTime)
    }
}