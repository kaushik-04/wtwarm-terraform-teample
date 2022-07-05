<#
.SYNOPSIS
Test if the given local configuration matches the remote data

.DESCRIPTION
Test if the given local configuration matches the remote data

.PARAMETER localColumnConfig
Mandatory. The local data to test with

.PARAMETER remoteBoardSettings
Mandatory. The remote data to test against

.EXAMPLE
Test-ProjectTeamBoardColumnConfigEqualsState -localColumnConfig @{} -remoteBoardSettings @{}

Returns 'true' if the local & remote config are the same
#>
function Test-ProjectTeamBoardColumnConfigEqualsState {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $localColumnConfig,

        [Parameter(Mandatory = $true)]
        [PSCustomObject] $remoteBoardSettings
    )

    # Check if any changes are required
    $formattedLocal = $localColumnConfig | Sort-Object -Property 'Name' | ForEach-Object {

        $res = @{
            name          = $_.name
            stateMappings = $_.stateMappings
        }
        if ($_.itemsInProgressLimit) { $res['itemLimit'] = $_.itemsInProgressLimit }
        if (([PSCustomObject]$_).Psobject.Properties.name -contains 'isSplit') { $res['isSplit'] = $_.isSplit }
        if ($_.definitionOfDone) { $res['description'] = $_.definitionOfDone }

        [PSCustomObject]$res
    }

    $formattedRemote = $remoteBoardSettings.columns | Where-Object { $_.columnType -notin @('incoming', 'outgoing') } | Sort-Object -Property 'Name' | ForEach-Object {

        # We may only consider properties that exist both in the local & remote item
        $remoteName = $_.Name
        $localCounterpart = $localColumnConfig | Where-Object { $_.Name -eq $remoteName }

        $res = @{
            name          = $_.name
            stateMappings = $_.stateMappings
        }

        if ($localCounterpart.itemsInProgressLimit -and $_.itemLimit) {
            $res['itemLimit'] = $_.itemLimit
        }

        if ((([PSCustomObject]$localCounterpart).Psobject.Properties.name -contains 'isSplit') -and (([PSCustomObject]$_).Psobject.Properties.name -contains 'isSplit')) {
            $res['isSplit'] = $_.isSplit
        }

        if ($localCounterpart.definitionOfDone -and $_.description) {
            $res['description'] = $_.description
        }

        [PSCustomObject]$res
    }

    return ($remoteBoardSettings.columns -and $localColumnConfig -and ([String]::Compare(($formattedLocal | ConvertTo-Json), ($formattedRemote | ConvertTo-Json), $true) -eq 0))
}