function  Test-GroupMembers {
    param (
        [Parameter(Mandatory = $true)][string]$GroupId,
        [Parameter(Mandatory = $true)][string]$PrincipalId,
        [Parameter(Mandatory = $true)][boolean]$ScopeAuthorizationStatus
    )

    $groupMembers = Get-AzADGroupMember -GroupObjectId $GroupId
    if ($groupMembers.Id -contains $PrincipalId) {
        return $true
    }
    elseif ($groupIds = ($groupMembers | Where-Object { $_.ObjectType -eq "Group" }).Id) {

        foreach ($groupId in $groupIds) {

            Test-GroupMembers -GroupId $groupId -PrincipalId $PrincipalId

            if ($ScopeAuthorizationStatus -eq $true) {
                break
            }
        }

    }

}