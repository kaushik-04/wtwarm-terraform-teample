<#
.SYNOPSIS
Validates if a string is null or empty

.DESCRIPTION
Validates if a string is null or empty

.PARAMETER String
The string to evaluate

.EXAMPLE
IsNullOrEmpty -String "String"

Validates if the provided sting is $null or "". This example will return false.

.EXAMPLE
"" | IsNullOrEmpty

Validates if the provided sting, using pipeing, is $null or "". This example will return true.

#>
Function IsNullOrEmpty {
    [Cmdletbinding()]
    [OutputType([bool])]
    param(
    [Parameter( Position = 0,
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
        [string]
        $String
    )
    return ("" -eq $String) -or (($null -eq $String))
}