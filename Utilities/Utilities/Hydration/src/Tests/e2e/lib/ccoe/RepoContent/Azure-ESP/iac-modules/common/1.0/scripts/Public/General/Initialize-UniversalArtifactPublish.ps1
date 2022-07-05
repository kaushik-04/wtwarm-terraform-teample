<#
.SYNOPSIS
Prepare to publish a module as an universal package to a DevOps artifact feed

.DESCRIPTION
Prepare to publish a module as an universal package to a DevOps artifact feed
The function will take evaluate which version should be published based on the provided input parameters (uiCustomVersion, pipelineCustomVersion, versioningOption) and the version currently deployed to the feed
If a UICustomVersion is provided, it has the highest priority over the other options
Second in line is the pipeline customVersion which is considered only if it is higher than the latest version deployed to the artifact feed
As a final case, one of the provided version options is chosen and applied with the default being 'patch'

The function returns
- the provided module name as a lowercase version (required by the publish-task)
- the version option to be applied if applicable
- the version to be applied if applicable

.PARAMETER moduleName
Mandatory. The name of the module to publish.

.PARAMETER vstsFeedOrganization
Mandatory. Name of the organization hosting the artifacts feed.

.PARAMETER vstsFeedProject
Optional. Name of the project hosting the artifacts feed. May be empty.

.PARAMETER vstsFeedName
Mandatory. Name to the feed to publish to.  

.PARAMETER uiCustomVersion
Optional. A custom version that can be provided by the UI. '-' represents an empty value.

.PARAMETER pipelineCustomVersion
Optional. A custom version the can be provided as a value in the pipeline file.

.PARAMETER versioningOption
Optional. A version option that can be specified in the UI. Defaults to 'patch'

.EXAMPLE
Initialize-UniversalArtifactPublish -moduleName 'keyvault' -vstsFeedOrganization 'servicescode' -vstsFeedProject '$(System.TeamProject)' -vstsFeedName 'Modules' -uiCustomVersion '3.0.0'

Try to publish the key vault module with version 3.0.0 to the module feed 'servicescode/$(System.TeamProject)/Modules' based on a value provided in the UI

.EXAMPLE
Initialize-UniversalArtifactPublish -moduleName 'keyvault' -vstsFeedOrganization 'servicescode' -vstsFeedProject '$(System.TeamProject)' -vstsFeedName 'Modules' -pipelineCustomVersion '1.0.0'

Try to publish the key vault module with version 1.0.0 to the module feed 'servicescode/$(System.TeamProject)/Modules' based on a value provided in the pipeline file

.EXAMPLE
Initialize-UniversalArtifactPublish -moduleName 'keyvault' -vstsFeedOrganization 'servicescode' -vstsFeedProject '$(System.TeamProject)' -vstsFeedName 'Modules'

Try to publish the next key vault module version to the module feed 'servicescode/$(System.TeamProject)/Modules' based on the default versioning behavior
#>
function Initialize-UniversalArtifactPublish {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $moduleName,
        
        [Parameter(Mandatory)]
        [string] $moduleVersion
    )
    # For function output
    $resultSet = @{}

    $lowerModuleName = $moduleName.ToLower()
    $major = $moduleVersion.Split(".")[0]
    $minor = $moduleVersion.Split(".")[-1]
        
    #################################
    ##    FIND CURRENT BRANCH      ##
    #################################
    $branchName = $env:BUILD_SOURCEBRANCHNAME
    Write-Verbose "Branch name is: $branchName" -Verbose
    $buildNumber = $env:BUILD_NUMBER
    $patch = $buildNumber.Split("_")[-1]
    Write-Verbose "Patch is: $patch" -Verbose

    ############################
    ##    EVALUATE VERSION    ##
    ############################

    if ([String]::Equals("master", $branchName)) {
        $newVersion = "$major.$minor.$patch".tolower()
    }
    else {
        $newVersion = ("$major.$minor.$patch-$branchName".tolower()).replace('_', '.')
    }
        
    Write-Verbose "$newVersion"

    if ($newVersion.Length -gt 128) {

        throw "The version is too long. It is $($newVersion.length) characters."
    }
        

    $resultSet['lowerModuleName'] = $lowerModuleName
    $resultSet['newVersionObject'] = $newVersion
    $resultSet['publishingMode'] = 'custom'
        
    return $resultSet
}