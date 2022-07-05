<#
.SYNOPSIS
Test given definition file against the schema

.PARAMETER Path
Path to the definition template file

.EXAMPLE
Test-HydraDefinition -Path 'C:\dev\hydration.json'

Test the hydration definition file in path 'C:\dev\hydration.json'
#>
function Test-Template {

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Path to the hydration definition JSON."
        )]
        [string] $Path
    )
    try {
        $null = Get-VerifiedHydrationDefinition -ParameterFilePath $Path
    }
    catch {
        throw $_
    }

    return $true
}