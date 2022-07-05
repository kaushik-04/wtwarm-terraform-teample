# Install Azure PowerShell Module Versions for Self Hosted Agent
param(
    [string]$MinimumVersion
)

$modules = Find-Module -Name Az -AllVersions |
    Where-Object {[version]($_.Version)-ge [version]($MinimumVersion)}

foreach ($module in $modules) {
    $installedPath = Join-Path -Path '/usr/share' -ChildPath "az_$($module.Version)"

    Save-Module -Name Az -LiteralPath $installedPath -RequiredVersion $module.Version -Force
}
