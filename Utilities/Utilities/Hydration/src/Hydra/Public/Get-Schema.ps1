<#
    .SYNOPSIS
    Returns the schema used for hydration

    .DESCRIPTION
    Returns the schema used for hydration

    .EXAMPLE
    Get-HydraSchema

    Explanation of what the example does
#>
function Get-Schema {

    [CmdletBinding()]
    param ()

    process {
        # $Env:SCHEMA_FILE_NAME = "hydrationSchema.json"
        # $Env:SCHEMA_FILE_PATH = Join-Path $PSScriptRoot $SCHEMA_FILE_NAME

        #FIXME: This is complete crap and should not be allowed, however, it makes the tests work
        # In case you are just using the module, the first if should work
        # If you are hacky like us the tests can not access the `Module.FileList` somehow - please fixme if you know how.
        if ( $MyInvocation.MyCommand.Module.FileList) {
            $Env:SCHEMA_FILE_PATH = $MyInvocation.MyCommand.Module.FileList[0]
        }
        else {
            # Somehow this is not beeing set in the tests, because we need to dot-source the module using C#
            if ($PSScriptRoot) {
                $root = $PSScriptRoot
            }
            # Make it work in Azure DevOps
            elseif ($Env:BUILD_SOURCESDIRECTORY) {
                $root = Join-Path -Path $Env:BUILD_SOURCESDIRECTORY -ChildPath 'Utilities' -AdditionalChildPath @('Hydration', 'src', 'Hydra')
            }
            # Make it work during local tests
            # Local test execution that require private functions, e.g. Get-VerifiedHydrationDefinition needs to be executed from the folder ./Utilities/Hydration/ because I decided so - sorry
            else {
                $root = Join-Path -Path 'src' -ChildPath 'Hydra'
            }
            $fixed_path = Join-Path $root 'Hydra.Schema.json'
            $Env:SCHEMA_FILE_PATH = $fixed_path
            Write-Warning "Load from fixed path $fixed_path"
        }

        $Env:SCHEMA_FILE = Get-Item -Path $Env:SCHEMA_FILE_PATH -ErrorAction Stop
        $Env:SCHEMA_STRING = Get-Content -Path $Env:SCHEMA_FILE -Raw

        return $Env:SCHEMA_STRING
    }
}