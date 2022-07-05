<#
.SYNOPSIS
Creates a new password (secret) for an application

.DESCRIPTION
Creates a new password (secret) for an application. If a password is not specified, the function creates a password.

.PARAMETER ApplicationID
The id of the application.

.PARAMETER Password
If specified, this is the password that will be given to the SPN

.PARAMETER ValidityYears
The validity period of the created password

.EXAMPLE
New-SPNPassword -ApplicationID <GUID>

Generates a new password for the specified application.

.EXAMPLE
New-SPNPassword -ApplicationID <GUID> -Password 'MyPlaceholder'

Creates a new password using the provided password for the specified application.

.NOTES
General notes
#>
Function New-SPNPassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [guid]
        $ApplicationID,
        [securestring]
        $Password,
        [int]
        $ValidityYears = 2,
        [int]
        $Retries = 20,
        [int]
        $IntervalSeconds = 10
    )
    $StartDate = Get-Date
    $EndDate = (Get-Date).AddYears($ValidityYears)

    if($Password | IsNotNullOrEmpty){
        Write-Verbose "Setting specified password"
        $SecurePassword = $Password
    } else {
        Write-Verbose "Generating a random password"
        $SecurePassword = New-GUID | ConvertTo-SecureString -AsPlainText -Force
    }

    for ($i=1;$i -lt $Retries; $i++) {
        try {
            Write-Verbose "Attempting to find the App"
            $App = Get-AzADApplication -ApplicationId $ApplicationID -ErrorAction Stop
            Write-Verbose "Found the App"
            break
        } catch {
            Write-Warning "Couldnt find the SPN"
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
    $Secret = $App | New-AzADAppCredential -Password $SecurePassword -StartDate $StartDate -EndDate $EndDate
    $Secret | Add-Member -NotePropertyName Secret -NotePropertyValue $SecurePassword -Force
    return $Secret
}