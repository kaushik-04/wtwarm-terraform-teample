function Get-ADOGroup {
    [Cmdletbinding()]
    param(
        [string]
        $Name,
        [switch]
        $Exact
    )
    $cmd = "az devops security group list --detect false | ConvertFrom-Json"
    $Groups = Invoke-Expression $cmd
    $Groups = $Groups.graphGroups
    if ($PSBoundParameters.ContainsKey('Name')) {
        if ($PSBoundParameters.ContainsKey('Exact')) {
            $Groups = $Groups | Where-Object displayName -EQ $Name
        } else {
            $Groups = $Groups | Where-Object displayName -Match $Name
        }
    }
    return $Groups
}