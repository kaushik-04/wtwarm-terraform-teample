<#
.SYNOPSIS
Get the process properties that differ in between the provided local process configuration & remote process instance

.DESCRIPTION
Get the process properties that differ in between the provided local process configuration & remote process instance

.PARAMETER localProcess
Mandatory. The locally configured process to compare

.PARAMETER remoteProcess
Mandatory. The remotely configured process to compare with

.EXAMPLE
Get-DevOpsProcessPropertiesToUpdate -localProcess @{ Description = 'MyDesc' } -remoteProcess @{ Description = 'New' }

Get a list properties that the provided local & remote process differ. In this case the result would be @('Description')
#>
function Get-DevOpsProcessPropertiesToUpdate {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $localProcess,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteProcess
    )

    $propertiesToUpdate = [System.Collections.ArrayList]@()

    if($localProcess.Description -and ($localProcess.Description -ne $remoteProcess.Description)) {
        $null = $propertiesToUpdate.Add('Description')
    }

    return $propertiesToUpdate
}