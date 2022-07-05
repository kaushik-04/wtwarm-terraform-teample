<#
.SYNOPSIS
Updates Azure DevOps Project

.DESCRIPTION
Updates Azure DevOps Project

.PARAMETER Organization
Azure DevOps Organization Name

.PARAMETER projectsToUpdate
Mandatory. The projects to update. The id can either be the name or id of the project.

.EXAMPLE
Set-Project -Organization Contoso -projectsToUpdate @( @{ id = '11111111-2222-3333-4444-555555555555'; name = 'newName'; description = 'desc' })

Update the name of the given project with id '11111111-2222-3333-4444-555555555555' to 'newName' and the description to 'desc'
#>
function Set-Project {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $projectsToUpdate,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($project in $projectsToUpdate) {

        if ($DryRun) {
            $dryAction = @{
                Op   = '^'
                id   = $project.id
                name = $project.name
            }

            if (-not ([String]::IsNullOrEmpty($project.Name)) -and -not ([String]::IsNullOrEmpty($project.'Old Name')) -and ($project.'Old Name') -ne $project.name) {
                $dryAction['Name'] = "[{0} => {1}]" -f (($project.'Old Name') ? $project.'Old Name' : '()'), $project.Name
            }
            if (-not ([String]::IsNullOrEmpty($project.Description))) {
                $dryAction['Description'] = "[{0} => {1}]" -f (($project.'Old Description') ? $project.'Old Description' : '()'), $project.Description
            }
            if (-not ([String]::IsNullOrEmpty($project.SourceControlType))) {
                $dryAction['SourceControlType'] = "[{0} => {1}]" -f (($project.'Old SourceControlType') ? $project.'Old SourceControlType' : '()'), $project.SourceControlType
            }
            if (-not ([String]::IsNullOrEmpty($project.TemplateTypeId))) {
                $dryAction['TemplateTypeId'] = "[{0} => {1}]" -f (($project.'Old TemplateTypeId') ? $project.'Old TemplateTypeId' : '()'), $project.TemplateTypeId
            }
            if (-not ([String]::IsNullOrEmpty($project.Visibility))) {
                $dryAction['Visibility'] = "[{0} => {1}]" -f (($project.'Old Visibility') ? $project.'Old Visibility' : '()'), $project.Visibility
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $body = @{ id = $project.id }
            if (-not [String]::IsNullOrEmpty($project.Name) -and ($project.'Old Name') -ne $project.name) { $body['Name'] = $project.Name }
            if (-not [String]::IsNullOrEmpty($project.Description)) { $body['Description'] = $project.Description }
            if (-not [String]::IsNullOrEmpty($project.Visibility)) { $body['visibility'] = $project.Visibility }
            if ((-not [String]::IsNullOrEmpty($project.SourceControlType)) -or (-not [String]::IsNullOrEmpty($project.TemplateTypeId))) {
                $body['capabilities'] = @{}

                if ((-not [String]::IsNullOrEmpty($project.SourceControlType))) {
                    $body.capabilities['versioncontrol'] = @{
                        'sourceControlType' = $project.SourceControlType
                    }
                }

                if ((-not [String]::IsNullOrEmpty($project.TemplateTypeId))) {
                    $body.capabilities['processTemplate'] = @{
                        'templateTypeId' = $project.TemplateTypeId
                    }
                }
            }

            $restInfo = Get-RelativeConfigData -configToken 'RESTProjectUpdate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), $project.id)
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to update project [{0}]' -f $project.Name), "Invoke")) {
                $updateCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($updateCommandResponse.errorCode)) {
                    Write-Error ('Failed to update project [{0}] because of [{1} - {2}]. Make sure the project does exist.' -f $project.name, $updateCommandResponse.typeKey, $updateCommandResponse.message)
                }
                else {
                    Write-Verbose ("[^] Successfully updated project [{0}]" -f $project.Name)
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould update projects to:"
        $dryRunString += "`n======================"

        $columns = @('#', 'Op', 'Name') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Name') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}