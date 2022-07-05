<#
.SYNOPSIS
Generate a new DevOps PAT

.DESCRIPTION
Generate a new DevOps PAT
Leverages a default name, scope & 1 day expiry if not provided

.PARAMETER Organization
Mandatory. The organization to create the PAT for

.PARAMETER TokenName
Optional. The name of the token to create

.PARAMETER Scope
Optional. The scope of the token to create

.PARAMETER ValidTo
Optional. The expiry date of the token to create. Defaults to one day in the future

.EXAMPLE
New-DevOpsPAT -Organization 'contoso'

Create a new PAT with default values for organization 'contoso'
#>
function New-DevOpsPAT {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $false)]
        [string] $TokenName = (Get-RelativeConfigData -configToken 'DEVOPS_PAT_NAME'),

        [Parameter(Mandatory = $false)]
        [string] $Scope = (Get-RelativeConfigData -configToken 'DEVOPS_GIT_PAT_SCOPE'),

        [Parameter(Mandatory = $false)]
        [datetime] $ValidTo = (Get-Date).AddDays(1)
    )

    $body = @{
        displayName = $TokenName
        scope       = $Scope
        validTo     = $ValidTo.ToString('yyyy-MM-ddTHH:mm:ss:ffffZ')
    }

    $restInfo = Get-RelativeConfigData -configToken 'RESTPATCreate'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization))
        body   = ConvertTo-Json $body -Depth 10 -Compress
    }

    if ($PSCmdlet.ShouldProcess(('REST command to create PAT [{0}]' -f $PAT.Name), "Invoke")) {
        $createCommandResponse = Invoke-RESTCommand @restInputObject
        if (-not [String]::IsNullOrEmpty($createCommandResponse.errorCode)) {
            Write-Error ('Failed to create PAT [{0}] because of [{1} - {2}]' -f $PAT.Name, $createCommandResponse.typeKey, $createCommandResponse.message)
            continue
        }
        else {
            return $createCommandResponse.patToken
        }
    }
}