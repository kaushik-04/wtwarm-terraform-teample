<#
.SYNOPSIS
Loads existing projects teams

.DESCRIPTION
Loads existing projects teams

.PARAMETER Organization
Mandatory. The organization containing the project to fetch the teams from

.PARAMETER Project
Mandatory. The project to fetch the teams from

.EXAMPLE
Get-ProjectTeamList -Organization 'contoso' -Project 'Module Playground'

Load the teams from project [contoso|Module Playground]
#>
function Get-ProjectTeamList {

    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Azure DevOps Organization."
            )]
        [string] $Organization,

        [Parameter(
            Mandatory = $true,
            HelpMessage = "Azure DevOps Project."
            )]
        [string] $Project
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTTeamList'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project))
    }
    $existingItems = Invoke-RESTCommand @restInputObject

    if($existingItems.value) {
        return $existingItems.value
    } else {
        return @()
    }
}