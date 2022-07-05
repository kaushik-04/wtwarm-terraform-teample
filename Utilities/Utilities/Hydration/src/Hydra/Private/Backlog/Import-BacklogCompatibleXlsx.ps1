<#
.SYNOPSIS
Import a .xlsc file from the given path

.DESCRIPTION
Import a .xslx file from the given path. Also checks that each line / work item provides the minimum set of required and properly formatted properties

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

.EXAMPLE
Import-BacklogCompatibleXlsx 'C:\localBacklog.xlsx'

Import the backlog data from path 'C:\localBacklog.xlsx'
#>
function Import-BacklogCompatibleXlsx {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string] $path
    )

    begin {
    }
    process {

        # Check module
        if(-not (Get-Module "ImportExcel" -ListAvailable).Count -gt 0) {
            throw "Make sure module 'ImportExcel' is installed on your machine"
        }

        # Load data
        Write-Verbose ("Loading .xlsx file [{0}]" -f (Split-Path $path -LeafBase))
        $localBacklogData = Import-Excel -Path $path

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