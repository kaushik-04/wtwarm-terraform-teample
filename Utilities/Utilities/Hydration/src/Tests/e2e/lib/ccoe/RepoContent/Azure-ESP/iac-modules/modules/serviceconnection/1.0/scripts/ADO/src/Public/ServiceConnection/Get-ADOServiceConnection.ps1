function Get-ADOServiceConnection {
    [CmdletBinding()]
    param (
        [string]
        $Name,
        [switch]
        $Exact
    )
    $Project = Get-ADOProject
    $TaskDescriptor = 'Get and list all Azure Service Connections'
    $cmd = "az devops service-endpoint list --detect false | ConvertFrom-Json | Sort-Object name"
    try {
        Write-Verbose $TaskDescriptor
        $ServiceConnections = Invoke-Expression $cmd
        foreach ($ServiceConnection in $ServiceConnections) {
            Write-Verbose " - '$($ServiceConnection.Name)'"
        }
        Write-Verbose "$TaskDescriptor - Found $($ServiceConnections.Count) Service Connection(s) in $($Project.Name)"
        if ($Exact) {
            $ServiceConnections = $ServiceConnections | Where-Object name -EQ $Name
        } else {
            $ServiceConnections = $ServiceConnections | Where-Object name -Match $Name
        }
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
    return $ServiceConnections
}