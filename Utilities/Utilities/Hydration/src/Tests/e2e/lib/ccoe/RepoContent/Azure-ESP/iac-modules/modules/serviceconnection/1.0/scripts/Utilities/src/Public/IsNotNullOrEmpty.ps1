<#
.SYNOPSIS
Validates if a string is not null or empty

.DESCRIPTION
Validates if a string is not null or empty

.PARAMETER String
The string to evaluate

.EXAMPLE
IsNotNullOrEmpty -String "String"

Validates if the provided sting is $null or "". This example will return true.

.EXAMPLE
"" | IsNotNullOrEmpty

Validates if the provided sting, using pipeing, is $null or "". This example will return false.

#>
Function IsNotNullOrEmpty {
    [Cmdletbinding()]
    [OutputType([bool])]
    param(
    [Parameter( Position = 0,
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
        [string]
        $String
    )
    return ("" -ne $String) -and (($null -ne $String))
}