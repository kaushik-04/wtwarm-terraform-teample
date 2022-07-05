<#
.Synopsis
Create or remove ADO Project Areas based on the given data and remote state

.Description
Create or remove ADO Project Areas based on the given data and remote state

.PARAMETER localAreaPaths
Mandatory. The area paths to create, update or remove

.PARAMETER Organization
Mandatory. The organization to create the items in or remove from. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to create the items in or remove from. E.g. 'Module Playground'

.PARAMETER removeExcessItems
Optional. Control whether or not remove areas that are not defined in the local dataset

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Sync-ProjectAreaList -organization 'contoso' -project 'Module Playground' -localAreaPaths @(@{ name = 'itemA'; children = @( @{ name = 'ItemB' })},  @{ name = 'itemC'})

Sync the defined area paths A,B & C with the ones in project [contoso|Module Playground]
#>
function Sync-ProjectAreaList {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localAreaPaths,

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

        # Build full list of areas to hydrate
        $flatLocalAreas = Resolve-ClassificationNodesFormatted -Nodes $localAreaPaths -project $project

        # Get existing areas - root is always the default area with all custom areas underneath it
        # Area Path Root with children
        if ($remoteAreas = Get-ProjectAreaList -Organization $Organization -Project $Project) {
            $flatRemoteAreas = Resolve-ClassificationNodesFormatted -Nodes $remoteAreas
        }
        else {
            $flatRemoteAreas = @()
        }

        ####################
        #   REMOVE AREAS   #
        ####################
        if ($removeExcessItems -and $remoteAreas.children) {
            if ($areaPathsToRemove = ($flatRemoteAreas | Where-Object { $_.$relationStringProperty -notin $flatLocalAreas.$relationStringProperty })) {
                $removeAreaInputObject = @{
                    Organization = $Organization
                    Project      = $Project
                    AreaPaths    = $areaPathsToRemove
                    DryRun       = $DryRun
                }
                if ($PSCmdlet.ShouldProcess(("[{0}] Areas from project [{1}]" -f $areaPathsToRemove.Count, $Project), "Remove")) {
                    Remove-ProjectAreaRange @removeAreaInputObject
                }

                if (-not $DryRun) {
                    # Refresh data
                    if ($remoteAreas = Get-ProjectAreaList -Organization $Organization -Project $Project) {
                        $flatRemoteAreas = Resolve-ClassificationNodesFormatted -Nodes $remoteAreas
                    }
                    else {
                        $flatRemoteAreas = @()
                    }
                }
            }
            else {
                Write-Verbose "No areas to remove"
            }
        }

        ####################
        #   CREATE AREAS   #
        ####################
        if ($areaPathsToCreate = ($flatLocalAreas | Where-Object { $_.$relationStringProperty -notin $flatRemoteAreas.$relationStringProperty })) {
            $newAreaInputObject = @{
                Organization = $Organization
                Project      = $Project
                AreaPaths    = $areaPathsToCreate
                DryRun       = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("[{0}] Areas in project [{1}]" -f $areaPathsToCreate.Count, $project), "Create")) {
                New-ProjectAreaRange @newAreaInputObject
                start-sleep 10 # Wait for propagation
            }
        }
        else {
            Write-Verbose "No areas to create"
        }

        $elapsedTime = (get-date) - $SyncProcessingStartTime
        $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
        Write-Verbose ("Project area sync took [{0}]" -f $totalTime)
    }
}