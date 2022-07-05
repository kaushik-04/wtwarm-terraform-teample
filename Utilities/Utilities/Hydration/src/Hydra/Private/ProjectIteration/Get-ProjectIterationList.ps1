<#
.SYNOPSIS
Loads existing projects iterations

.DESCRIPTION
Loads existing projects iterations

.PARAMETER Organization
Mandatory. The organization to get the items from. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to get the items from. E.g. 'Module Playground'

.EXAMPLE
Get-ProjectIterationList -Organization 'contoso' -Project 'Module Playground'

Get the iterations currently existing the project [Module Playground|contoso]
#>
function Get-ProjectIterationList {

    param(
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project
    )

    # Fetch root
    $restInfo = Get-RelativeConfigData -configToken 'RESTProjectIterationClassificationRootList'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project))
    }
    $rootElements = Invoke-RESTCommand @restInputObject
    if ($rootElements.errorCode) {
        Write-Error ("[{0}]: {1}" -f $rootElements.typeKey, $rootElements.message)
    }
    if (-not $rootElements) {
        return @()
    }

    $restInfo = Get-RelativeConfigData -configToken 'RESTProjectIterationClassificationChildList'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), ($rootElements.id -join ','))
    }
    $childElements = Invoke-RESTCommand @restInputObject
    if ($childElements.errorCode) {
        Write-Error ("[{0}]: {1}" -f $childElements.typeKey, $childElements.message)
    }
    if ($childElements.value) {
        return $childElements.value
    }
    else {
        return @()
    }
}