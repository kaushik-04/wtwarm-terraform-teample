<#
.SYNOPSIS
Sync the locally defined backlog data with their remote counterparts create/update/remove workitems and create/remove relations in the process

.DESCRIPTION
Sync the locally defined backlog data with their remote counterparts create/update/remove workitems and create/remove relations in the process

.PARAMETER localBacklogData
Mandatory. The backlog items to create, update or remove

.PARAMETER Organization
Mandatory. The organization to create the items in. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to create the items in. E.g. 'Module Playground'

.PARAMETER removeExcessItems
Optional. Control whether or not to remove backlog items that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-Backlog -localBacklogData  @(@{ id = 1; 'Work Item Type' = 'Epic'; 'Title 1' = 'Item 1'}; @{ 'Work Item Type' = 'Epic'; 'Title 2' = 'Item 2'}; @{ 'Work Item Type' = 'Epic'; 'Title 1' = 'Item 3'}}) -Organization 'contoso' -project 'Module Playground' -removeExcessItems

Process the given board data based on the current state in the remote project [contoso\Module Playground]. Once the function executed the remote state should map 1:1 to the locally defined data
Item 1 will be created\updated
Item 2 will be created\updated
Item 3 will be created\update

Item 1 will have a parent-child relationship to Item 2
#>
function Sync-Backlog {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localBacklogData,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    $SyncProcessingStartTime = Get-Date

    # Generate relation hierarchy string - used to identify items without having their id
    Resolve-BacklogLocalFormatted -localBacklogData $localBacklogData
    $localDuplicates = ($localBacklogData.gen_relationstring | Group-Object | Where-Object { $_.Count -gt 1 }).Values
    if ($localDuplicates.Count -gt 0) {
        $duplicateString = ($localDuplicates | ForEach-Object { "- {0}`n" -f $_ } | Out-String)
        Write-Error ("Found [{0}] duplicate items in the same hierarchy in the local data. Each workitem title/type combination must be unique per hierarchy level.`n{1}" -f $localDuplicates.count, $duplicateString)
        return
    }

    # Generate relation hierarchy string
    # Used to find the correct remote items matching the local data without having their id
    if ($remoteBacklogData = Get-BacklogItemsCreated -Project $Project -Organization $Organization -fetchDetails -expandCategory 'Relations' -dryRun:$DryRun) {
        Resolve-BacklogRemoteFormatted -remoteBacklogData $remoteBacklogData
    }
    $remoteDuplicates = ($remoteBacklogData.gen_relationstring | Group-Object | Where-Object { $_.Count -gt 1 }).Values
    if ($remoteDuplicates.Count -gt 0) {
        $duplicateString = ($remoteDuplicates | ForEach-Object { "- {0}`n" -f $_ } | Out-String)
        Write-Error ("Found [{0}] duplicate items in the same hierarchy in the remote data. Each workitem title/type combination must be unique per hierarchy level.`n{1}" -f $remoteDuplicates.count, $duplicateString)
        return
    }

    # Match as many local & remote items as possible (match IDs & relation strings)
    $resolveIdsInputObject = @{ localBacklogData = $localBacklogData }
    if ($resolveIdsInputObject) { $resolveIdsInputObject['remoteBacklogData'] = $remoteBacklogData }
    Resolve-BacklogLocalItemId @resolveIdsInputObject

    $itemsToCreate = $localBacklogData | Where-Object { [String]::IsNullOrEmpty($_.Id) }
    $itemsExisting = $localBacklogData | Where-Object { -not [String]::IsNullOrEmpty($_.Id) }

    ######################
    # Create Board Items #
    ######################
    if ($itemsToCreate) {
        $inputParameters = @{
            workItemsToCreate = $itemsToCreate
            Organization      = $Organization
            Project           = $Project
            DryRun            = $DryRun
        }
        if ($PSCmdlet.ShouldProcess(("[{0}] backlog items" -f $itemsToCreate.Count), "Create")) {
            New-BacklogItemRange @inputParameters
        }
    }
    else {
        Write-Verbose "No backlog items to create"
    }

    ######################
    # Update Board Items #
    ######################

    foreach ($existingItem in $itemsExisting) {

        $matchingRemote = $remoteBacklogData | Where-Object {
            $_.Id -eq $existingItem.Id -or # Either we provided the exact guid as an id
            $_.Id -eq $existingItem.Name -or # Or we provide the name as the id (works too)
            ([String]::IsNullOrEmpty($_.id) -and $_.$relationStringProperty -eq $existingItem.$relationStringProperty)  # Or we did not provide the ID so we just match the relation string
        }

        if ($propertiesToUpdate = Get-WorkItemPropertiesToUpdate -localWorkItem $existingItem -remoteWorkItem $matchingRemote) {

            if (($existingItem | Get-Member -MemberType "NoteProperty" ).Name -notcontains "GEN_PropertiesToUpdate") {
                $existingItem | Add-Member -NotePropertyName 'GEN_PropertiesToUpdate' -NotePropertyValue ''
            }
            $existingItem.'GEN_PropertiesToUpdate' = $propertiesToUpdate
        }
    }

    if ($itemsToUpdate = ($itemsExisting | Where-Object { $_.'GEN_PropertiesToUpdate' })) {
        $inputParameters = @{
            workItemsToUpdate = $itemsToUpdate
            Organization      = $Organization
            DryRun            = $DryRun
        }
        if ($PSCmdlet.ShouldProcess(("[{0}] backlog items" -f $itemsToUpdate.Count), "Update")) {
            Set-BacklogItemRange @inputParameters
        }
    }
    else {
        Write-Verbose "No backlog items to update"
    }

    # Analyze Relations
    $expectedRelations = Get-BacklogItemLocalRelationTupleList -localBacklogData $localBacklogData

    #############################
    # Remove Excess Board Items #
    #############################

    # Update local data to latest remote
    if ($remoteBacklogData = Get-BacklogItemsCreated -Project $Project -Organization $Organization -fetchDetails -expandCategory 'Relations' -dryRun:$DryRun) {
        Resolve-BacklogRemoteFormatted -remoteBacklogData $remoteBacklogData
    }

    # Cleanup excess work items
    if ($removeExcessItems -and ($remoteBacklogData.Count -gt 0)) {
        # Identify excess items
        $excessItems = $remoteBacklogData | Where-Object { $localBacklogData.Id -notcontains $_.Id }
        if ($excessItems.Count -gt 0) {
            Write-Verbose ("Found [{0}] excess items to remove." -f $excessItems.Count)
            $removeInputObject = @{
                excessItems  = $excessItems
                Organization = $Organization
                DryRun       = $DryRun
            }
            if ($PSCmdlet.ShouldProcess("Excess board items", "Remove")) {
                Remove-BacklogItemExcess @removeInputObject
            }

            if (-not $DryRun) {
                # Refresh data
                if ($remoteBacklogData = Get-BacklogItemsCreated -Project $Project -Organization $Organization -fetchDetails -expandCategory 'Relations' -dryRun:$DryRun) {
                    Resolve-BacklogRemoteFormatted -remoteBacklogData $remoteBacklogData
                }
            }
        }
        else {
            Write-Verbose "No backlog items to remove"
        }
    }

    ###########################
    # Remove Excess Relations #
    ###########################

    if ($remoteBacklogData) {
        $rawRemoteRelations = Get-BacklogItemRemoteRelationTupleList -remoteBacklogData $remoteBacklogData
        # Note: We're filtering anything but hierarchical remote child-relationships because anything else is not supported in the local board data
        $remoteRelations = $rawRemoteRelations | Where-Object { $_.relationType -eq 'Child' }
    }

    $evalRelationInputObject = @{}
    if ($expectedRelations) { $evalRelationInputObject['localBacklogRelations'] = $expectedRelations }
    if ($remoteRelations) { $evalRelationInputObject['remoteBacklogRelations'] = $remoteRelations }

    if ($relationsToRemove = Get-BacklogRelationsToRemove @evalRelationInputObject) {
        Write-Verbose ("Found [{0}] excess relations to remove" -f $relationsToRemove.Count)
        $removeRelationsInputObject = @{
            relationsToRemove = $relationsToRemove
            remoteBacklogData = $remoteBacklogData
            Organization      = $Organization
            DryRun            = $DryRun
        }
        if ($PSCmdlet.ShouldProcess("Excess board item relations", "Remove")) {
            Remove-BacklogItemRelationExcess @removeRelationsInputObject
        }

        if (-not $DryRun) {
            # Refresh data
            if ($remoteBacklogData = Get-BacklogItemsCreated -Project $Project -Organization $Organization -fetchDetails -expandCategory 'Relations' -dryRun:$DryRun) {
                Resolve-BacklogRemoteFormatted -remoteBacklogData $remoteBacklogData

                $rawRemoteRelations = Get-BacklogItemRemoteRelationTupleList -remoteBacklogData $remoteBacklogData
                # Note: We're filtering anything but hierarchical remote child-relationships because anything else is not supported in the local board data
                $remoteRelations = $rawRemoteRelations | Where-Object { $_.relationType -eq 'Child' }
            }
        }
    }
    else {
        Write-Verbose "No backlog item relations to remove"
    }


    ####################
    # Create Relations #
    ####################

    $evalRelationInputObject = @{}
    if ($expectedRelations) { $evalRelationInputObject['localBacklogRelations'] = $expectedRelations }
    if ($remoteRelations) { $evalRelationInputObject['remoteBacklogRelations'] = $remoteRelations }

    if ($relationsToSet = Get-BacklogRelationsToSet @evalRelationInputObject) {
        Write-Verbose ("Found [{0}] missing relations to set" -f $relationsToSet.Count)
        # Create relations
        $setRelationInputObject = @{
            relationsToSet = $relationsToSet
            Organization   = $Organization
            DryRun         = $DryRun
        }
        if ($PSCmdlet.ShouldProcess("Board item relations", "Set")) {
            Set-BacklogItemRelationRange @setRelationInputObject
        }
    }
    else {
        Write-Verbose "No backlog item relations to set"
    }

    $elapsedTime = (get-date) - $SyncProcessingStartTime
    $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
    Write-Verbose ("Backlog Sync create/update took [{0}]" -f $totalTime)
}