<#
.SYNOPSIS
Searches for a GUID in a string and returns the GUID it found.

.DESCRIPTION
Searches for a GUID in a string and returns the GUID it found.

.PARAMETER String
The string to search for a GUID in.

.EXAMPLE
Search-GUID -String "This might be a GUID: f6d1c148-588e-46f4-b641-d80940609442"
f6d1c148-588e-46f4-b641-d80940609442

Searches for a string in the text and returns the GUID.

.NOTES
General notes
#>
Function Search-GUID {
    [Cmdletbinding()]
    [OutputType([guid])]
    param(
        [Parameter( Mandatory=$true,
                    Position = 0,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [string]
        $String
    )
    Write-Verbose "Looking for a GUID in $String"
    $GUID = $String.ToLower() |
        Select-String -Pattern "[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12}" | 
        Select-Object -ExpandProperty Matches |
        Select-Object -ExpandProperty Value
    Write-Verbose "Found GUID: $GUID"
    return $GUID
}