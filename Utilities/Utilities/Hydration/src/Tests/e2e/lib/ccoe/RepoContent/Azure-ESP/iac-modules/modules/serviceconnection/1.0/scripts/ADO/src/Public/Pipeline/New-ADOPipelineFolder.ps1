function New-ADOPipelineFolder {
    [CmdletBinding()]
    param (
        [string]
        $Path
    )
    $Path = $Path.Replace('/','\')
    if (-not $Path.StartsWith('\')) {
        $Path = "\$Path"
    }
    
    $TaskDescriptor = "Create Azure Pipeline Folder - $Path"
    $cmd = "az pipelines folder create --path '$Path' --detect false | ConvertFrom-Json"

    Write-Verbose "$TaskDescriptor - Checking if it already exists"
    $ADOPipelineFolder = Get-ADOPipelineFolder -Path $Path -Exact
    if ($ADOPipelineFolder) {
        Write-Verbose "$TaskDescriptor - Already exists"
        return $ADOPipelineFolder
    }
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