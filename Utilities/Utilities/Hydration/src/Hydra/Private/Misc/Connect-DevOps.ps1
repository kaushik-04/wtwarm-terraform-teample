<#
.SYNOPSIS
Log into the az cli devops context

.DESCRIPTION
Log into the az cli devops context
Also ensures the required devops extension for the hydration is installed

.PARAMETER skipLogin
Optional. Skip the login and uses cached credentials

.EXAMPLE
Connect-DevOps

Install and log into the az devops cli context. Will prompt for credentials

.EXAMPLE
Connect-DevOps -skipLogin

Just make sure the required devops cli extension is installed.
#>
function Connect-DevOps {

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [switch] $skipLogin
    )

    if ($pscmdlet.ShouldProcess('CLI extension [azure-devops]', 'Install')) {
        Write-Verbose "Installing DevOps CLI extension"
        az extension add --name azure-devops
    }

    if (-not $skipLogin) {
        Write-Verbose "Logging in to Azure DevOps"
        if ($pscmdlet.ShouldProcess('To CLI context', 'Login')) {
            az devops login
        }
        Write-Verbose "Login successfull"
    }
}