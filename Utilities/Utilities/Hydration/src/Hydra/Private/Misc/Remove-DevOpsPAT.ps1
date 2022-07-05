<#
.SYNOPSIS
Remote a PAT token by authorization ID from the given organization

.DESCRIPTION
Remote a PAT token by authorization ID from the given organization

.PARAMETER Organization
Mandatory. The organization to remove the PAT token from

.PARAMETER AuthorizationId
Mandatory. The authorization id of the token to remove.
Can be extracted when fetching current PAT tokens.

.EXAMPLE
Remove-DevOpsPAT -Organization 'contoso' -AuthorizationId '12345'

Remove the PAT token with authorization ID '12345' from organization 'contoso'
#>
function Remove-DevOpsPAT {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [string] $AuthorizationId
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTPATRevoke'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $AuthorizationId)
    }

    if ($PSCmdlet.ShouldProcess(('REST command to revoke PAT [{0}]' -f $PAT.Name), "Invoke")) {
        $revokeCommandResponse = Invoke-RESTCommand @restInputObject
        if (-not [String]::IsNullOrEmpty($revokeCommandResponse.errorCode)) {
            Write-Error ('Failed to revoke PAT [{0}] because of [{1} - {2}]' -f $PAT.Name, $revokeCommandResponse.typeKey, $revokeCommandResponse.message)
            continue
        }
    }
}