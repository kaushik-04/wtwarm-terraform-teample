function Set-Application {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Name of the Azure Active Directory Application to set"
        )]
        [ValidateNotNullOrEmpty()]
        [string] $ApplicationName
    )

    $TaskDescriptor = "Set-Application"

    #get Application
    Write-Verbose "$TaskDescriptor - Get Azure Active Directory App with name '$ApplicationName'"
    $App = Get-AzAdApplication -DisplayName $ApplicationName
    if ($App) {
        #update Application
        Write-Verbose "$TaskDescriptor - Azure Active Directory App with name '$ApplicationName' already exists"
    }
    else {
        #create Application
        Write-Verbose "$TaskDescriptor - Create Azure Active Directory App with name '$ApplicationName'"
        $params = @{
            DisplayName    = $ApplicationName
            IdentifierUris = "http://$ApplicationName"
            HomePage       = "http://$ApplicationName"
        }
        Write-Verbose ($params | Out-String)
        $App = New-AzAdApplication @params
        Write-Verbose "$TaskDescriptor - Create Azure Active Directory App OK"
    }
    if ([String]::IsNullOrEmpty($App)) {
        throw "$TaskDescriptor - Set Azure Active Directory App with name '$ApplicationName' FAILED"
    }

    Write-Verbose ($App | Out-String)
    return $App
}