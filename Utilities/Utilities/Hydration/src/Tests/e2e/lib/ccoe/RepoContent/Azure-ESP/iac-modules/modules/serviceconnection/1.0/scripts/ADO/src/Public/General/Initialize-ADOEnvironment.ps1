function Initialize-ADOEnvironment {
    [Cmdletbinding()]
    param(
        [version]
        $MinimumAzureCLIVersion = '2.13.0',
        [version]
        $MinimumAzureCLIADOVerison = '0.18.0'
    )

    $TestDescriptor = "Verifying environment for running ADO-Automation"
    Write-Verbose $TestDescriptor
    Write-Verbose "$TestDescriptor - Check that Azure CLI is installed"
    $CLIIsInstalled = Assert-AzureCLI
    if (-not $CLIIsInstalled) {
        throw "Azure CLI is not installed."
    }
    
    Write-Verbose "$TestDescriptor - Check that required Azure CLI version is installed ($MinimumAzureCLIVersion)"
    $MinimumAzureCLIVersionIsInstalled = Assert-AzureCLIVersion -MinimumVersion $MinimumAzureCLIVersion
    if (-not $MinimumAzureCLIVersionIsInstalled) {
        Update-AzureCLI
        Write-Verbose "$TestDescriptor - Verifying that required Azure CLI version is installed ($MinimumAzureCLIVersion)"
        $MinimumAzureCLIVersionIsInstalled = Assert-AzureCLIVersion -MinimumVersion $MinimumAzureCLIVersion
        if (-not $MinimumAzureCLIVersionIsInstalled) {
            throw "Not running required version of the Azure CLI"
        }
    }

    Write-Verbose "$TestDescriptor - Check that Azure CLI DevOps extension is installed"
    $DevOpsIsInstalled = Assert-ADOExtension
    if (-not $DevOpsIsInstalled) {
        Install-ADOExtension
        Write-Verbose "$TestDescriptor - Verifying required Azure CLI DevOps extension version is installed ($MinimumAzureCLIVersion)"
        $MinimumAzureCLIADOVerisonIsInstalled = Assert-ADOExtensionVersion -MinimumVersion $MinimumAzureCLIADOVerison
        if (-not $MinimumAzureCLIADOVerisonIsInstalled) {
            Install-ADOExtension
        }
    }

    $MinimumAzureCLIADOVerisonIsInstalled = Assert-ADOExtensionVersion -MinimumVersion $MinimumAzureCLIADOVerison
    if (-not $MinimumAzureCLIADOVerisonIsInstalled) {
        throw "Not running required version of the Azure CLI DevOps extension"
    }
}