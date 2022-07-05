<#
.SYNOPSIS
Creates a new Azure DevOps Project

.DESCRIPTION
Creates a new Azure DevOps Project

.PARAMETER Organization
Mandatory. Organization Name. E.g. 'contoso'

.PARAMETER projectsToCreate
Mandatory. The projects to create. Each object must at least contain a name.

.PARAMETER DryRun
Simulate and end2end execution

.EXAMPLE
New-Project -Organization Contoso -Project ADO-project -projectsToCreate @(@{ Name = 'Module Playground'; Descripton = 'Module Playground Description' })

Create new project 'Module Playground' using description 'Module Playground Description'
#>
function New-Project {

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Organization,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $projectsToCreate,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    if ($DryRun) {
        $dryRunActions = [System.Collections.ArrayList]@()
    }

    foreach ($project in $projectsToCreate) {

        if ($DryRun) {
            $dryAction = @{
                Op                = '+'
                name              = $project.Name
                SourceControlType = $project.SourceControlType
                TemplateTypeId    = $project.TemplateTypeId
            }

            if (-not ([String]::IsNullOrEmpty($project.Description))) {
                $dryAction['Description'] = $project.'Description'
            }
            if (-not ([String]::IsNullOrEmpty($project.Visibility))) {
                $dryAction['Visibility'] = $project.Visibility
            }
            $null = $dryRunActions.Add($dryAction)
        }
        else {
            $body = @{ name = $project.Name }
            if (-not [String]::IsNullOrEmpty($project.Description)) { $body['description'] = $project.Description }
            $body['capabilities'] = @{
                versioncontrol  = @{
                    sourceControlType = $project.SourceControlType
                }
                processTemplate = @{
                    templateTypeId = $project.TemplateTypeId
                }
            }
            if (-not [String]::IsNullOrEmpty($project.visibility)) { $body['visibility'] = $project.visibility }

            $restInfo = Get-RelativeConfigData -configToken 'RESTProjectCreate'
            $restInputObject = @{
                method = $restInfo.method
                uri    = '"{0}"' -f ($restInfo.uri -f [uri]::EscapeDataString($Organization), [uri]::EscapeDataString($Project))
                body   = ConvertTo-Json $body -Depth 10 -Compress
            }

            if ($PSCmdlet.ShouldProcess(('REST command to create project [{0}]' -f $project.Name), "Invoke")) {
                $createCommandResponse = Invoke-RESTCommand @restInputObject
                if (-not [String]::IsNullOrEmpty($createCommandResponse.errorCode)) {
                    Write-Error ('Failed to create project [{0}] because of [{1} - {2}]' -f $project.Name, $createCommandResponse.typeKey, $createCommandResponse.message)
                    return
                }
                else {
                    Write-Verbose ("[+] Successfully created project [{0}]" -f $project.name)

                    # Set ID for further processing
                    if (($project | Get-Member -MemberType "NoteProperty").Name -notcontains 'id') {
                        $project | Add-Member -NotePropertyName 'id' -NotePropertyValue ''
                    }
                    $project.id = $createCommandResponse.id
                }
            }
        }
    }

    if ($dryRunActions.count -gt 0) {
        $dryRunString = "`n`nWould create projects:"
        $dryRunString += "`n======================"

        $columns = @('#', 'Op', 'Id') + ($dryRunActions.Keys | Select-Object -Unique | Where-Object { $_ -notin ('Op', 'Id') })
        $dryRunActionsCount = 1
        $dryRunString += ($dryRunActions | Sort-Object -Property @(@{ Expression = 'type' }) | ForEach-Object {
                $_ | Select-Object @{Name = '#'; Expression = { $dryRunActionsCount } }, *
                $dryRunActionsCount++
            } | Format-Table $columns -AutoSize | Out-String)
        Write-Verbose $dryRunString -Verbose
    }
}