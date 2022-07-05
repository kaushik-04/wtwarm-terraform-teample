<#
.SYNOPSIS
Test if a given backlog item is properly formatted

.DESCRIPTION
Test if a given backlog item is properly formatted
Checks
- Title & Work Item Type is provided if ID is not

.PARAMETER backlogItem
Mandatoy. The item to check

.PARAMETER elementIndex
Optional. The index of the item. Used as a print out for easier identification.

.EXAMPLE
Confirm-BacklogItem -backlogItem @{ id = 1; 'Work Item Type' = 'User Story'; 'Title 3' = 'Story 1' -State 'unknown' } -elementIndex 4

Check if the provided item is valid. As the given state is invalid out would return an error message complaining about the state of the item at index 4
#>
function Confirm-BacklogItem {

    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $backlogItem,

        [Parameter(Mandatory = $false)]
        [int] $elementIndex = -1
    )

    $properties = (Get-Member -InputObject $backlogItem -MemberType 'NoteProperty').Name
    $validity = $true

    #############################
    # Mandatory property checks #
    #############################

    ## Has to have a title if no id
    ## ----------------------------
    if ([String]::IsNullOrEmpty($backlogItem.Id)) {
        $titleColumns = $properties | Where-Object { $_ -like "Title*" }
        $title = ''
        foreach ($titleColumn in $titleColumns) {
            if (-not [String]::IsNullOrEmpty($backlogItem.$titleColumn)) {
                $title = $backlogItem.$titleColumn
                break
            }
        }
        if ([String]::IsNullOrEmpty($title)) {
            Write-Error "Element [$elementIndex]: [Title] missing"
            $validity = $false
        }
    }

    ## Has to have a type if no id
    ## ---------------------------
    $workItemTypePropertyName = 'Work Item Type'
    if ([String]::IsNullOrEmpty($backlogItem.Id)) {
        if ($properties -notcontains $workItemTypePropertyName) {
            Write-Error "Element [$elementIndex]: [$workItemTypePropertyName] missing"
            $validity = $false
        }
    }

    return $validity
}