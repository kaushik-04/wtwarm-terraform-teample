<#
.SYNOPSIS
Get the available iterations of the project team settings for the given project

.DESCRIPTION
Get the available iterations of the project team settings for the given project

.PARAMETER Organization
Mandatory. The organization hosting the project to get the data from

.PARAMETER Project
Mandatory. The project hosting the team to get the data from

.PARAMETER Team
Mandatory. The name of the team to get the configuration of

.EXAMPLE
Get-ProjectTeamSettingIterationList -organization 'contoso' -project 'Module Playground' -Team 'someTeam'

Get the available iterations for team [contoso|Module Playground|someTeam]
#>
function Get-ProjectTeamSettingIterationList {

    param(
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [string] $Team
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTTeamSettingsIterationsGet'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), [uri]::EscapeDataString($Team))
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