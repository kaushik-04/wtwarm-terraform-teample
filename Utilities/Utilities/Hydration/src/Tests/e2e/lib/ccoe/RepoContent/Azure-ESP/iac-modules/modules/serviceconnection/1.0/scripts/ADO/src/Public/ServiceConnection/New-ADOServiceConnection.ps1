function New-ADOServiceConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Parameterfile
    )

    $TaskDescriptor = 'Create Azure Service Connection'
    $cmd = "az devops service-endpoint create --service-endpoint-configuration '$Parameterfile' --detect false | ConvertFrom-Json"
    try {
        Write-Verbose $TaskDescriptor
        $CreateServiceConnection = Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
    return $CreateServiceConnection
}