<#
.SYNOPSIS
Try to identify matching remote backlog items for those that don't have an ID configured locally

.DESCRIPTION
Try to identify matching remote backlog items for those that don't have an ID configured locally

.PARAMETER localBacklogData
Mandatory. The local backlog data to identify the IDs for

.PARAMETER remoteBacklogData
Optional. The remote backlog data used to find matching counterparts to the local data

.EXAMPLE
Resolve-BacklogLocalItemId -localBacklogData @(@{ id = 1; 'Work Item Type' = 'Epic'; Title = 'Item 1'; gen_relationString = 'Epic=Item 1'}; @{ 'Work Item Type' = 'Epic'; Title = 'Item 2'; gen_relationString = 'Epic=Item 2'}; @{ 'Work Item Type' = 'Epic'; Title = 'Item 3'; gen_relationString = 'Epic=Item 3'}}) -remoteBacklogData  @(@{ id = 1; fields = @{ 'System.Title' = 'Item 1'; 'System.WorkItemType' = 'Epic'}; gen_relationString = 'Epic=Item 1'}, @{ id = 2; fields = @{ 'System.Title' = 'Item 2'; 'System.WorkItemType' = 'Epic'}; gen_relationString = 'Epic=Item 2'})

Match the provided local data with the remote counterparts. In the given example
- Item #1 keeps ID 1 (as provided)
- Item #2 matches a remote item by its relation string and gets ID 2 assigned
- Item #3 matches no remote item and has no ID configured, so no action is taken
#>
function Resolve-BacklogLocalItemId {

    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $localBacklogData,

        [Parameter(Mandatory = $false)]
        [PSCustomObject[]] $remoteBacklogData = @()
    )

    foreach ($backlogItem in $localBacklogData | Where-Object { [String]::IsNullOrEmpty($_.Id) }) {

        if ($matchingRemote = $remoteBacklogData | Where-Object { $_.GEN_relationString -eq $backlogItem.GEN_relationString }) {

            if ($matchingRemote -is [array]) {
                throw "This should not happen. Found duplicate matching remote item "
            }

            # Assign local ID
            if (($backlogItem | Get-Member -MemberType "NoteProperty" ).Name -notcontains "Id") {
                $backlogItem | Add-Member -NotePropertyName 'Id' -NotePropertyValue ''
            }
            $backlogItem.Id = $matchingRemote.Id
        }
    }
}