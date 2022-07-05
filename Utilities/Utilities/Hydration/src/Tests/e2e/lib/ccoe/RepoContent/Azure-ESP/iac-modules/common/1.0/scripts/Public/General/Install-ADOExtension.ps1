function Install-ADOExtension {
    [CmdletBinding()]
    param ()
    Write-Verbose "Installing Azure CLI extension devops"
    
    $TaskDescriptor = "Enable silent installation"
    $cmd = "az configure set extension.use_dynamic_install=yes_without_prompt"
    try {
        Write-Verbose $TaskDescriptor
        Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }

    $TaskDescriptor = "Add and upgrade AzureCLI extension, devops"
    $cmd = "az extension add --upgrade --name azure-devops"
    try {
        Write-Verbose "$TaskDescriptor"
        Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
}