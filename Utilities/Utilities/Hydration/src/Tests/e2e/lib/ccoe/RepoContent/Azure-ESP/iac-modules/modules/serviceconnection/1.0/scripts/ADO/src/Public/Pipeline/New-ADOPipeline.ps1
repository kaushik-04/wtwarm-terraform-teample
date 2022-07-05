function New-ADOPipeline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $PipelineName,
        [Parameter(Mandatory)]
        [string]
        $RepositoryName,
        [string]
        $BranchName = 'master',
        [Parameter(Mandatory)]
        [string]
        $PipelineTargetPath,
        [Parameter(Mandatory)]
        [string]
        $PipelineFilePath
    )

    $TaskDescriptor = "Create Azure Pipeline from YML file - $PipelineFilePath"
    $cmd = "az pipelines create --repository '$RepositoryName' --repository-type 'tfsgit' --branch '$BranchName' --folder-path '$PipelineTargetPath' --name '$PipelineName' --yml-path '$PipelineFilePath' --skip-run --detect false | ConvertFrom-Json"
  try {
        Write-Verbose $TaskDescriptor
        $ADOPipeline = Invoke-Expression $cmd
        Write-Verbose "$TaskDescriptor - Ok"
    } catch {
        Write-Verbose "$TaskDescriptor - Failed"
        throw $_
    }
    return $ADOPipeline
}