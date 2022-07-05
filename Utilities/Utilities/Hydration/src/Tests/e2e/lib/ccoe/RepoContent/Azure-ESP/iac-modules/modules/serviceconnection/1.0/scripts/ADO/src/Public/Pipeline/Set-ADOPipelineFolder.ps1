function Set-ADOPipelineFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Path,
        [ValidateNotNullOrEmpty()]
        [string]
        $NewPath,
        [ValidateNotNullOrEmpty()]
        [string]
        $NewName
    )
    $Path = $Path.Replace('/', '\')
    if (-not $Path.StartsWith('\')) {
        $Path = "\$Path"
    }
    $TaskDescriptor = "Update Azure Pipeline Folder - $Path"
    $ADOPipelineFolder = Get-ADOPipelineFolder -Path $Path -Exact
    if (-not $ADOPipelineFolder) {
        Write-Verbose "$TaskDescriptor - Path not found"
        return $null
    }

    if ($NewPath) {
        # Format path to be '\folder\subfolder'
        $NewPath = $NewPath.Replace('/', '\')
        if ($NewPath.EndsWith('\')) {
            $NewPath = $NewPath.TrimEnd('\')
        }
        if (-not $NewPath.StartsWith('\')) {
            $NewPath = "\$NewPath"
        }
        $NewPath = $NewPath
        
        Write-Verbose "$TaskDescriptor - New path is: '$NewPath'"
    } else {
        $NewPath = (($ADOPipelineFolder.Path).Split('\') | Select-Object -SkipLast 1) -join "\"
        Write-Verbose "$TaskDescriptor - Only renaming, not moving"
    }

    if ($NewName) {
        $NewName = $NewName.Replace('/', '\')
        if ($NewName.EndsWith('\')) {
            $NewName = $NewName.TrimEnd('\')
        }
        if (-not $NewName.StartsWith('\')) {
            $NewName = "\$NewName"
        }
        Write-Verbose "$TaskDescriptor - New name is: '$NewName'"
    } else {
        $NewName = $ADOPipelineFolder.Path
        Write-Verbose "$TaskDescriptor - Only moving, not renaming"
    }
    $NewFullPath = "$NewPath\$NewName".Replace('\\','\')
    Write-Verbose "$TaskDescriptor - New full path is: '$NewFullPath'"
    $cmd = "az pipelines folder update --path '$Path' --new-path '$NewFullPath' --detect false | ConvertFrom-Json"
    try {
        Write-Verbose $TaskDescriptor
        $ADOPipelineFolder = Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
    return $ADOPipelineFolder
}