<#
.SYNOPSIS
Split an array in chunks of the given size

.DESCRIPTION
Split an array in chunks of the given size.

.PARAMETER InputArray
Mandatory. The original array to split.

.PARAMETER SplitSize
Optional. The maximum bucket size per split.

.EXAMPLE
Split-Array -InputArray @(1..1005) -splitSize 100

Split the given array with 1.005 elements into chunks with size 100.Returns an array with 11 entries with 100 elements in the first 10, and 5 in the last.
#>
function Split-Array {

    [CmdletBinding()]
    [OutputType('System.Object[]')]
    param(
        [Parameter(Mandatory = $true)]
        [object[]] $InputArray,

        [Parameter(Mandatory = $false)]
        [int] $SplitSize = 200
    )

    if ($splitSize -ge $InputArray.Count) {
        return $InputArray
    }
    else {
        $res = @()
        for ($Index = 0; $Index -lt $InputArray.Count; $Index += $SplitSize) {
            $res += , ( $InputArray[$index..($index + $splitSize - 1)] )
        }
        return $res
    }
}