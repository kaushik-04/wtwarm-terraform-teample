function ConvertTo-Hashtable {
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    process {
        if ($null -eq $InputObject) { return $null }
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable $object
                }
            )
            $collection
        }
        elseif ($InputObject -is [psobject]) {
            $hash = @{ }
            foreach ($property in $InputObject.PSObject.Properties) {
                # special treatment for arrays required. if they contain 0 or 1 element they are not treated as array objects anymore
                if ($property.value -is [array]) {
                    $hash[$property.Name] = [array](ConvertTo-Hashtable $property.Value)
                }
                else {
                    $hash[$property.Name] = ConvertTo-Hashtable $property.Value
                }
            }
            $hash
        }
        else {
            $InputObject
        }
    }
}