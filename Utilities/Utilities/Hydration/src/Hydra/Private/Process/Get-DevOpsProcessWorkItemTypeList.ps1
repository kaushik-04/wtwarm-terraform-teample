<#
.SYNOPSIS
Get the work item types for a given process

.DESCRIPTION
Get the work item types for a given process

.PARAMETER Organization
Mandatory. The organization to fetch the data from

.PARAMETER processId
Mandatory. The id of the process in the given organization to fetch the work item types from.

.EXAMPLE
Get-DevOpsProcessWorkItemTypeList -organization 'contoso' -processId '1dc4d4bf-f1a6-4f13-9e18-1d8da8fd79bf'

Get the work item types in process [contoso|1dc4d4bf-f1a6-4f13-9e18-1d8da8fd79bf]
#>
function Get-DevOpsProcessWorkItemTypeList {

    [CmdletBinding()]
    [OutputType('System.Object[]')]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $processId
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTProcessWorkItemTypeList'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $processId)
    }
    $workItemTypes = Invoke-RESTCommand @restInputObject

    if ($workItemTypes.errorCode) {
        Write-Error ("[{0}]: {1}" -f $processes.typeKey, $processes.message)
    }
    if ($workItemTypes.value) {
        return $workItemTypes.value
    }
    else {
        return @()
    }
}