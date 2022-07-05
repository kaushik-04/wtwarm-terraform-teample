<#
.SYNOPSIS
Compare a local & remote project to get the properties that diverge

.DESCRIPTION
Compare a local & remote project to get the properties that diverge
Currently compares 'Name', 'Description' & 'Visibility'

.PARAMETER localProject
Mandatory. The local project to look into. E.g. @{ name = 'nameA'; description = 'descriptionA'; visibility = 'private' }

.PARAMETER remoteProject
Mandatory. The remote project to compare with E.g. @{ name = 'nameB'; description = 'descriptionB'; visibility = 'public' }

.EXAMPLE
Get-ProjectPropertiesToUpdate -localProject @{ name = 'nameA'; description = 'descriptionY'; visibility = 'private' } -remoteProject @{ name = 'nameA'; description = 'descriptionZ'; visibility = 'private' }

Compare the given project. The given examples results in the return value '@(description)'
#>
function Get-ProjectPropertiesToUpdate {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable] $localProject,

        [Parameter(Mandatory = $true)]
        [Hashtable] $remoteProject
    )

    $propertiesToUpdate = [System.Collections.ArrayList]@()

    if ($localProject.Name -ne $remoteProject.Name) {
        $null = $propertiesToUpdate.Add('name')
    }

    if ($localProject.Description -ne $remoteProject.Description) {
        $null = $propertiesToUpdate.Add('description')
    }

    if ($localProject.Visibility -ne $remoteProject.Visibility) {
        $null = $propertiesToUpdate.Add('visibility')
    }

    return $propertiesToUpdate
}