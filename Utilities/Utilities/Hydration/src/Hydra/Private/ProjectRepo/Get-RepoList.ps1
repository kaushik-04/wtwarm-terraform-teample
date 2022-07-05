<#
.Synopsis
Get the repos that already exist in the given project

.Description
Get the repos that already exist in the given project and returns the repos data.

.PARAMETER Organization
Mandatory. The organization to get the project from. E.g. 'contoso'

.PARAMETER Project
Mandatory. The project name to get. E.g. 'Module Playground'

.Example
Get-RepoList -Project 'Module Playground' -Organization 'contoso'

Gets the repos from organization 'contoso' and returns hash table with repo properties name
#>
function Get-RepoList {

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
    $restInfo = Get-RelativeConfigData -configToken 'RESTRepositoriesList'
    $restInputObject = @{
        method = $restInfo.method
        uri    = $restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project)
    }
    $existingItems = Invoke-RESTCommand @restInputObject
    if ($existingItems.value) {
        return $existingItems.value
    }
    else {
        return @()
    }
}