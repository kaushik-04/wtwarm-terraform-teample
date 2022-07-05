<#
.SYNOPSIS
Creates or updates Azure DevOps Project

.DESCRIPTION
Creates or updates Azure DevOps Project

.PARAMETER localProjects
Mandatory. The projects to update. The identifier can either be the name or id of the team.

.PARAMETER Organization
Mandatory. Azure DevOps Organization Name

.PARAMETER DryRun
Optional.Simulate and end2end execution

.PARAMETER assetsPath
Optional. Path to the assets root (folder where definition is). Must be provided if using a relative path to project icons

.EXAMPLE
Sync-Project -Organization Contoso -localProjects @( @{ name = 'newName'; description = 'desc'; sourceControlType = 'Git'; process = 'Agile'; visibility = 'private' })

Create the project using name = 'newName', description = 'desc', sourceControlType = 'Git', process = 'Agile' and visibility = 'private'
#>
function Sync-Project {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localProjects,

        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun,

        [Parameter(Mandatory = $false)]
        [string] $assetsPath
    )

    $SyncProcessingStartTime = Get-Date

    foreach ($localProject in $localProjects) {

        ################
        #   Get Data   #
        ################

        # Get remote project & format local
        $remoteProject = Get-Project -Organization $Organization -Project $localProject.name
        if (-not $localProject.templateTypeId -and $localProject.process) {
            $localProject.templateTypeId = (Get-DevOpsProcessList -Organization $definition.organizationName | Where-Object { $_.Name -eq $localProject.process }).Id
        }

        ######################
        #   Update Project   #
        ######################

        $projectsToUpdate = [System.Collections.ArrayList]@()

        if ($remoteProject) {
            if ($propertiesToUpdate = Get-ProjectPropertiesToUpdate -localProject $localProject -remoteProject $remoteProject) {
                # Update project
                $updateObject = @{
                    name = $remoteProject.Name
                    id   = $remoteProject.Id
                }
                foreach ($propertyToUpdate in $propertiesToUpdate) {
                    $updateObject[$propertyToUpdate] = $localProject.$propertyToUpdate
                    $updateObject["Old $propertyToUpdate"] = $remoteProject.$propertyToUpdate

                    if ($DryRun) {
                        # Simulate change
                        $remoteProject.$propertyToUpdate = $localProject.$propertyToUpdate
                    }
                }
                $null = $projectsToUpdate.Add([PSCustomObject]$updateObject)
            }
        }

        if ($projectsToUpdate.Count -gt 0) {
            $newProjectInputObject = @{
                Organization     = $Organization
                projectsToUpdate = $projectsToUpdate
                DryRun           = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("Update of [{0}] projects in organization [{1}]" -f $projectsToUpdate.Count, $Organization), "Initiate")) {
                Set-Project @newProjectInputObject
            }
        }
        else {
            Write-Verbose "No projects to update"
        }

        #######################
        #   Create Projects   #
        #######################

        $projectsToCreate = [System.Collections.ArrayList]@()

        if (-not $remoteProject) {
            $null = $projectsToCreate.Add([PSCustomObject]$localProject)
        }

        if ($projectsToCreate.Count -gt 0) {
            $newProjectInputObject = @{
                Organization     = $Organization
                projectsToCreate = $projectsToCreate
                DryRun           = $DryRun
            }
            if ($PSCmdlet.ShouldProcess(("Creation of [{0}] projects in organization [{1}]" -f $projectsToCreate.Count, $Organization), "Initiate")) {
                New-Project @newProjectInputObject
                start-sleep 10 # Wait for propagation
            }
        }
        else {
            Write-Verbose "No projects to create"
        }

        ################
        #   Set Icon   #
        ################
        if ((-not [String]::IsNullOrEmpty($localProject.relativeIconFilePath)) -or (-not [String]::IsNullOrEmpty($localProject.IconPathAbsolute))) {
            $iconPath = (-not [String]::IsNullOrEmpty($localProject.IconPathAbsolute)) ? $localProject.IconPathAbsolute : (Join-Path $assetsPath $localProject.relativeIconFilePath)
            if ($PSCmdlet.ShouldProcess(("Icon [$iconPath] for project [{0}]" -f $localProject.projectName), "Set")) {
                $setIconInputObject = @{
                    Organization = $Organization
                    project      = $localProject
                    iconPath     = $iconPath
                    DryRun       = $DryRun
                }
                Set-ProjectIcon @setIconInputObject
            }
        }
        else {
            Write-Verbose "No icon to set"
        }
    }

    $elapsedTime = (get-date) - $SyncProcessingStartTime
    $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
    Write-Verbose ("Project Sync create/update took [{0}]" -f $totalTime)
}