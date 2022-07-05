function Set-EnableLogAccessUsingOnlyResourcePermissions {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ParametersFilePath
    )

    Write-Output "Get Log Analytics Workspace from Parameter file $parametersFilePath"
    $params = Get-Content -Raw -Path $ParametersFilePath | ConvertFrom-Json
    $WSName = $params.parameters.logAnalyticsWorkspaceName.value
    $enableLogAccessUsingOnlyResourcePermissions = $params.parameters.enableLogAccessUsingOnlyResourcePermissions.value
    $Workspace = Get-AzResource -Name $WSName -ExpandProperties

    if ($workspace) {
        Write-Output "Resource $($workspace.name) found." 
        Write-Output "Getting feature enableLogAccessUsingOnlyResourcePermissions for Log Analytics Workspace"
        if ($Workspace.Properties.features.enableLogAccessUsingOnlyResourcePermissions -eq $null) { 
            $Workspace.Properties.feature | Add-Member enableLogAccessUsingOnlyResourcePermissions $enableLogAccessUsingOnlyResourcePermissions -Force 
        }
        else {
            $Workspace.Properties.features.enableLogAccessUsingOnlyResourcePermissions = $enableLogAccessUsingOnlyResourcePermissions
        }
    
        Write-Output "Setting feature enableLogAccessUsingOnlyResourcePermissions for Log Analytics Workspace"
        Set-AzResource -ResourceId $Workspace.ResourceId -Properties $Workspace.Properties -Force
        $Result = Get-AzResource -Name $WSName -ExpandProperties
        $Result.Properties.features | select-object enableLogAccessUsingOnlyResourcePermissions
    }
    else {
        Write-Warning "Resource $WSName doesn't exists"
    }
}
