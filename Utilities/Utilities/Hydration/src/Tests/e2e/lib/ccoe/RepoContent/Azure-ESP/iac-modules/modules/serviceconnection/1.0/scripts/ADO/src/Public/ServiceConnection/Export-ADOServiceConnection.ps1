function Export-ADOServiceConnection {
    [CmdletBinding()]
    param (
        [string]
        $Name,
        [switch]
        $Exact,
        [string]
        $DestinationPath
    )
    $return = @()
    $TaskDescriptor = 'Export Azure Service Connections'
    Write-Verbose $TaskDescriptor
    try {
        Write-Verbose "$TaskDescriptor - Getting Service Connections"
        $ServiceConnections = Get-ADOServiceConnection -Name $Name -Exact:$Exact
        Write-Verbose "$TaskDescriptor - Getting Service Connections - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Getting Service Connections - Failed"
        throw $_
    }
    
    Write-Verbose "$TaskDescriptor - $($ServiceConnections.count) Service Connection to export"
    foreach ($ServiceConnection in $ServiceConnections) {
        Write-Verbose " - '$($ServiceConnection.Name)'" -Verbose
        $ServiceConnection.authorization.parameters | Add-Member -NotePropertyName serviceprincipalkey -NotePropertyValue $null
        $ServiceConnection | Add-Member -NotePropertyName authorized -NotePropertyValue $null
        $ServiceConnection.PSObject.Properties.Remove('createdBy')

        #Re-sort Object
        $ServiceConnection = Sort-PSObject $ServiceConnection
        
        try {
            if ($DestinationPath) {
                $return += $ServiceConnection | ConvertTo-Json -Depth 100 | Set-Content -Path "$DestinationPath/$($ServiceConnection.name).json" -Force
            } else {
                $return += $ServiceConnection | ConvertTo-Json -Depth 100
            }
        } catch {
            Write-Verbose "$TaskDescriptor - Failed"
            Write-Warning $_
        }
    }
    Write-Verbose "$TaskDescriptor - Ok"
    return $return
}