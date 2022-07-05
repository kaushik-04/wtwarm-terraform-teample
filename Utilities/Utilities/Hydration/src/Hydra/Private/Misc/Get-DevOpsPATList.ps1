<#
.SYNOPSIS
Fetch the currently existing PAT tokens from the given organization

.DESCRIPTION
Fetch the currently existing PAT tokens from the given organization

.PARAMETER Organization
Mandatory. The organization to fetch the tokens from

.EXAMPLE
Get-DevOpsPATList -Organization 'contoso'

Fetch the current tokens of organization 'contoso'
#>
function Get-DevOpsPATList {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTPATList'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization))
    }

    if ($PSCmdlet.ShouldProcess(('REST command to list PATs of org [{0}]' -f $Organization), "Invoke")) {
        $listCommandResponse = Invoke-RESTCommand @restInputObject
        if (-not [String]::IsNullOrEmpty($listCommandResponse.errorCode)) {
            Write-Error ('Failed to fetch PATs for org [{0}] because of [{1} - {2}]' -f $Organization, $listCommandResponse.typeKey, $listCommandResponse.message)
            continue
        }
        else {
            return $listCommandResponse.patTokens
        }
    }
}