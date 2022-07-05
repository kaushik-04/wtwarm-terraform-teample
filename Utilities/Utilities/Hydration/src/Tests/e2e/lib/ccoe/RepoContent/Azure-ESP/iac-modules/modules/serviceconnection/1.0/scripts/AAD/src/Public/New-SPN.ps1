<#
.SYNOPSIS
Creates a new SPN in the current tenant

.DESCRIPTION
Creates an AzADApplication (App registration), an AzADServicePrincipal (Enterprise App) and creates a password on the App.
If an SPN with the provided name exists, the will return the SPN object

.PARAMETER SPNName
The name of the SPN. This will be used as both display name, identifierUris and homepage for the new app.

.PARAMETER SPNPW
The password that the new SPN shall have. If a password is not assigned, one will be created by the New-SPNPassword function.

.PARAMETER SkipPasswordCreation
Skips the password creation, call New-SPNPassword seperatly

.PARAMETER PWValidityYears
The validity period of the created password

.PARAMETER Retries
How many times the function should retry requests to external APIs such as Azure.

.PARAMETER IntervalSeconds
How long the function should wait inbetween attempts to comple requests to external APIs such as Azure.

.EXAMPLE
New-SPN -SPNName "CCoE-Platform-123456-SPN" -SPNPW "ThisIsASecretPassw0rd!" -PWValidityYears 1

Ensures the existance of an SPN named "CCoE-Platform-123456-SPN". If the SPN exists the SPN is returned, no new password is generated.
If a SPN does not exist, one is created with the provided password and validity period.

#>
Function New-SPN {
    [Cmdletbinding()]
    [OutputType([Microsoft.Azure.Commands.ActiveDirectory.PSADServicePrincipal])]
    param(
        [Parameter(Mandatory)]
        [String]
        $SPNName,
        [String]
        $SPNPW,
        [switch]
        $SkipPasswordCreation,
        [int]
        $PWValidityYears = 2,
        [int]
        $Retries = 20,
        [int]
        $IntervalSeconds = 10
    )


    #Check if SPN exists
    $SPN = Get-AzADServicePrincipal -DisplayName $SPNName
    if ($SPN) {
        Write-Warning "The SPN already exists."
        return $SPN
    } else {
        Write-Verbose "SPN doesnt exist. Continuing"
        for ($i = 1; $i -le $Retries; $i++) {
            try {
                Write-Verbose "Creating SPN $SPNName - (Attempt: $i/$Retries)"
                try {
                    Write-Verbose "Creating App registration"
                    $AppTemp = New-AzADApplication -DisplayName $SPNName -IdentifierUris "http://$SPNName" -HomePage "http://$SPNName"
                    Write-Verbose "Creating App registration - Validation"
                    for ($j = 1; $j -le $Retries; $j++) {
                        Start-Sleep -Seconds $IntervalSeconds
                        $App = Get-AzADApplication -ApplicationId $AppTemp.ApplicationId
                        if ($null -ne $App) {
                            Write-Verbose "Creating App registration - Validation - Ok"
                            break
                        }
                        Write-Verbose "Creating App registration - Validation - Failed $j/$Retries"
                    }
                    Write-Verbose "Creating App registration - Done - $($App.ApplicationId) - $($App.ObjectId)"
                } catch {
                    Write-Warning $_
                    # Attempt cleanup
                    try {
                        Write-Verbose "Attempting cleanup"
                        Remove-AzADApplication -ApplicationId $App.ApplicationId -Force -ErrorAction SilentlyContinue | Out-Null
                        Write-Verbose "Attempting cleanup - Done"
                    } catch {
                        Write-Verbose "Attempting cleanup - Failed"
                    }
                    throw "Creating App registration - Failed"
                }

                try {
                    Write-Verbose "Creating Enterprise App"
                    $NewSPNTemp = New-AzADServicePrincipal -DisplayName $SPNName -ApplicationId $App.ApplicationId -SkipAssignment
                    Write-Verbose "Creating Enterprise App - Validation"
                    for ($j = 1; $j -le $Retries; $j++) {
                        Start-Sleep -Seconds $IntervalSeconds
                        $NewSPN = Get-AzADServicePrincipal -ApplicationId $NewSPNTemp.ApplicationId
                        if ($null -ne $App) {
                            Write-Verbose "Creating Enterprise App - Validation - Ok"
                            break
                        }
                        Write-Verbose "Creating Enterprise App - Validation - Failed $j/$Retries"
                    }
                    Write-Verbose "Creating Enterprise App - Done - $($NewSPN.ApplicationId) - $($NewSPN.Id)"
                } catch {
                    Write-Warning $_
                    # Attempt cleanup
                    try {
                        Write-Verbose "Attempting cleanup"
                        Remove-AzADServicePrincipal -ApplicationId $NewSPN.ApplicationId -Force -ErrorAction SilentlyContinue | Out-Null
                        Write-Verbose "Attempting cleanup - Done"
                    } catch {
                        Write-Verbose "Attempting cleanup - Failed"
                    }
                    throw "Creating Enterprise App - Failed"
                }
                if (-not $SkipPasswordCreation) {
                    try {
                        Write-Verbose "Creating App registration password"
                        $SecretPW = $SPNPW | ConvertTo-SecureString -AsPlainText -Force -ErrorAction SilentlyContinue
                        New-SPNPassword -ApplicationID $App.ApplicationId -Password $SecretPW -ValidityYears $PWValidityYears
                        Write-Verbose "Creating App registration password - Done"
                    } catch {
                        Write-Warning $_
                        throw "Creating App registration password - Failed"
                    }
                } else {
                    Write-Verbose "Skipping creation of App registration password"
                }
                Write-Verbose "Successfully completed after $i attempt(s)"
                return $NewSPN
            } catch {
                if ($i -lt $Retries) {
                    Write-Warning "Waiting $IntervalSeconds`s before trying again."
                    Start-Sleep -Seconds $IntervalSeconds
                    continue
                } else {
                    Write-Warning "Unsuccessfull attempt to create SPN."
                    throw $_
                }
            }
        }
    }
}