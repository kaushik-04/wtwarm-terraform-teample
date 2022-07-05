<#
.SYNOPSIS
Import a .csv file from the given path

.DESCRIPTION
Import a .csv file from the given path. Also checks that each line / work item provides the minimum set of required and properly formatted properties

The column structure should look like the following:

Flat structure
--------------
| ID | Work Item Type | Title |
| -- | -------------- | ----- |

Hierachical structure
---------------------
| ID | Work Item Type | Title 1 | Title 2 |
| -- | -------------- | ------- | ------- |

where 'Title 2' is a child item of 'Title 1'

.PARAMETER path
Mandatory. The Path  to the file to import

.PARAMETER delimiter
Optional. The delimiter used by the CSV to separate cells. Defaults to ','

.EXAMPLE
Import-BacklogCompatibleCSV 'C:\localBacklog.csv'

Import the backlog data from path 'C:\localBacklog.csv'

.NOTES
The Azure DevOps export with delimiter ';' by default. However, if you're leveraging tags, it switches to ','
#>
function Import-BacklogCompatibleCSV {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [string] $path
    )

    begin {
    }
    process {

        # Load data
        Write-Verbose ("Loading .csv file [{0}]" -f (Split-Path $path -LeafBase))


        # Identify delimiter
        $header = (Get-Content -Path $path)[0]
        if($header -match ';') {
            $delimiter = ';'
        } elseif($header -match ',') {
            $delimiter = ','
        } else {
            throw 'Unable to identify CSV delimiter. Please use either "," or ";"'
        }

        # Load data
        $localBacklogData = Import-Csv -Path $path -Delimiter $delimiter

        # Validation
        $invalidDataPoints = [System.Collections.ArrayList] @()
        for ($elementIndex = 0; $elementIndex -lt $localBacklogData.Count; $elementIndex++) {
            $res = Confirm-BacklogItem -backlogItem $localBacklogData[$elementIndex] -elementIndex $elementIndex
            if (-not $res) {
                $null = $invalidDataPoints.Add($res)
            }
        }

        if ($invalidDataPoints.Count -gt 0) {
            throw ("Found [{0}] problems with the input data." -f $invalidDataPoints.Count)
        }
    }

    end {
        return $localBacklogData
    }
}