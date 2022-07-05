<#
.SYNOPSIS
Get the processes that exist in the given organization

.DESCRIPTION
Get the processes that exist in the given organization

.PARAMETER Organization
Mandatory. The organization to fetch the processes for

.EXAMPLE
Get-DevOpsProcessList -Organization 'contoso'

Get the processes of organization 'contoso'
#>
function Get-DevOpsProcessList {

    [CmdletBinding()]
    [OutputType('System.Object[]')]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Organization
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTProcessList'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization))
    }
    $processes = Invoke-RESTCommand @restInputObject

    if ($processes.errorCode) {
        Write-Error ("[{0}]: {1}" -f $processes.typeKey, $processes.message)
    }
    if ($processes.value) {
        return $processes.value
    }
    else {
        return @()
    }
}