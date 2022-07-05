function Compare-ParameterObjects {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$InputObject1,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$InputObject2
    )

    $areEqual = $true
    foreach ($property1 in $InputObject1.PSObject.Properties) {

        $key = $property1.Name
        $property2 = $InputObject2.PSObject.Properties.Item($key)

        if ($null -ne $property2) {
            if ($InputObject1.$key -is [array]) {
                If ( Compare-Object -ReferenceObject $property1.Value -DifferenceObject $property2.value) {
                    return $false
                }
            }
            elseif ($property1.Value -is [PsCustomObject]) {
                $areEqual = Compare-ParameterObjects $property1.value $property2.value
                if (-not ($areEqual)) {
                    return $false
                }
            }
            elseif ($property1.Value.GetType().Name -eq 'DateTime') {
                Write-Output "COMPARING DATETIME Value in SuObject!!!"
                # ToString("o") converts DateTime format to string like "03/31/2020 21:51:19"
                if ($property1.Value.ToString("o") -ne $property2.value) {
                    return $false
                }
            }
            else {
                if (-not (($property1.Value) -eq ($property2.value))) {
                    return $false
                }
            }
        }
        else {
            return $false
        }
    }
    #check if there is an object in object2 that is missing in object1, then obj1 and obj2 are also different
    foreach ($property2 in $InputObject2.PSObject.Properties) {
        $key2 = $property2.Name
        $property1 = $InputObject1.PSObject.Properties.Item($key2)
        if ($null -eq $property1) {
            return $false
        }
    }
    return $areEqual
}
