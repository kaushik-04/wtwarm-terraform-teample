[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $path
)

Describe "[Iteration] Azure DevOps Project Iteration Specs" {

    $HydrationDefinitionObj = ConvertFrom-Json (Get-Content -Path $path -Raw)
    $testCases = @()
    foreach ($projectObj in $HydrationDefinitionObj.projects) {
        $testCases += @{
            projectObj       = $projectObj
            organizationName = $HydrationDefinitionObj.organizationName
        }
    }

    It "Should have all expected iterations in project [<organizationName>|<projectObj.projectname>]" -TestCases $testCases {

        param(
            [PSCustomObject] $projectObj,
            [string] $organizationName
        )

        $global:projectObj = $projectObj
        $global:organizationName = $organizationName

        InModuleScope 'Hydra' {

            $relationStringProperty = 'GEN_RelationString'
            if ($localIterations = $projectObj.iterationPaths) {
                $flatLocalIterations = Resolve-ClassificationNodesFormatted -Nodes $localIterations -project $projectObj.projectName

                $inputParameters = @{
                    Organization = $organizationName
                    Project      = $projectObj.ProjectName
                }
                if ($remoteIterations = Get-ProjectIterationList @inputParameters) {
                    $flatRemoteIterations = Resolve-ClassificationNodesFormatted -Nodes $remoteIterations
                }
                else {
                    $flatRemoteIterations = @()
                }

                foreach ($flatLocalIteration in $flatLocalIterations) {
                    $matchingRemote = $flatRemoteIterations | Where-Object {
                        $_.Name -eq $flatLocalIteration.Name -and
                        $_.$relationStringProperty -eq $flatLocalIteration.$relationStringProperty -and
                        ([String]::IsNullOrEmpty($flatLocalIteration.attributes.startDate) -or (-not [String]::IsNullOrEmpty($flatLocalIteration.attributes.startDate) -and [String]::IsNullOrEmpty($_.attributes.startDate)) -or ([DateTime]$flatLocalIteration.attributes.startDate).ToString('yyyy-MM-dd') -eq ([DateTime]$_.attributes.startDate).ToString('yyyy-MM-dd')) -and
                        ([String]::IsNullOrEmpty($flatLocalIteration.attributes.finishDate) -or (-not [String]::IsNullOrEmpty($flatLocalIteration.attributes.finishDate) -and [String]::IsNullOrEmpty($_.attributes.finishDate)) -or ([DateTime]$flatLocalIteration.attributes.finishDate).ToString('yyyy-MM-dd') -eq ([DateTime]$_.attributes.finishDate).ToString('yyyy-MM-dd'))
                    }
                    $matchingRemote | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}