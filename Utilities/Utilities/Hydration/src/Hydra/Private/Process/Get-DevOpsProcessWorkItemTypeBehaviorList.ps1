<#
.SYNOPSIS
Get a list of available behaviors for the given work item type reference

.DESCRIPTION
Get a list of available behaviors for the given work item type reference

.PARAMETER Organization
Mandatory. The organization to fetch the data from

.PARAMETER Process
Mandatory. The process to fetch the data from containing the work item type in question

.PARAMETER workItemTypeReferenceName
Mandatory. The internal work item type reference to query the available behaviors for. E.g.
- CustomAgileProcess.CustomChangeRequest (<processname>.<typename> without whitespaces)
- CustomAgileProcess.de81222d-b7be-4a27-9498-53d1b55d08dd (<processname>.<guid> without whitespaces)

.EXAMPLE
Get-DevOpsProcessWorkItemTypeBehaviorList -Organization 'contoso' -Process @{ name = 'myProcess'; id = '18ccd4f7-b848-400f-be6e-8e5e77726879' } -workItemTypeReferenceName 'Custom.de81222d-b7be-4a27-9498-53d1b55d08dd'

Get the available behaviors for an work item type with reference name 'Custom.de81222d-b7be-4a27-9498-53d1b55d08dd' from process [contoso|myProcess]
#>
function Get-DevOpsProcessWorkItemTypeBehaviorList {

    [CmdletBinding()]
    [OutputType('System.Object[]')]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $Process,

        [Parameter(Mandatory = $true)]
        # e.g. CustomAgileProcess.CustomChangeRequest (<processname>.<typename> without whitespaces)
        [string] $workItemTypeReferenceName
    )

    $restInfo = Get-RelativeConfigData -configToken 'RESTProcessWorkItemTypeBehaviorList'
    $restInputObject = @{
        method = $restInfo.method
        uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $Process.id, $workItemTypeReferenceName)
    }
    $workItemTypeBehavior = Invoke-RESTCommand @restInputObject

    if ($workItemTypeBehavior.value) {
        return $workItemTypeBehavior.value
    }
    else {
        return @()
    }
}