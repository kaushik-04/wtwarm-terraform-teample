function Test-AssignmentsJson {
    param (
        [Parameter(Mandatory = $true)][PSCustomObject]$JsonRootScope
    )

    $script:NumberOfScopes++

    Write-Host "        Testing assignment scope $($script:NumberOfScopes): $($JsonRootScope.Scope)"

    ($JsonRootScope | ConvertTo-Json -Depth 100) | Test-Json -Schema $schema -ErrorAction Stop | Out-Null

    $uniqueAssignments = @()
    $AssignmentsInScope = $JsonRootScope.policyAssignments + $JsonRootScope.policySetAssignments
    foreach ($Item in $AssignmentsInScope) {
        if ($uniqueAssignments -notcontains $Item.name) {
            $uniqueAssignments += $Item.name
        }
        else {
            Write-Error "There is more than one policy assignment defined in the JSON in the ""$($JsonRootScope.Scope)"" scope with the name of ""$($Item.name)""." -ErrorAction Stop
        }
    }

    if ($JsonRootScope.children) {
        foreach ($JsonChildScope in $JsonRootScope.children) {
            Test-AssignmentsJson -JsonRootScope $JsonChildScope
        }
    }

}