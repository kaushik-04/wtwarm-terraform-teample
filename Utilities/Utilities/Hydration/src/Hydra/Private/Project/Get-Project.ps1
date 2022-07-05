<#
.SYNOPSIS
Get the project that already exist in the given organization

.DESCRIPTION
Get the project that already exist in the given organization and returns the project data.

.PARAMETER Organization
Mandatory. The organization to get the project from. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project name to get. E.g. 'Module Playground'

.EXAMPLE
Get-Project -Project 'Module Playground' -Organization 'contoso'

Gets the project named 'Module Playground' from organization 'contoso' and returns hash table with project properties name, description, sourceControlType, templateTypeId and visibility
#>
function Get-Project {

    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [string] $Organization
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTProjectGet'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project))
    }
    $remoteProject = Invoke-RESTCommand @restInputObject

    if ($remoteProject.id) {

        $restInfo = Get-RelativeConfigData -configToken 'RESTProjectPropertiesGet'
        $restInputObject = @{
            method = $restInfo.Method
            uri    = $restInfo.uri -f [uri]::EscapeDataString($Organization), $remoteProject.id
        }
        $propertiesResponse = Invoke-RESTCommand @restInputObject
        if (-not $propertiesResponse.value) {
            throw ("Unable to fetch properties of project [{0}]: [{1}]" -f $remoteProject.name, $propertiesResponse)
        }
        $properties = $propertiesResponse.value

        $sourceControlTypeGit = $properties | Where-Object Name -eq 'System.SourceControlGitEnabled'
        if ($sourceControlTypeGit.value) {
            $sourceControlType = 'Git'
        }
        else {
            $sourceControlType = 'Tfvc'
        }

        return @{
            id                = $remoteProject.id
            name              = $remoteProject.name
            description       = $remoteProject.description
            sourceControlType = $sourceControlType
            templateTypeId    = ($properties | Where-Object name -eq 'System.ProcessTemplateType').value
            visibility        = $remoteProject.visibility
            defaultTeam       = @{
                id   = $remoteProject.defaultTeam.id
                name = $remoteProject.defaultTeam.name
            }
        }
    }
    else {
        return $null
    }
}