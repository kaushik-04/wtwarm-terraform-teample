<#
.SYNOPSIS
Compare a local & remote team to get the properties that diverge

.DESCRIPTION
Compare a local & remote team to get the properties that diverge
Currently compares 'Name' & 'Description'

.PARAMETER localTeam
Mandatory. The local team to look into. E.g. @{ name = 'nameA'; description = 'descriptionA' }

.PARAMETER remoteTeam
Mandatory. The remote team to compare with E.g. @{ name = 'nameB'; description = 'descriptionB' }

.EXAMPLE
Get-ProjectTeamPropertiesToUpdate -localTeam @{ name = 'nameA'; description = 'descriptionY' } -remoteTeam @{ name = 'nameA'; description = 'descriptionZ' }

Compare the given teams. The given examples results in the return value '@(description)'
#>
function Get-ProjectTeamPropertiesToUpdate {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $localTeam,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteTeam
    )

    $propertiesToUpdate = [System.Collections.ArrayList]@()

    if($localTeam.Name -ne $remoteTeam.Name) {
        $null = $propertiesToUpdate.Add('Name')
    }

    if($localTeam.Description -and ($localTeam.Description -ne $remoteTeam.Description)) {
        $null = $propertiesToUpdate.Add('Description')
    }

    return $propertiesToUpdate
}