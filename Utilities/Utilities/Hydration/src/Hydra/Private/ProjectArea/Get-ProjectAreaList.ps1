<#
.SYNOPSIS
Loads existing projects areas

.DESCRIPTION
Loads existing projects areas

.PARAMETER Organization
Mandatory. The organization to fetch the areas from. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project to fetch the areas from. E.g. 'Module Playground'

.EXAMPLE
Get-ProjectAreaList -project 'Module Playground' -organization 'contoso'

Get all project areas in project [contoso|Module Playground]
#>
function Get-ProjectAreaList {

    param(
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project
    )

    # Fetch root
    $restInfo = Get-RelativeConfigData -configToken 'RESTProjectAreaClassificationRootList'
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

    $restInfo = Get-RelativeConfigData -configToken 'RESTProjectAreaClassificationChildList'
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