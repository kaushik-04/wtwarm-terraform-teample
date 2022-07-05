<#
.SYNOPSIS
Removes passwords for a specified SPN.

.DESCRIPTION
Removes passwords for a specified SPN. Will only remove the specified secret if KeyID is provided. If OnlyExpired is specified, then only expired keys will be removed.

.PARAMETER ApplicationID
The id of the application.

.PARAMETER KeyID
If provided, only the specified key will be removed.

.PARAMETER OnlyExpired
If specified the function only removed key which are expired.

.EXAMPLE
Remove-SPNPassword -ApplicationID <GUID> -OnlyExpired

Removes the exired keys for the specified SPN.

.EXAMPLE
Remove-SPNPassword -ApplicationID <GUID>

Removes all keys for the specified SPN.

.EXAMPLE
Remove-SPNPassword -ApplicationID <GUID> -KeyID <GUID>

Removes a specific key for the specified SPN.

#>
Function Remove-SPNPassword {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [guid]
        $ApplicationID,
        [guid]
        $KeyID,
        [switch]
        $OnlyExpired,
        [int]
        $KeepNewest
    )

    
    $Keys = Get-AzADAppCredential -ApplicationId $ApplicationId
    Write-Verbose "Found $($Keys.Count) keys on App $ApplicationID"
    if ($KeyID) {
        Write-Verbose "Only taking key with id $KeyID"
        $Keys = $Keys | Where-Object KeyId -match $KeyID
    }
    if ($OnlyExpired) {
        Write-Verbose "Only taking key which are expired"
        $Keys = $Keys | Where-Object {(Get-Date $_.EndDate) -le (Get-Date)}
    }

    if ($null -ne $KeepNewest) {
        Write-Verbose "Keeping newest $KeepNewest key(s)"
        $Keys = $Keys | Sort-Object EndDate -Descending | Select-Object -Skip $KeepNewest
    }

    Write-Verbose "There are $($Keys.Count) keys to remove on App $ApplicationID"
    foreach ($Key in $Keys) {
        Write-Verbose "Removing $($Key.KeyId)"
        try {
            Remove-AzADAppCredential -ApplicationId $ApplicationId -KeyId $Key.KeyId -Force
        } catch {
            Write-Error $_
        }
    }
}