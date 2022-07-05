<#
.SYNOPSIS
Get a list of available states for a given work item type

.DESCRIPTION
Get a list of available states for a given work item type

.PARAMETER Organization
Mandatory. The organization to fetch the data from

.PARAMETER processId
Mandatory. The id of the process in the given organization that contains the provided work item type.

.PARAMETER workItemTypeReferenceName
Mandatory. The internal work item type reference to query the available states for. E.g.
- CustomAgileProcess.CustomChangeRequest (<processname>.<typename> without whitespaces)
- CustomAgileProcess.de81222d-b7be-4a27-9498-53d1b55d08dd (<processname>.<guid> without whitespaces)

.EXAMPLE
Get-DevOpsProcessWorkItemTypeStateList -Organization 'contoso' -processId '0e347f98-194b-4d2b-9377-e7933d07e77e' -workItemTypeReferenceName 'Custom.de81222d-b7be-4a27-9498-53d1b55d08dd'

Get the available states of the work item type with internal reference 'Custom.de81222d-b7be-4a27-9498-53d1b55d08dd' of process [contoso|'0e347f98-194b-4d2b-9377-e7933d07e77e']
#>
function Get-DevOpsProcessWorkItemTypeStateList {

    [CmdletBinding()]
    [OutputType('System.Object[]')]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $processId,

        [Parameter(Mandatory = $true)]
        # e.g. CustomAgileProcess.CustomChangeRequest (<processname>.<typename> without whitespaces)
        [string] $workItemTypeReferenceName
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTProcessWorkItemTypeStateList'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $processId, $workItemTypeReferenceName)
    }
    $states = Invoke-RESTCommand @restInputObject

    if ($states.errorCode) {
        Write-Error ("Failed fetching states because of [{0}]: {1}" -f $processes.typeKey, $processes.message)
    }
    if ($states.value) {
        return $states.value
    }
    else {
        return @()
    }
}