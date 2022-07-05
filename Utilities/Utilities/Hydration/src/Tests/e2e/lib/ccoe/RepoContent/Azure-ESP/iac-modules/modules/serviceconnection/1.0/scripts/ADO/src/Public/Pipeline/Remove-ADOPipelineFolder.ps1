function Remove-ADOPipelineFolder {
    [CmdletBinding()]
    param (
        [string]
        $Path,
        [switch]
        $Force
    )
    $Path = $Path.Replace('/','\')
    if (-not $Path.StartsWith('\')) {
        $Path = "\$Path"
    }
    
    $TaskDescriptor = "Remove Azure Pipeline Folder - $Path"
    $Found = Get-ADOPipelineFolder -Path $Path -Exact
    if (-not $Found) {
        Write-Verbose "$TaskDescriptor - Path not found"
        return $null
    }
    $Pipelines = Get-ADOPipeline -Path $Path
    if ($Pipelines.count -gt 0) {
        if($Force) {
            Write-Verbose "$TaskDescriptor - Folder is not empty, but force delete is enabled"
        } else {
            Write-Verbose "$TaskDescriptor - Folder is not empty. Exiting. Specify -Force to delete folder regardless"
            return $null
        }
    }
    $cmd = "az pipelines folder delete --path '$Path' --yes --detect false | ConvertFrom-Json"
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