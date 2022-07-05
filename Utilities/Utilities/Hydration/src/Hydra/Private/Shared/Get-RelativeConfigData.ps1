<#
.SYNOPSIS
Get config data from the moduleconfig as for the given parameters

.DESCRIPTION
Get config data from the moduleconfig as for the given parameters
Includes token replacement if tokens are provided as part of the valueMap

.PARAMETER configToken
To token to search for. E.g. DatabricksApiPathClusterList

.PARAMETER valueMap
A hastable of key/value pairs to replace tokens in values returned from the Module config. E.g. @{ Location = 'WE' }
If the module config value is 'custom-<project>-<location>' and the value map @{ Project = 'Contoso'; Location = 'we' }
it returns the result 'custom-contoso-we'

.PARAMETER ConfigPath
Path of the config file to fetch data from

.EXAMPLE
Get-RelativeConfigData -configToken 'DefaultIterationCount'

Returns the value for token 'DefaultIterationCount'. E.g. '2'

.EXAMPLE
Get-RelativeConfigData -configToken 'DefaultProjectName' -valuemap @{ Project = 'Contoso'; Location = 'we' }

Returns the value for token 'DefaultProjectName' and formats the result with the given valuemap. E.g. 'custom-contoso-we'

.EXAMPLE
Get-RelativeConfigData -configToken 'DefaultIterationCount' -ConfigPath (Join-Path (Split-Path $PScriptRoot -Parent) 'SomeConfig.psd1')

Returns the value for token 'DefaultIterationCount' from file 'SomeConfig.psd1'. E.g. '2'
#>
function Get-RelativeConfigData {

    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string] $configToken,

        [Parameter(Mandatory = $false)]
        [Hashtable] $valueMap = @{ },

        [Parameter(Mandatory = $false)]
        [string] $ConfigPath = $moduleConfigPath
    )

    process {
        $moduleConfig = Import-PowerShellDataFile -Path $ConfigPath
        $data = $moduleConfig[$configToken]

        ## Replace tokens
        if ($valueMap.Count -gt 0) {

            $result = @()
            foreach ($entry in $data) {
                foreach ($key in $valueMap.Keys) {
                    if ($entry -is [System.Collections.Hashtable]) {
                        $item = @{ }
                        foreach ($key in $entry.Keys) { $item[$key] = $entry[$key].Replace("<{0}>" -f $key.ToLower(), $valueMap[$key]) }
                        $entry = $item
                    }
                    elseif ($entry -is [String]) {
                        $entry = $entry | ForEach-Object { $_.Replace("<{0}>" -f $key.ToLower(), $valueMap[$key]) }
                    }
                    else {
                        # do nothing
                    }
                }
                if ($data -is [array]) {
                    $result += $entry
                }
                else {
                    $result = $entry
                }
            }
        }
        else {
            $result = $data
        }

        return , $result # ',' preserves array
    }
}
