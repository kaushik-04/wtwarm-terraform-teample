<#
.SYNOPSIS
Get the work item type properties that differ in between the provided local work item type configuration & remote work item type instance

.DESCRIPTION
Get the work item type properties that differ in between the provided local work item type configuration & remote work item type instance

.PARAMETER localWorkItemType
Mandatory. The locally configured work item type to compare

.PARAMETER remoteWorkItemType
Mandatory. The remotely configured work item type to compare with

.EXAMPLE
Get-DevOpsProcessWorkItemTypePropertiesToUpdate -locallocalWorkItemType @{ Color = 'eeeeee'; Description = 'MyDesc' } -remotelocalWorkItemType @{ Color = 'eeeeee'; Description = 'New' }

Get a list properties that the provided local & remote work item type differ. In this case the result would be @('Description')
#>
function Get-DevOpsProcessWorkItemTypePropertiesToUpdate {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $localWorkItemType,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteWorkItemType
    )

    $propertiesToUpdate = [System.Collections.ArrayList]@()

    if ($localWorkItemType.Color -and ($localWorkItemType.Color -ne $remoteWorkItemType.Color)) {
        $null = $propertiesToUpdate.Add('Color')
    }
    if ($localWorkItemType.icon -and ($localWorkItemType.icon -ne $remoteWorkItemType.icon)) {
        $null = $propertiesToUpdate.Add('Icon')
    }
    if ($localWorkItemType.Description -and ($localWorkItemType.Description -ne $remoteWorkItemType.Description)) {
        $null = $propertiesToUpdate.Add('Description')
    }

    return $propertiesToUpdate
}