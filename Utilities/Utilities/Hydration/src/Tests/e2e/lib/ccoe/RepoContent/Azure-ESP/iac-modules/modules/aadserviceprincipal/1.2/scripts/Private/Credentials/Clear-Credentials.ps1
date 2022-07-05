function Clear-Credentials {
    [CmdletBinding()]
    param(
        [Parameter(
            HelpMessage = "Id of the Azure Active Directory Application to have the credentials cleared",
            Mandatory = $true,
            ParameterSetName = "KeyId"
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Expired"
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "KeepNewest"
        )]
        [guid]
        $ApplicationID,

        [Parameter(
            Mandatory = $false,
            ParameterSetName = "Expired"
        )]
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "KeepNewest"
        )]
        [ValidateSet("Password", "AssymetricX509Cert", "Any")]
        [string]
        $Type = "Any",

        [Parameter(
            HelpMessage = "Id of Key that will be cleared",
            Mandatory = $true,
            ParameterSetName = "KeyId"
        )]
        [guid[]]
        $KeyID,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Ids of the Azure Active Directory Application to have the credentials cleared",
            ParameterSetName = "Expired"
        )]
        [switch]
        $Expired,

        [Parameter(
            HelpMessage = "Number of newest credentials of the Azure Active Directory Application not to be cleared",
            ParameterSetName = "KeepNewest"
        )]
        [int]
        $KeepNewest
    )

    $TaskDescriptor = "Clear-Credentials"
    
    Write-Verbose "$TaskDescriptor - Clear credentials for Azure Active Directory App with Id '$ApplicationID'"
    $Keys = Get-AzADAppCredential -ApplicationId $ApplicationId
    Write-Verbose "$TaskDescriptor - Found $($Keys.Count) keys in Azure Active Directory App"
    Write-Verbose ($Keys | Out-String)
    switch ($PSCmdlet.ParameterSetName) {
        # case KeyId: remove the chosen key ID
        'KeyId' {
            Write-Verbose "$TaskDescriptor - Case 'KeyId': Only clear credential with Key Id '$KeyID'"
            $Keys = $Keys | Where-Object KeyId -match $KeyID
        }

        # case Expired: remove the expired credentials
        'Expired' {
            Write-Verbose "$TaskDescriptor - Case 'Expired': Only clear credentials which are expired of type '$Type'"
            if ($Type -ne "Any") {
                $Keys = $Keys | Where-Object { $_.Type -eq $Type }
            }
            $Keys = $Keys | Where-Object { (Get-Date $_.EndDate) -le (Get-Date) }
        }

        # case KeepNewest: remove credentials except newest
        'KeepNewest' {
            Write-Verbose "$TaskDescriptor - Case 'KeepNewest': Clear all credentials of type '$Type' leaving newest $KeepNewest credential(s)"
            if ($Type -ne "Any") {
                $Keys = $Keys | Where-Object { $_.Type -eq $Type }
            }
            $Keys = $Keys | Sort-Object { (Get-Date($_.StartDate)).ToFileTime() } -Descending | Select-Object -Skip $KeepNewest
        }
    }

    Write-Verbose "$TaskDescriptor - $($Keys.Count) credentials will be removed"
    Write-Verbose ($Keys | Out-String)
    foreach ($Key in $Keys) {
        Write-Verbose "$TaskDescriptor - Removing credential with Key Id '$($Key.KeyId)'"
        try {
            Remove-AzADAppCredential -ApplicationId $ApplicationId -KeyId $Key.KeyId -Force
        }
        catch {
            Write-Error $_
        }
    }
}