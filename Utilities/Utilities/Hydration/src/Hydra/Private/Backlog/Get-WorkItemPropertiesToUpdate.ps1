<#
.SYNOPSIS
Compare a local & remote workItem to get the properties that diverge

.DESCRIPTION
Compare a local & remote workItem to get the properties that diverge

.PARAMETER localWorkItem
Mandatory. The local workItem to look into. E.g. @{ name = 'nameA'; description = 'descriptionA'; visibility = 'private' }

.PARAMETER remoteWorkItem
Mandatory. The remote workItem to compare with E.g. @{ name = 'nameB'; description = 'descriptionB'; visibility = 'public' }

.EXAMPLE
Get-WorkItemPropertiesToUpdate -localWorkItem @{ name = 'nameA'; description = 'descriptionY'; visibility = 'private' } -remoteWorkItem @{ name = 'nameA'; description = 'descriptionZ'; visibility = 'private' }

Compare the given workItem. The given examples results in the return value '@(description)'

.NOTES
Available:
Acceptance Criteria
Accepted By
Accepted Date
Activated By
Activated Date
Activity
Application Launch Instructions
Application Start Information
Application Type
Area Path
Assigned To
Associated Context
Associated Context Code
Associated Context Owner
Associated Context Type
Attached File Count
Authorized As
Authorized Date
Automated Test Id
Automated Test Name
Automated Test Storage
Automated Test Type
Automation status
Board Column
Board Column Done
Board Lane
Business Value
Changed By
Changed Date
Closed By
Closed Date
Closed Status
Closed Status Code
Closing Comment
Comment Count
Completed Work
Created By
Created Date
Description
Due Date
Effort
External Link Count
Finish Date
Found In
History
Hyperlink Count
ID
Integration Build
Issue
Iteration Path
Local Data Source
Node Name
Original Estimate
Parameters
Parent
Priority
Query Text
Rating
Reason
Related Link Count
Remaining Work
Remote Link Count
Repro Steps
Resolved By
Resolved Date
Resolved Reason
Rev
Reviewed By
Revised Date
Risk
Severity
Stack Rank
Start Date
State
State Change Date
State Code
Steps
Story Points
System Info
Tags
Target Date
Team Project
Test Suite Audit
Test Suite Type
Test Suite Type Id
Time Criticality
Title
Value Area
Watermark
Work Item Type
#>
function Get-WorkItemPropertiesToUpdate {

    [CmdletBinding()]
    [OutputType('System.Collections.ArrayList')]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $localWorkItem,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteWorkItem
    )

    $propertiesToUpdate = [System.Collections.ArrayList]@()

    $availableProperties = ($localWorkItem | Get-Member -MemberType 'NoteProperty').Name
    $relevantProperties = $availableProperties | Where-Object {
        $_ -notin @('id') -and
        $_ -notlike "Title *" -and
        $_ -notlike "GEN_*" -and
        (-not [String]::IsNullOrEmpty($localWorkItem.$_)) }

    foreach ($localProperty in $relevantProperties) {

        $remoteProperty = Get-BacklogPropertyCounterpart -localPropertyName $localProperty

        # Dates need special care due to their format
        if ($localProperty -like "*Date*") {
            if (((-not $remoteWorkItem.fields.$remoteProperty) -or
                    ($remoteWorkItem.fields.$remoteProperty -and ([DateTime]$localWorkItem.$localProperty).ToString('yyyy-MM-dd') -ne ([DateTime]$remoteWorkItem.fields.$remoteProperty).ToString('yyyy-MM-dd')))) {
                $null = $propertiesToUpdate.Add($localProperty)
            }
        }
        elseif ($localProperty -in @('Assigned To') -and $localWorkItem.$localProperty -match (Get-RelativeConfigData -configToken 'RegexEmail')) {
            # matches email format
            $email = $Matches[1]
            if ($email -ne $remoteWorkItem.fields.$remoteProperty.uniqueName) {
                $null = $propertiesToUpdate.Add($localProperty)
            }
        }
        else {
            if ($localWorkItem.$localProperty -ne $remoteWorkItem.fields.$remoteProperty) {
                $null = $propertiesToUpdate.Add($localProperty)
            }
        }
    }

    return $propertiesToUpdate
}