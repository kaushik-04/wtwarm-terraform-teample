<#
.SYNOPSIS
Translate local properties to their remote REST counterpart

.DESCRIPTION
Translate local properties to their remote REST counterpart
E.g. 'Priority' maps to 'Microsoft.VSTS.Common.Priority' in the REST object.
The local properties as chosen based on the format one gets when exporting a query as a CSV from Azure DevOps

.PARAMETER localPropertyName
Mandatory. The local property name to get the REST counterpart for

.EXAMPLE
Get-BacklogPropertyCounterpart -localPropertyName 'Team Project'

Get the remote counterpart for property 'Team Project'. Returns 'System.TeamProject'
#>
function Get-BacklogPropertyCounterpart {

    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'local')]
        [string] $localPropertyName,
        [Parameter(Mandatory = $true, ParameterSetName = 'remote')]
        [string] $remotePropertyName
    )

    if ($localPropertyName) {

        switch ($localPropertyName) {
            'Acceptance Criteria' { return 'Microsoft.VSTS.Common.AcceptanceCriteria' }
            'Activity' { return 'Microsoft.VSTS.Common.Activity' }
            'Area Path' { return 'System.AreaPath' }
            'AreaPath' { return 'System.AreaPath' }
            'Assigned To' { return 'System.AssignedTo' }
            'Board Column' { return 'System.BoardColumn' }
            'Board Column Done' { return 'System.BoardColumnDone' }
            'Board Lane' { return 'System.BoardLane' }
            'Business Value' { return 'Microsoft.VSTS.Common.BusinessValue' }
            'BusinessValue' { return 'Microsoft.VSTS.Common.BusinessValue' }
            'Completed Work' { return 'Microsoft.VSTS.Scheduling.CompletedWork' }
            'CompletedWork' { return 'Microsoft.VSTS.Scheduling.CompletedWork' }
            'Description' { return 'System.Description' }
            'Due Date' { return 'Microsoft.VSTS.Scheduling.DueDate' }
            'DueDate' { return 'Microsoft.VSTS.Scheduling.DueDate' }
            'Effort' { return 'Microsoft.VSTS.Scheduling.Effort' }
            'ID' { return 'ID' }
            'Iteration Path' { return 'System.IterationPath' }
            'IterationPath' { return 'System.IterationPath' }
            'Original Estimate' { return 'Microsoft.VSTS.Scheduling.OriginalEstimate' }
            'OriginalEstimate' { return 'Microsoft.VSTS.Scheduling.OriginalEstimate' }
            'Priority' { return 'Microsoft.VSTS.Common.Priority' }
            'Reason' { return 'System.Reason' }
            'Repro Steps' { return 'Microsoft.VSTS.TCM.ReproSteps' }
            'ReproSteps' { return 'Microsoft.VSTS.TCM.ReproSteps' }
            'Resolved Reason' { return 'Microsoft.VSTS.Common.ResolvedReason' }
            'ResolvedReason' { return 'Microsoft.VSTS.Common.ResolvedReason' }
            'Risk' { return 'Microsoft.VSTS.Common.Risk' }
            'Severity' { return 'Microsoft.VSTS.Common.Severity' }
            'Stack Rank' { return 'Microsoft.VSTS.Common.StackRank' }
            'StackRank' { return 'Microsoft.VSTS.Common.StackRank' }
            'Start Date' { return 'Microsoft.VSTS.Scheduling.StartDate' }
            'StartDate' { return 'Microsoft.VSTS.Scheduling.StartDate' }
            'State' { return 'System.State' }
            'Story Points' { return 'Microsoft.VSTS.Scheduling.StoryPoints' }
            'StoryPoints' { return 'Microsoft.VSTS.Scheduling.StoryPoints' }
            'System Info' { return 'Microsoft.VSTS.TCM.SystemInfo' }
            'SystemInfo' { return 'Microsoft.VSTS.TCM.SystemInfo' }
            'Tags' { return 'System.Tags' }
            'Target Date' { return 'Microsoft.VSTS.Scheduling.TargetDate' }
            'TargetDate' { return 'Microsoft.VSTS.Scheduling.TargetDate' }
            'Team Project' { return 'System.TeamProject' }
            'TeamProject' { return 'System.TeamProject' }
            'Time Criticality' { return 'Microsoft.VSTS.Common.TimeCriticality' }
            'TimeCriticality' { return 'Microsoft.VSTS.Common.TimeCriticality' }
            'Title' { return 'System.Title' }
            'Value Area' { return 'Microsoft.VSTS.Common.ValueArea' }
            'ValueArea' { return 'Microsoft.VSTS.Common.ValueArea' }
            'Work Item Type' { return 'System.WorkItemType' }
            'WorkItemType' { return 'System.WorkItemType' }
            default {
                Write-Debug "No conversion of local property name [$localPropertyName] into remote counterpart implemented. Trying to use as is. If it fails, try to find the exact internal name of this property in Azure DevOps (e.g. via REST)"
                return $localPropertyName
            }
        }
    }
    else {
        switch ($remotePropertyName) {
            'System.AssignedTo' { return 'Assigned To' }
            'System.BoardColumn' { return  'Board Column' }
            'System.BoardColumnDone' { return 'Board Column Done' }
            'System.BoardLane' { return 'Board Lane' }
            'System.Tags' { return 'Tags' }
            'Microsoft.VSTS.Common.AcceptanceCriteria' { return 'Acceptance Criteria' }
            'Microsoft.VSTS.Common.Activity' { return 'Activity' }
            'System.AreaPath' { return 'Area Path' }
            'Microsoft.VSTS.Common.BusinessValue' { return 'Business Value' }
            'Microsoft.VSTS.Scheduling.CompletedWork' { return 'Completed Work' }
            'System.Description' { return 'Description' }
            'Microsoft.VSTS.Scheduling.DueDate' { return 'Due Date' }
            'Microsoft.VSTS.Scheduling.Effort' { return 'Effort' }
            'ID' { return 'ID' }
            'System.IterationPath' { return 'Iteration Path' }
            'Microsoft.VSTS.Scheduling.OriginalEstimate' { return 'Original Estimate' }
            'Microsoft.VSTS.Common.Priority' { return 'Priority' }
            'System.Reason' { return 'Reason' }
            'Microsoft.VSTS.TCM.ReproSteps' { return 'Repro Steps' }
            'Microsoft.VSTS.Common.ResolvedReason' { return 'Resolved Reason' }
            'Microsoft.VSTS.Common.Risk' { return 'Risk' }
            'Microsoft.VSTS.Common.Severity' { return 'Severity' }
            'Microsoft.VSTS.Common.StackRank' { return 'Stack Rank' }
            'Microsoft.VSTS.Scheduling.StartDate' { return 'Start Date' }
            'System.State' { return 'State' }
            'Microsoft.VSTS.Scheduling.StoryPoints' { return 'Story Points' }
            'Microsoft.VSTS.TCM.SystemInfo' { return 'System Info' }
            'Microsoft.VSTS.Scheduling.TargetDate' { return 'Target Date' }
            'System.TeamProject' { return 'Team Project' }
            'Microsoft.VSTS.Common.TimeCriticality' { return 'Time Criticality' }
            'System.Title' { return 'Title' }
            'Microsoft.VSTS.Common.ValueArea' { return 'Value Area' }
            'System.WorkItemType' { return 'Work Item Type' }
            default {
                Write-Warning "No conversion of remote property name [$remotePropertyName] into local counterpart implemented. Trying to use as is. If it fails, try to find the exact external name of this property in Azure DevOps (e.g. via CSV export)"
                return $localPropertyName
            }
        }
    }
}