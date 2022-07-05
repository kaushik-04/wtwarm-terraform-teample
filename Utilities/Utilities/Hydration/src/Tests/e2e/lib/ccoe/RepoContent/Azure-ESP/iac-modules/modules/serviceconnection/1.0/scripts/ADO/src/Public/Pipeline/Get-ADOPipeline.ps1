function Get-ADOPipeline {
    [CmdletBinding()]
    param (
        [string]
        $Name,
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        [switch]
        $Exact
    )
    $TaskDescriptor = 'Get and list all Azure Pipelines'
    $cmd = 'az pipelines list --detect false | ConvertFrom-Json | Sort-Object -Property Path, Name'
    try {
        Write-Verbose $TaskDescriptor
        $azurePipelines = Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Total found $($azurePipelines.Count) Azure Pipeline(s)"
        if ($Path){
            $azurePipelines = $azurePipelines | Where-Object Path -like "*$Path*"
        }
        if ($Exact) {
            $azurePipelines = $azurePipelines | Where-Object Name -EQ $Name
            $subcmd = "az pipelines show --id $($azurePipeline.id) | ConvertFrom-Json"
            $azurePipelines = Invoke-Expression $subcmd
        } else {
            $azurePipelines = $azurePipelines | Where-Object Name -Match $Name
        }
        $azurePipelines | ForEach-Object { Write-Verbose " - '$($_.Path) - $($_.Name)'" }
        Write-Verbose "$TaskDescriptor - Filtered to $($azurePipelines.Count) Azure Pipeline(s)"
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
    return $azurePipelines
}