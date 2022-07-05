<#
.SYNOPSIS
Get the current board settings for a given backlog level

.DESCRIPTION
Get the current board settings for a given backlog level, e.g. rows & columns

.PARAMETER Organization
Mandatory. The organization containing the project that hosts the team to look into

.PARAMETER Project
Mandatory. The project that hosts the team to look into

.PARAMETER team
Mandatory. The team to fetch the details for

.PARAMETER backlogLevel
Mandatory. The specific backlog level to fetch the details for

.EXAMPLE
Get-ProjectTeamBoardSetting -organization 'contoso' -project 'Module Playground' -team 'product-council' -backloglevel 'Product Portfolio'

Fetch the details for the backlog level 'Product Portfolio' of team 'product-council' of project [contoso|Module Playground]
#>
function Get-ProjectTeamBoardSetting {

    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $false)]
        [string] $team,

        [Parameter(Mandatory = $true)]
        [string] $backlogLevel
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTeamBoardGet'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), [uri]::EscapeDataString($team), [uri]::EscapeDataString($backlogLevel))
    }
    $response = Invoke-RESTCommand @restInputObject

    if (-not [String]::IsNullOrEmpty($response.errorCode)) {
        if ($DryRun) {
            return @{}
        }
        else {
            Write-Error ("[{0}]: {1}" -f $response.typeKey, $response.message)
        }
    }
    return $response
}