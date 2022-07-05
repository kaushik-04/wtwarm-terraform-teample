function Set-ADOProject {
    [CmdletBinding()]
    param (
        [string]
        $ProjectName
    )
    $TaskDescriptor = "Set default Azure DevOps configuration Project: '$ProjectName'"
    $cmd = "az devops configure --defaults project='$ProjectName'"
    try {
        Write-Verbose $TaskDescriptor
        Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }

    if (($null -eq $ProjectName) -or ("" -eq $ProjectName)){
        return $null
    }

    return Get-ADOProject
}