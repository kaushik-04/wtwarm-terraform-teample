<#
.SYNOPSIS
Get the state properties that differ in between the provided local state configuration & remote state instance

.DESCRIPTION
Get the state properties that differ in between the provided local state configuration & remote state instance

.PARAMETER localState
Mandatory. The locally configured state to compare

.PARAMETER remoteState
Mandatory. The remotely configured state to compare with

.EXAMPLE
Get-DevOpsstatePropertiesToUpdate -localstate @{ Color = 'eeeeee' } -remotestate @{ Color = '000000' }

Get a list properties that the provided local & remote state differ. In this case the result would be @('Color')
#>
function Get-DevOpsProcessWorkItemTypeStatePropertiesToUpdate {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $localState,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteState
    )

    $propertiesToUpdate = [System.Collections.ArrayList]@()

    if($localState.Color -and ($localState.Color -ne $remoteState.Color)) {
        $null = $propertiesToUpdate.Add('Color')
    }
    if($localState.StateCategory -and ($localState.StateCategory -ne $remoteState.StateCategory)) {
        $null = $propertiesToUpdate.Add('StateCategory')
    }

    return $propertiesToUpdate
}