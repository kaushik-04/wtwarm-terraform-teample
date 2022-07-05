<#
.SYNOPSIS
Get the project team settings regarding area paths for the given project

.DESCRIPTION
Get the project team settings regarding area paths for the given project

.PARAMETER Organization
Mandatory. The organization hosting the project to get the data from

.PARAMETER Project
Mandatory. The project hosting the team to get the data from

.PARAMETER Team
Mandatory. The name of the team to get the configuration of

.PARAMETER DryRun
Optional. Simulate the end2end execution

.EXAMPLE
Get-ProjectTeamSettingFieldValue -organization 'contoso' -project 'Module Playground' -Team 'someTeam'

Get the area path configuration for team [contoso|Module Playground|someTeam]
#>
function Get-ProjectTeamSettingFieldValue {

    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [string] $Team,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTTeamSettingsFieldValuesGet'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project), [uri]::EscapeDataString($Team))
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