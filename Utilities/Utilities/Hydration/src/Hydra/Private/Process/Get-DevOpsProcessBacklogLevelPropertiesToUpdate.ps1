<#
.SYNOPSIS
Get the backlog level properties that differ in between the provided local backlog level configuration & remote backlog level instance

.DESCRIPTION
Get the backlog level properties that differ in between the provided local backlog level configuration & remote backlog level instance

.PARAMETER localBacklogLevel
Mandatory. The locally configured backlog level to compare

.PARAMETER remoteBacklogLevel
Mandatory. The remotely configured backlog level to compare with

.EXAMPLE
Get-DevOpsProcessBacklogLevelPropertiesToUpdate -localBacklogLevel @{ color = '000000' } -remoteBacklogLevel @{ color = 'eeeeee' }

Get a list properties that the provided local & remote backlog level differ. In this case the result would be @('color')
#>
function Get-DevOpsProcessBacklogLevelPropertiesToUpdate {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $localBacklogLevel,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteBacklogLevel
    )

    $propertiesToUpdate = [System.Collections.ArrayList]@()

    if($localBacklogLevel.Color -and ($localBacklogLevel.Color -ne $remoteBacklogLevel.Color)) {
        $null = $propertiesToUpdate.Add('Color')
    }

    return $propertiesToUpdate
}