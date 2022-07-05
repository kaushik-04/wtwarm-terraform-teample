[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $path
)

Describe "[Area] Azure DevOps Project Area Specs" {

    $HydrationDefinitionObj = ConvertFrom-Json (Get-Content -Path $path -Raw)
    $testCases = @()
    foreach ($projectObj in $HydrationDefinitionObj.projects) {
        $testCases += @{
            projectObj       = $projectObj
            organizationName = $HydrationDefinitionObj.organizationName
        }
    }

    It "Should have all expected areas in project [<organizationName>|<projectObj.projectname>]" -TestCases $testCases {

        param(
            [PSCustomObject] $projectObj,
            [string] $organizationName
        )

        $global:projectObj = $projectObj
        $global:organizationName = $organizationName

        InModuleScope 'Hydra' {

            $relationStringProperty = 'GEN_RelationString'

            if ($areas = $projectObj.areaPaths) {
                $flatLocalAreas = Resolve-ClassificationNodesFormatted -Nodes $areas -project $projectObj.projectName

                $inputParameters = @{
                    Organization = $organizationName
                    Project      = $projectObj.ProjectName
                }
                if ($remoteAreas = Get-ProjectAreaList @inputParameters) {
                    $flatRemoteAreas = Resolve-ClassificationNodesFormatted -Nodes $remoteAreas
                }
                else {
                    $flatRemoteAreas = @()
                }

                foreach ($expectedArea in $flatLocalAreas) {

                    $matchingRemote = $flatRemoteAreas | Where-Object { $_.Name -eq $expectedArea.Name -and $_.$relationStringProperty -eq $expectedArea.$relationStringProperty }

                    $matchingRemote | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}