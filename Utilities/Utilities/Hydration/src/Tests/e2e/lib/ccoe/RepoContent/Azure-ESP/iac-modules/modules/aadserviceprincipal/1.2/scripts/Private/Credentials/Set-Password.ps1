function Set-Password {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Id of the Azure Active Directory Application to set the password"
        )]
        [ValidateNotNullOrEmpty()]
        [string] $ApplicationId,
        
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Months that the Password will be valid from current date"
        )]
        [ValidateRange("Positive")]
        [int] $ValidityMonths = 12
    )

    $TaskDescriptor = "Set-Password"
    
    # set Application Password
    Write-Verbose "$TaskDescriptor - Create new password"
    $securePassword = ( -join ((35..126) * 80 | Get-Random -Count 128 | ForEach-Object { [char]$_ })) | ConvertTo-SecureString -AsPlainText -Force
    Write-Verbose "$TaskDescriptor - Create new password OK"
    Write-Verbose "$TaskDescriptor - Set new password as credential for Azure Active Directory App with Id '$ApplicationId'"
    New-AzADAppCredential -ApplicationId $ApplicationId -Password $securePassword -StartDate (Get-Date) -EndDate ((Get-Date).AddMonths($ValidityMonths)) | Out-Null
    Write-Verbose "$TaskDescriptor - Set new password as credential for Azure Active Directory App OK"

    return $securePassword
}