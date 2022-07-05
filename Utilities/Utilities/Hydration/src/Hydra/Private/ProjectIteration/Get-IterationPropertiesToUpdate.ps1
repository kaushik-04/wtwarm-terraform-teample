<#
.SYNOPSIS
Compare a local & remote Iteration to get the properties that diverge

.DESCRIPTION
Compare a local & remote Iteration to get the properties that diverge
Currently compares 'Name', 'StartDate', 'EndDate' & hierarchy

.PARAMETER localIteration
Mandatory. The local Iteration to look into. E.g. @{ name = 'nameA' }

.PARAMETER remoteIteration
Mandatory. The remote Iteration to compare with E.g. @{ name = 'nameB' }

.EXAMPLE
Get-IterationPropertiesToUpdate -localIteration @{ name = 'nameA'; startDate = '01.01.2042' } -remoteIteration @{ name = 'nameA'; startDate = '09.09.2099' }

Compare the given Iterations. The given examples results in the return value '@(startDate)'
#>
function Get-IterationPropertiesToUpdate {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $localIteration,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteIteration
    )

    $propertiesToUpdate = [System.Collections.ArrayList]@()
    $relationStringProperty = 'GEN_RelationString'

    if (($localIteration.attributes.startDate) -and
        ((-not $remoteIteration.attributes.startDate) -or
            ($remoteIteration.attributes.startDate -and $localIteration.attributes.startDate -ne ([DateTime]$remoteIteration.attributes.startDate).ToString('yyyy-MM-dd')))) {
        $null = $propertiesToUpdate.Add('Startdate')
    }

    if (($localIteration.attributes.finishDate) -and
        ((-not $remoteIteration.attributes.finishDate) -or
            ($remoteIteration.attributes.finishDate -and $localIteration.attributes.finishDate -ne ([DateTime]$remoteIteration.attributes.finishDate).ToString('yyyy-MM-dd')))) {
        $null = $propertiesToUpdate.Add('FinishDate')
    }

    if ($localIteration.Name -ne $remoteIteration.Name) {
        $null = $propertiesToUpdate.Add('Name')
    }

    if ($localIteration.$relationStringProperty -ne $remoteIteration.$relationStringProperty) {
        $null = $propertiesToUpdate.Add($relationStringProperty)
    }

    return $propertiesToUpdate
}