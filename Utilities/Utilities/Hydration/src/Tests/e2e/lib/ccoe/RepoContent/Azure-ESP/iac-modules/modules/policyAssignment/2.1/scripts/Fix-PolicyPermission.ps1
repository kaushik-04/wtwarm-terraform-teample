Function Fix-PolicyPermission {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string] $ParametersFilePath
    )
    $Role = "Contributor"

    $ParameterFile = Get-Item -Path $ParametersFilePath
    $JSON = $ParameterFile | Get-Content
    $ParameterObject = $JSON | ConvertFrom-Json

    $Scope = $ParameterObject.parameters.scope.value
    Write-Output "Scope is: $Scope"
    if ($Scope -match "/subscriptions/" ) {
        $ScopeObject = Get-AzSubscription -SubscriptionId $Scope.split('/')[-1]
    } elseif ($Scope -match "/providers/Microsoft.Management/managementGroups/") {
        $ScopeObject = Get-AzManagementGroup -GroupId $Scope.split('/')[-1]
    }
    if (-not $ScopeObject) {
        throw "The scope is not valid."
    }

    $PolicyName = $ParameterObject.parameters.properties.value.policyAssignment.displayName
    Write-Output "PolicyName is: $PolicyName"
    $Policies = Get-AzPolicyAssignment -Scope $Scope | Select-Object Name, @{n = "DisplayName"; e = { $_.Properties.DisplayName } }, @{n = "principalId"; e = { $_.Identity.principalId } }
    $Policy = $Policies | Where-Object DisplayName -match $PolicyName
    if (-not $Policy) {
        throw "The policy assignment '$PolicyName' on scope '$Scope' does not exist"
    }

    $ID = $Policy.principalId
    if (-not $ID) {
        throw "Could not retreive the managed identity id from the policy assignment."
    }

    if ($ParameterObject.parameters.properties.value.policyAssignment.parameters.logAnalytics) {
        Write-Output "RoleAssignmentScope is: logAnalytics"
        $RoleAssignmentScope = $ParameterObject.parameters.properties.value.policyAssignment.parameters.logAnalytics
        Write-Output "RoleAssignmentScope is: $RoleAssignmentScope"
    } elseif ($ParameterObject.parameters.properties.value.policyAssignment.parameters.eventHubRuleId) {
        Write-Output "RoleAssignmentScope is: eventhub"
        $RoleAssignmentScope = $ParameterObject.parameters.properties.value.policyAssignment.parameters.eventHubRuleId
        Write-Output "RoleAssignmentScope is: $RoleAssignmentScope"
    } else {
        throw "Did not find expected scope of, logAnalytics or eventHubRuleId"
    }
    $RoleAssignmentScope = ($RoleAssignmentScope.split("/") | Select-Object -first 9) -join '/'

    $Resouce = Get-AzResource -ResourceId $RoleAssignmentScope
    if (-not $Resouce) {
        throw "The resource $RoleAssignmentScope was not found."
    }


    $RoleAssignment = Get-AzRoleAssignment -Scope $RoleAssignmentScope -ObjectId $ID -RoleDefinitionName $Role
    if (-not $RoleAssignment) {
        $RoleAssignment = New-AzRoleAssignment -Scope $RoleAssignmentScope -ObjectId $ID -RoleDefinitionName $Role
    }
    $RoleAssignment

}