function Remove-ADOServiceConnection {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position=0 )]
        [string]
        $ID
    )
    $TaskDescriptor = "Removing Azure Service Connection"
    $cmd = "az devops service-endpoint delete --id $ID --yes --detect false"
    try {
        Write-Verbose "$TaskDescriptor - $ID"
        Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - $ID - Ok"
        return $true
    } catch {
        Write-Verbose "$TaskDescriptor - $ID - Failed"
        throw $_
    }
    return $true
}