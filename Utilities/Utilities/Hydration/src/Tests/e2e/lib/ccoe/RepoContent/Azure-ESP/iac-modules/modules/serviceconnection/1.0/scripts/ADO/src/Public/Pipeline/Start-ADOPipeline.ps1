function Start-ADOPipeline {
    [CmdletBinding(DefaultParameterSetName = 'ID')]
    param (
        [Parameter(ParameterSetName = 'ID')]
        [string]
        $PipelineID,
        [Parameter(Mandatory,ParameterSetName = 'Name')]
        [string]
        $PipelineName,
        [string]
        $BranchName = 'master',
        [Parameter(Mandatory)]
        [string]
        $PipelineFolderPath
    )

    $TaskDescriptor = "Run Azure Pipeline - $PipelineFilePath"
    if ($PipelineID) {
        $cmd = "az pipelines run --branch '$BranchName' --folder-path '$PipelineFolderPath' --id '$PipelineID' --detect false | ConvertFrom-Json"
    } elseif ($PipelineName) {
        $cmd = "az pipelines run --branch '$BranchName' --folder-path '$PipelineFolderPath' --name '$PipelineName' --detect false | ConvertFrom-Json"
    }
    
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