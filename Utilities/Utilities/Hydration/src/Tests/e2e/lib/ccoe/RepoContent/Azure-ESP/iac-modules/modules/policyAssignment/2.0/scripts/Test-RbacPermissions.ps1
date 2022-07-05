function Test-RbacPermissions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [boolean]$CheckRbacPermissionsForAllScopes,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Identity,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$AssignmentObject
    )

    Write-Output "    Checking the User/Service Principal authorization on the specified scopes..."

    #Initialize authorization status variable and required roles authorized to assign/modify Policies
    $ScopeAuthorizationStatus = $null

    $requiredRoleNames = @("Owner")
    $scope = $AssignmentObject.scope.value
    Write-Output "    Checking authorization on scope $Scope..."

    $roleAssignments = Get-AzRoleAssignment -Scope $scope -ErrorAction SilentlyContinue | Where-Object { $requiredRoleNames -contains $_.RoleDefinitionName }

    if (-not $roleAssignments) {
        Write-Warning "Unable to get Azure RBAC Role Assignments ! Check whether the Client with Object ID: $($Identity.Id) has permissions to read on the given scope and if a Service Principal is used, check whether it has assigned the AAD DIRECTORY READER role"
        Write-Output ""
    }

    $ScopeAuthorizationStatus = $false

    if ($roleAssignments.ObjectId -contains $Identity.Id) {
        $ScopeAuthorizationStatus = $true
    }
    elseif ($groupIds = ($roleAssignments | Where-Object { $_.ObjectType -eq "Group" }).ObjectId) {
        foreach ($groupId in $groupIds) {
            $ScopeAuthorizationStatus = Test-GroupMembers -GroupId $groupId -PrincipalId $Identity.Id -ScopeAuthorizationStatus $ScopeAuthorizationStatus

            if ($ScopeAuthorizationStatus -eq $true) {
                break
            }
        }
    }

    # Abort the script execution in case one of the scopes did not pass authorization check
    if ($ScopeAuthorizationStatus -eq $false) {
        Write-Error "        The Client with Object ID: $($Identity.Id) is not assigned one of the required roles to change assignments on the given scope, aborting the script !" -ErrorAction Stop
        Write-Output ""
    }

    # Report successful auhtorization check while all of the scopes passed
    Write-Output "    The Client with Object ID: $($Identity.Id) has been authorized"
}

