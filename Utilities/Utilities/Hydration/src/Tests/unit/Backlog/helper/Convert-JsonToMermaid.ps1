function Get-TitleForId {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int] $id,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $source        
    )

    $matchingItem = $source | Where-Object { $_.Id -eq $id }
    return $matchingItem.fields.'System.Title'

    ($relationData | Where-Object { $_.Id -eq $id }).fields.'System.Title'
}

function Convert-JsonToMermaid {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $relationDataPath,

        [Parameter(Mandatory = $false)]
        [switch] $includeNonHierarchyRelations
    )

    $relationData = ConvertFrom-Json (Get-Content -Path $relationDataPath -Raw) 

    Clear-Host
    Write-Host '```mermaid'
    Write-Host 'flowchart BT;'

    $relations = [System.Collections.ArrayList]@()
    foreach ($relationItem in $relationData) {
        $currentId = $relationItem.Id
        $currenttitle = $relationItem.fields.'System.Title'
        $itemIdTitleTuple = "{0}[{0}<br/>{1}]" -f $currentId, $currenttitle

        if(-not $includeNonHierarchyRelations) {
            $configuredRelations = $relationItem.relations | Where-Object { $_.attributes.Name -eq 'Child' }
            foreach($otherItem in $relationItem.relations | Where-Object { $_.attributes.Name -ne 'Child' -and $_.attributes.Name -ne 'Parent' }) {
                $relation = "{0}[{0}<br/>{1}]" -f $otherItem.url.Split('/')[-1], ($relationData | Where-Object { $_.Id -eq $otherItem.url.Split('/')[-1] }).fields.'System.Title'
                $null = $relations.Add($relation)
            }
        } else {
            $configuredRelations = $relationItem.relations
        }

        foreach ($relation in $configuredRelations) {
            $relationItemId = $relation.url.Split('/')[-1]
            $relationItemTitle = ($relationData | Where-Object { $_.Id -eq $relationItemId }).fields.'System.Title'
            $relationIdTitleTuple = "{0}[{0}<br/>{1}]" -f $relationItemId, $relationItemTitle

            switch ($relation.rel) {
                'System.LinkTypes.Hierarchy-Forward' { 
                    $relation = "{0} -- Child --> {1}" -f $relationIdTitleTuple, $itemIdTitleTuple
                    $null = $relations.Add($relation)
                }
                'System.LinkTypes.Hierarchy-Reverse' { 
                    $relation = "{1} -- Child --> {0}" -f $relationIdTitleTuple, $itemIdTitleTuple
                    $null = $relations.Add($relation)
                }
                Default {
                    $forward = "{0} -. {1} .- {2}" -f $itemIdTitleTuple, $relation.attributes.name, $relationIdTitleTuple
                    $reverse = "{2} -. {1} .- {0}" -f $itemIdTitleTuple, $relation.attributes.name, $relationIdTitleTuple
                    if ($relations -notcontains $forward -and $relations -notcontains $reverse) {
                        $null = $relations.Add($forward)
                    }
                }
            }
        }
    }
    $relations | Select-Object -Unique

    Write-Host '```'
}