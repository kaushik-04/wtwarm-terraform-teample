function Get-ADOPipelineFolder {
    [CmdletBinding()]
    param (
        [string]
        $Path,
        [switch]
        $Exact
    )
    $TaskDescriptor = 'Get and list all Azure Pipeline Folders'
    $cmd = 'az pipelines folder list | ConvertFrom-Json | Sort-Object Path'
    try {
        Write-Verbose $TaskDescriptor
        $ADOPipelineFolders = Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Totally found $($ADOPipelineFolders.Count) Azure Pipeline Folder(s)"
        if ($Path){
            if ($Exact) {
                $ADOPipelineFolders = $ADOPipelineFolders | Where-Object Path -EQ $Path
            } else {
                $ADOPipelineFolders = $ADOPipelineFolders | Where-Object Path -like "*$Path*"
            }
        }
        $ADOPipelineFolders | ForEach-Object { Write-Verbose " - '$($_.Path)'" }
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
    return $ADOPipelineFolders
}