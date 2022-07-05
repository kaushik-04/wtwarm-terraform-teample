function Sort-PSObject {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]    
        [PSObject]
        $Object
    )

    $SC = [ordered]@{}
    $Properties = $Object.psobject.properties
    $SortedProperties = $Properties | Sort-Object Name

    #Check for change
    $PropertiesNames = $Properties.Name
    $SortedPropertiesNames = $SortedProperties.Name
    if (Compare-Object -ReferenceObject $PropertiesNames -DifferenceObject $SortedPropertiesNames -SyncWindow 0) {
        Write-Verbose "Order will change"
        Write-Verbose "Order was:"
        $PropertiesNames | ForEach-Object {Write-Verbose "- $_"}
        Write-Verbose "Order will be:"
        $SortedPropertiesNames | ForEach-Object {Write-Verbose "- $_"}
    } else {
        Write-Verbose "Order will NOT change"
    }

    foreach ($Property in $SortedProperties) {
        Write-Verbose "---------------------------------"
        Write-Verbose "Processing $($Property.Name)"
        Write-Debug "Value: $($Property.Value)"
        Write-Debug "Type: $($Property.TypeNameOfValue)"
        if ($Property.TypeNameOfValue -eq "System.Management.Automation.PSCustomObject") {
            $SC[$Property.Name] = Sort-PSObject -Object $Property.Value
        } else {
            $SC[$Property.Name] = $Property.Value
        }
    }
    return New-Object PSCustomObject -Property $SC
}