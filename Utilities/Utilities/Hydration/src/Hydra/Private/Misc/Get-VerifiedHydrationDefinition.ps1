<#
.Synopsis
Verifies and loads Hydration definition and schema.

.Description
Loads hydration definition and schema. Verifies if hydration is a valid JSON and if it is valid against hydration schema.
Populates global hydration definition variable $Global:hydrationDefinition.

.PARAMETER Path
Mandatory. Path to the hydration file

.EXAMPLE
Get-VerifiedHydrationDefinition -Path 'C:\hydrationDefinition.json'

Load and verify the hydration definition in path 'C:\hydrationDefinition.json'
#>
function Get-VerifiedHydrationDefinition {

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Hydration Parameter File Path."
        )]
        [Alias('ParameterFilePath')]
        [string] $Path
    )
    process {
        # Load the Hydration definition schema
        $schema = Get-HydraSchema

        try {
            Write-Verbose "Verifying hydration JSON file $Path"

            $null = Test-Path $Path -ErrorAction 'Stop'
            $content = Get-Content -Path $Path -Raw

            $null = Test-Json -Json $content -Schema $schema -ErrorAction 'Stop'
            Write-Verbose "The Hydration definition JSON is file compliant with the schema."
        }
        catch {
            Write-Error ($_.ErrorDetails.Message)
            throw $_
        }

        $definitionObject = ConvertFrom-Json $content
        return $definitionObject
    }
}