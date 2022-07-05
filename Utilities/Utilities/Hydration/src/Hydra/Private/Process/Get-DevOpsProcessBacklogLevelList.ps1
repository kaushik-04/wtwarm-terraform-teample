<#
.SYNOPSIS
Get all backlog levels / the backlog portfolio of the given process

.DESCRIPTION
Get all backlog levels / the backlog portfolio of the given process

.PARAMETER Organization
Mandatory. The organization to fetch the data from

.PARAMETER processId
Mandatory. The process id to fetch the data from

.EXAMPLE
Get-DevOpsProcessBacklogLevelList -Organization 'contoso' -processId 'ac076f52-f7cb-48ae-b37e-a150f2dfbbef'

Get the backlog levels for process [contoso|ac076f52-f7cb-48ae-b37e-a150f2dfbbef]
#>
function Get-DevOpsProcessBacklogLevelList {

    [CmdletBinding()]
    [OutputType('System.Object[]')]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $processId
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTProcessBacklogLevelList'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $processId)
    }
    $backlogLevel = Invoke-RESTCommand @restInputObject

    if ($backlogLevel.errorCode) {
        Write-Error ("[{0}]: {1}" -f $processes.typeKey, $processes.message)
    }
    if ($backlogLevel.value) {
        return $backlogLevel.value
    }
    else {
        return @()
    }
}