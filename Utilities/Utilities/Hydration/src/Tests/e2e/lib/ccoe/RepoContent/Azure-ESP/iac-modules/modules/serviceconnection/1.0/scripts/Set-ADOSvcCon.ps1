function Set-ADOSvcCon {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ParameterfilePath,
        [int] $KeepNewest = 3
    )

    #region Connect to service
    Write-Verbose "Connect to ADO"
    Connect-ADOOrganization -OrganizationURI $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI -ProjectName $env:SYSTEM_TEAMPROJECT -PAT $env:AZURE_DEVOPS_EXT_PAT

    $Parameterfile = Get-Item -Path $ParameterfilePath
    Write-Output "Processing file : $($Parameterfile.FullName)"

    $SvcObj = Get-Content -Path $Parameterfile | ConvertFrom-Json
    $SPNAppID = $SvcObj.authorization.parameters.serviceprincipalid
    Write-Output "Found AppID: $SPNAppID"

    $SPN = Get-AzADServicePrincipal -ApplicationId $SPNAppID -Verbose
    $SPN
    "App id secrets:"
    $SPNCreds = Get-AzADAppCredential -ApplicationId $SPNAppID
    $SPNCreds
    "Remove all secrets, but the $KeepNewest newest..."
    Remove-SPNPassword -ApplicationId $SPNAppID -KeepNewest $KeepNewest -Verbose
    "App id secrets:"
    $SPNCreds = Get-AzADAppCredential -ApplicationId $SPNAppID
    $SPNCreds

    "Create new SPN Password"
    $SPNPW = New-SPNPassword -ApplicationID $SPNAppID -Verbose

    Set-ADOServiceConnection -Path $Parameterfile -SPNSecret $SPNPW.Secret

    #region Disconnect all connections!
    Write-Verbose "Disconnect all connections"

    try {
        Disconnect-ADOOrganization
    }
    catch {
        Write-Warning "Failed to disconnect ADO"
    }
    #endregion
}