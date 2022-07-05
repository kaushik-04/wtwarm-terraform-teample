[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $path
)

Describe "[Repo] Azure DevOps Project Repo Specs" -Tag Acceptance {

    $HydrationDefinitionObj = ConvertFrom-Json (Get-Content -Path $path -Raw)
    $testCases = @()
    foreach ($projectObj in $HydrationDefinitionObj.projects) {
        $testCases += @{
            HydrationDefinitionPath = Split-Path $path -Parent
            projectObj              = $projectObj
            organizationName        = $HydrationDefinitionObj.organizationName
        }
    }

    It "Should have all expected Repos in project [<organizationName>|<projectObj.projectname>]" -TestCases $testCases {

        param(
            [PSCustomObject] $projectObj,
            [string] $organizationName
        )

        $global:projectObj = $projectObj
        $global:organizationName = $organizationName

        InModuleScope 'Hydra' {

            if ($expectedRepos = $projectObj.repositories) {
                $inputParameters = @{
                    Organization = $organizationName
                    Project      = $projectObj.ProjectName
                }
                $remoteReposObj = Get-RepoList @inputParameters

                foreach ($expectedRepo in $expectedRepos) {
                    $matchingRemote = $remoteReposObj | Where-Object {
                        $_.Name -eq $expectedRepo.Name
                    }
                    $matchingRemote | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    It "Files of all repos should be hydrated as expected in project [<organizationName>|<projectObj.projectname>]" -TestCases $testCases {

        param(
            [string] $HydrationDefinitionPath,
            [PSCustomObject] $projectObj,
            [string] $organizationName
        )

        $global:projectObj = $projectObj
        $global:organizationName = $organizationName
        $global:HydrationDefinitionPath = $HydrationDefinitionPath

        InModuleScope 'Hydra' {

            if ($localRepos = $projectObj.repositories) {
                $inputParameters = @{
                    Organization = $organizationName
                    Project      = $projectObj.ProjectName
                }
                $remoteRepos = Get-RepoList @inputParameters # used by test

                $remoteRepos.Count | Should -Be $localRepos.Count

                if ([String]::IsNullOrEmpty($env:AZURE_DEVOPS_EXT_PAT)) {
                    Write-Verbose "Generating DevOps PAT" -Verbose
                    $pat = (New-DevOpsPAT -organization $organizationName).token
                }
                else {
                    Write-Verbose "Leveraging provided DevOps PAT" -Verbose
                    $pat = $env:AZURE_DEVOPS_EXT_PAT
                }

                foreach ($localRepo in $localRepos) {

                    # Check if remote repo with expected name exists
                    $matchingRemote = $remoteRepos | Where-Object {
                        ($_.Name -eq $localRepo.Name)
                    }
                    $matchingRemote | Should -Not -BeNullOrEmpty

                    try {
                        $url = (Get-RelativeConfigData -configToken 'DEVOPS_GIT_URL') -f ($pat, [uri]::EscapeDataString($organizationName), [uri]::EscapeDataString($projectObj.ProjectName), [uri]::EscapeDataString($localRepo.name))
                        $temp = [System.IO.Path]::GetTempPath()
                        $tempFolder = (Get-Random).ToString()
                        $tempPath = Join-Path $temp $tempFolder

                        $path = Join-Path $tempPath $localRepo.name
                        if (test-path $path) { remove-item -literalpath $path -Force -Recurse }
                        $dest = New-Item -path $path -ItemType "directory"
                        Write-Verbose ("Folder created: {0}" -f $dest.FullName)

                        [string]$localFilesDir = Join-Path $HydrationDefinitionPath $localRepo.relativePath
                        [string]$remoteFilesDir = $dest.FullName

                        #Clone the remote repo
                        git clone $url $remoteFilesDir

                        #Compare content from local and remote repo
                        if ((Test-Path -Path $remoteFilesDir) -and (Test-Path -Path $localFilesDir)) {
                            write-Verbose "Both folders exist"
                        }

                        $localFiles = Get-ChildItem $localFilesDir -Recurse -File
                        $remoteFiles = Get-ChildItem $remoteFilesDir -Recurse -File

                        foreach ($localFile in $localFiles) {
                            # Test file existence
                            $matchingRemote = $remoteFiles | Where-Object {
                                $localFile.FullName.Replace($HydrationDefinitionPath, '').Replace('/','\').TrimStart('\') -eq (Join-Path $localRepo.relativePath $_.FullName.Replace($remoteFilesDir, '')).Replace('/','\')
                            }
                            $matchingRemote | Should -Not -BeNullOrEmpty -Because ('the local file [{0}] must have a remote counterpart in collection [{1}]' -f $localFile.FullName.Replace($HydrationDefinitionPath, '').TrimStart('\'), ($remoteFiles | Foreach-Object { Join-Path $localRepo.relativePath $_.FullName.Replace($remoteFilesDir, '')}))

                            # Test file content
                            (Get-FileHash $localFile).Hash | Should -Be (Get-FileHash $matchingRemote).Hash -Because ('the hashes of local defined file and remote hydrated file {0} should be the same if they have the same content' -f $localFile.Name)
                        }
                    }
                    catch {
                        throw $_
                    }
                    finally {
                        # Remove temp files
                        if ((-not [String]::IsNullOrEmpty($tempPath)) -and (Test-Path $tempPath)) {
                            Remove-item -literalpath $tempPath -Force -Recurse
                        }
                    }
                }
                ###

                foreach ($localRepo in $localRepos) {
                    $matching = $localRepo | Where-Object { (test-path (join-path $HydrationDefinitionPath $localRepo.relativePath)) -and ((Get-ChildItem -Path (join-path $HydrationDefinitionPath $localRepo.relativePath) -Recurse | Measure-Object).Count -gt 0) }
                    $matching | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}