<#
.SYNOPSIS
Create, update or delete ADO Project Iterations

.DESCRIPTION
Create, update or delete ADO Project Iterations

.PARAMETER localIterations
Mandatory. The locally defined iterations. E.g. @(@{name = 'Sprint 0', attributes = @{ startDate = '2020-12-14', finishDate = '2020-12-28' }})

.PARAMETER Organization
Mandatory. The organization to create the items in, update or remove from. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to create the items in, update or remove from. E.g. 'Module Playground'

.PARAMETER removeExcessItems
Optional. Control whether or not remove iterations that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-ProjectIterationList -organization 'contoso' -project 'Module Playground' -localIterations @(@{name = 'Sprint 0', attributes = @{ startDate = '2020-12-14', finishDate = '2020-12-28' }})

Sync the defined iteration path 'Sprint 0' with the ones in project [contoso|Module Playground]
#>
function Sync-ProjectIterationList {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localIterations,

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

        $relationStringProperty = 'GEN_RelationString'

        # Build full list of iterations to hydrate
        $flatLocalIterations = Resolve-ClassificationNodesFormatted -Nodes $localIterations -project $project

        if ($remoteIterations = Get-ProjectIterationList -Organization $Organization -Project $Project) {
            $flatRemoteIterations = Resolve-ClassificationNodesFormatted -Nodes $remoteIterations
        }
        else {
            $flatRemoteIterations = @()
        }


        #########################
        #   UPDATE ITERATIONS   #
        #########################

        $iterationsToUpdate = [System.Collections.ArrayList]@()

        foreach ($remoteIteration in $flatRemoteIterations) {

            $matchingLocal = $flatLocalIterations | Where-Object {
                $_.Id -eq $remoteIteration.Id -or # Either we provided the exact guid as an id
                $_.Id -eq $remoteIteration.Name -or # Or we provide the name as the id (works too)
                ([String]::IsNullOrEmpty($_.id) -and $_.$relationStringProperty -eq $remoteIteration.$relationStringProperty)  # Or we did not provide the ID so we just match the relation string
            }
            if ($matchingLocal) {
                if ($propertiesToUpdate = Get-IterationPropertiesToUpdate -localIteration $matchingLocal -remoteIteration $remoteIteration) {
                    # Update Iteration
                    $updateObject = @{
                        id                      = $remoteIteration.Id
                        url                     = $remoteIteration.url
                        $relationStringProperty = $remoteIteration.$relationStringProperty
                    }

                    foreach ($propertyToUpdate in $propertiesToUpdate) {

                        switch ($propertyToUpdate) {
                            'Name' {
                                $updateObject.name = $matchingLocal.name
                                $updateObject["Old Name"] = $remoteIteration.name

                                if ($DryRun) {
                                    if (($remoteIteration | Get-Member -MemberType "NoteProperty").Name -notcontains 'name') {
                                        $remoteIteration | Add-Member -NotePropertyName 'name' -NotePropertyValue ''
                                    }
                                    $remoteIteration.name = $matchingLocal.name
                                }
                            }
                            'Startdate' {
                                $updateObject.startdate = $matchingLocal.attributes.startdate
                                $updateObject["Old startDate"] = ($remoteIteration.attributes.startdate) ? $remoteIteration.attributes.startdate : '-'
                                if ($DryRun) {
                                    if (($remoteIteration | Get-Member -MemberType "NoteProperty").Name -notcontains 'attributes') {
                                        $remoteIteration | Add-Member -NotePropertyName 'attributes' -NotePropertyValue ([PSCustomObject]@{})
                                    }
                                    if (($remoteIteration.attributes | Get-Member -MemberType "NoteProperty").Name -notcontains 'startdate') {
                                        $remoteIteration.attributes | Add-Member -NotePropertyName 'Startdate' -NotePropertyValue ''
                                    }
                                    $remoteIteration.attributes.Startdate = $matchingLocal.attributes.Startdate
                                }
                            }
                            'FinishDate' {
                                $updateObject.finishDate = $matchingLocal.attributes.finishDate
                                $updateObject["Old finishDate"] = ($remoteIteration.attributes.finishDate) ? $remoteIteration.attributes.finishDate : '-'
                                if ($DryRun) {
                                    if (($remoteIteration | Get-Member -MemberType "NoteProperty").Name -notcontains 'attributes') {
                                        $remoteIteration | Add-Member -NotePropertyName 'attributes' -NotePropertyValue ([PSCustomObject]@{})
                                    }
                                    if (($remoteIteration.attributes | Get-Member -MemberType "NoteProperty").Name -notcontains 'finishDate') {
                                        $remoteIteration.attributes | Add-Member -NotePropertyName 'finishDate' -NotePropertyValue ''
                                    }
                                    $remoteIteration.attributes.finishDate = $matchingLocal.attributes.finishDate
                                }
                            }
                            $relationStringProperty {
                                # NOT YET SUPPORTED. Order would need to be updated the enable e.g. removing one item to a completely new tree
                                # # Find new parent
                                # $relationParts = $matchingLocal.$relationStringProperty.Split('-[_Child_]-')
                                # $expectedParentRelationString = $relationParts[0..($relationParts.count-2)] -join '-[_Child_]-'
                                # $flatRemoteIterations | Where-Object { $_.$relationStringProperty -eq $expectedParentRelationString}

                                # if ($DryRun) {
                                #     $remoteIteration.$propertyToUpdate = $matchingLocal.$propertyToUpdate
                                # }
                            }
                        }
                    }
                    $null = $IterationsToUpdate.Add([PSCustomObject]$updateObject)
                }
            }
        }

        if ($iterationsToUpdate.Count -gt 0) {
            $setIterationsInputObject = @{
                Organization       = $Organization
                Project            = $Project
                iterationsToUpdate = $iterationsToUpdate
                DryRun             = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("Update of [{0}] iterations in project [{1}]" -f $iterationsToUpdate.Count, $Project), "Initiate")) {
                Set-ProjectIterationRange @setIterationsInputObject
            }

            if (-not $DryRun) {
                # Refresh remote data
                if ($remoteIterations = Get-ProjectIterationList -Organization $Organization -Project $Project) {
                    $flatRemoteIterations = Resolve-ClassificationNodesFormatted -Nodes $remoteIterations
                }
                else {
                    $flatRemoteIterations = @()
                }
            }
        }
        else {
            Write-Verbose "No iterations to update"
        }


        #########################
        #   REMOVE ITERATIONS   #
        #########################
        if ($removeExcessItems -and $remoteIterations.children) {
            if ($IterationToRemove = ($flatRemoteIterations | Where-Object { $_.$relationStringProperty -notin $flatLocalIterations.$relationStringProperty })) {
                $removeIterationInputObject = @{
                    Organization = $Organization
                    Project      = $Project
                    Iteration    = $IterationToRemove
                    DryRun       = $DryRun
                }
                if ($PSCmdlet.ShouldProcess(("[{0}] Iterations from project [{1}]" -f $IterationToRemove.Count, $Project), "Remove")) {
                    Remove-ProjectIterationRange @removeIterationInputObject
                }

                # Refresh data
                if ($remoteIterations = Get-ProjectIterationList -Organization $Organization -Project $Project) {
                    $flatRemoteIterations = Resolve-ClassificationNodesFormatted -Nodes $remoteIterations
                }
                else {
                    $flatRemoteIterations = @()
                }
            }
            else {
                Write-Verbose "No iterations to remove"
            }
        }

        #########################
        #   CREATE ITERATIONS   #
        #########################

        if ($iterationPathsToCreate = ($flatLocalIterations | Where-Object { $_.$relationStringProperty -notin $flatRemoteIterations.$relationStringProperty })) {
            $newIterationInputObject = @{
                Organization = $Organization
                Project      = $Project
                Iterations   = $iterationPathsToCreate
                DryRun       = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("[{0}] Iterations in project [{1}]" -f $iterationPathsToCreate.Count, $Project), "Create")) {
                New-ProjectIterationRange @newIterationInputObject
                start-sleep 10 # Wait for propagation
            }
        }
        else {
            Write-Verbose "No iterations to create"
        }

        $elapsedTime = (get-date) - $SyncProcessingStartTime
        $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
        Write-Verbose ("Project iterations sync took [{0}]" -f $totalTime)
    }
}