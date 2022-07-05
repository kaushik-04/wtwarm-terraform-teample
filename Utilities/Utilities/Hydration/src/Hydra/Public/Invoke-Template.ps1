<#
    .SYNOPSIS
    Invokes the hydration given the definition file.
    Creates Azure DevOps resources based on a hydration definition file that matches a given schema.

    1. Run `Get-AzHydrationSchema` and create a definition file based on the given JSON schema you can find an example in [hydrationDefinition.json](../src/Tests/hydrationDefinition.json)
    2. Run `Test-AzHydrationTemplate` to validate the create definition template against the schema
    3. Run `Invoke-AzHydrationTemplate` to run the actual hydration
    4. Login to Azure DevOps
        1. The user is prompted to [login with a personal access token](https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows).
        1. This login can be avoided using the `-SkipLogin` parameter. Make sure to be logged in using `az login` before using the `-SkipLogin` option.

    .DESCRIPTION
    Invokes the hydration given the definition file.
    Creates Azure DevOps resources based on a hydration definition file that matches a given schema.

    1. Run `Get-AzHydrationSchema` and create a definition file based on the given JSON schema you can find an example in [hydrationDefinition.json](../src/Tests/hydrationDefinition.json)
    2. Run `Test-AzHydrationTemplate` to validate the create definition template against the schema
    3. Run `Invoke-AzHydrationTemplate` to run the actual hydration
    4. Login to Azure DevOps
        1. The user is prompted to [login with a personal access token](https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows).
        1. This login can be avoided using the `-SkipLogin` parameter. Make sure to be logged in using `az login` before using the `-SkipLogin` option.

    The `Invoke-AzHydrationTemplate` will create Azure DevOps resources based on a hydration defintion file that matches a given schema.
    The module uses the extension 'azure-devops' and installs it if misisng.

    .PARAMETER Path
    Path to the definition template file.
    The defintion tempalte file can be tested against a schema using `Test-AzHydrationTemplate`.
    The schema for the definition file can be generated using `Get-AzHydrationSchema`.

    .PARAMETER Force
    ATTENTION! Forces the replacement of exsiting resources.
    Make sure to validate the defintion file before applying it using `-Force`.
    Deletes exsisting resource before recreating the ones specified in the defintion file.
    Make sure to backup exsiting resources before applying them with force.

    .PARAMETER SkipLogin
    Skip the login and uses cached credentials.
    Make sure you run `az devops login` previous to running `Invoke-AzHydrationTempalte -SkipLogin`.
    Follow https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows to Sign in with a Personal Access Token

    .PARAMETER DryRun
    Simulate an end2end execution.

    .EXAMPLE
    Invoke-HydraTemplate -Path $path

    Extension 'azure-devops' is already installed.
    Token:
    TODO: input output of actual execution

    .EXAMPLE
    Invoke-HydraTemplate -Path $path -SkipLogin

    Extension 'azure-devops' is already installed.
    TODO: input output of actual execution

    .NOTES
    The `Hydra` PowerShell module is used to rehydrate a given Azure DevOps project.
    I uses a configuration based approach, similar to an ARM template.
    The module implements a ordered collection of Azure cli commands to achieve the rehydration.

    As the hydration is opinionated, we are execting a defined configuration file.
    The default configuration file can then be changed and adopted to customers needs - providing a flexible approach.

    TODO: #67790 A blueprint hydration template file is beeing provided as a reference to the module.
    A hydration template can also be created from scratch, given that it alignes to the schema (`Get-HydraSchema` and `Test-HydraTemplate).

    The configuration will be aligned to configure the resources outlined in the diagram displayed in the [Wiki ccoe-hydration-0.1](https://ADO-Hydration.visualstudio.com/Hydration/_wiki/wikis/Wiki/4888/Cloud-Center-of-Excellence?anchor=ccoe-hydration-0.1)

    To get started the user has to create a hydration template based on the schema using `Get-HydraSchema`.
    Next the template is tested against the schema using `Test-HydraTemplate`.
    Laslty, the configuration will be read by `Invoke-HydraTemplate` and executed using different functions to invoke the changes on Azure DevOps.


    .LINK
    https://docs.microsoft.com/en-us/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows
#>
function Invoke-Template {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [switch] $force = $false,

        [Parameter(Mandatory = $false)]
        [switch] $skipLogin,

        [Parameter(Mandatory = $false)]
        [switch] $removeExcessItems,

        [Parameter(Mandatory = $false)]
        [switch] $DryRun
    )

    # Verify JSON
    $definition = Get-VerifiedHydrationDefinition -ParameterFilePath $Path

    # DevOps Login
    if ($pscmdlet.ShouldProcess('CLI Login function', 'Execute')) {
        if ($skipLogin) {
            Connect-DevOps -skipLogin
        }
        else {
            Connect-DevOps
        }
    }
    else {
        Connect-DevOps -WhatIf
    }

    $HydrationProcessingStartTime = Get-Date

    Write-Verbose '######################################'
    Write-Verbose '#   DevOps Organization Processing   #'
    Write-Verbose '######################################'

    if ($definition.processes) {
        $syncProcessInputObject = @{
            Organization      = $definition.organizationName
            localProcesses    = $definition.processes
            removeExcessItems = $removeExcessItems
            DryRun            = $dryRun
        }
        if ($pscmdlet.ShouldProcess(('[{0}] DevOps Processes' -f $definition.processes.count), 'Create/Update/Remove')) {
            Sync-DevOpsOrgProcessList @syncProcessInputObject
        }
    }

    Write-Verbose '#################################'
    Write-Verbose '#   DevOps Project Processing   #'
    Write-Verbose '#################################'
    $ItemIndex = 1
    $definitonBase = Split-Path $Path -Parent

    foreach ($project in $definition.projects) {

        # Verify backlog data if provided
        $configuredBacklogData = [System.Collections.ArrayList]@()
        if ($project.backlogs.count -gt 0) {
            foreach ($backlogDefinition in $project.backlogs) {

                # Check if configured file actually exists
                $localBacklogDataPath = Join-Path $definitonBase $backlogDefinition.relativeBacklogFilePath
                if (-not (Test-Path -Path $localBacklogDataPath)) {
                    throw "Path [$localBacklogDataPath] does not exist. Make sure the backlog data file exists in the same folder as the definition file."
                }

                $localBacklogDataFileType = Split-Path $localBacklogDataPath -Extension
                switch ($localBacklogDataFileType) {
                    '.csv' { $localBacklogData = Import-BacklogCompatibleCSV $localBacklogDataPath }
                    '.xlsx' { $localBacklogData = Import-BacklogCompatibleXlsx $localBacklogDataPath }
                    Default {
                        throw "Board data file type [$localBacklogDataFileType] is not supported. Please use one of the following file types [csv|xslx]"
                    }
                }

                $null = $configuredBacklogData.AddRange($localBacklogData)
            }
        }

        Write-Verbose "###################################"
        Write-Verbose "#   Item $ItemIndex : Project Processing   #"
        Write-Verbose '###################################'
        # Create or update DevOps Project
        $syncProjectInputObject = @{
            Organization  = $definition.organizationName
            localProjects = @{
                name                 = $project.projectName
                description          = $project.description
                sourceControlType    = $project.sourceControl
                process              = $project.process
                visibility           = $project.visibility
                templateTypeId       = ($project.templateTypeId) ? $project.templateTypeId : $null
                relativeIconFilePath = $project.relativeIconFilePath
                IconPathAbsolute     = $project.IconPathAbsolute
            }
            DryRun        = $dryRun
            assetsPath    = Split-Path $Path -Parent
        }
        if ($pscmdlet.ShouldProcess(('Project [{0}]' -f $project.projectName), 'Create/Update')) {
            Sync-Project @syncProjectInputObject
            Start-Sleep 10
        }

        if ($project.areaPaths.count -gt 0) {
            Write-Verbose "######################################"
            Write-Verbose "#   Item $ItemIndex : Process Project Areas   #"
            Write-Verbose '######################################'
            # Create or update Devops Project Areas
            $syncProjectAreasInputObject = @{
                localAreaPaths    = $project.areaPaths
                Organization      = $definition.organizationName
                Project           = $project.projectName
                removeExcessItems = $removeExcessItems
                DryRun            = $dryRun
                Verbose           = $PSBoundParameters.ContainsKey('Verbose')
            }
            if ($pscmdlet.ShouldProcess(('[{0}] area paths from project [{1}]' -f $project.areaPaths.count, $project.projectName), 'Create, Update or Remove')) {
                Sync-ProjectAreaList @syncProjectAreasInputObject
            }
        }

        if ($project.iterationPaths.count -gt 0) {
            Write-Verbose "###########################################"
            Write-Verbose "#   Item $ItemIndex : Process Project Iterations   #"
            Write-Verbose '###########################################'
            $syncProjectIterationsInputObject = @{
                localIterations   = $project.iterationPaths
                Organization      = $definition.organizationName
                Project           = $project.projectName
                removeExcessItems = $removeExcessItems
                DryRun            = $dryRun
                Verbose           = $PSBoundParameters.ContainsKey('Verbose')
            }
            if ($pscmdlet.ShouldProcess(('[{0}] iteration paths from project [{1}]' -f $project.iterationPaths.count, $project.projectName), 'Create, Update or Remove')) {
                Sync-ProjectIterationList @syncProjectIterationsInputObject
            }
        }

        if ($project.teams.count -gt 0) {
            Write-Verbose "######################################"
            Write-Verbose "#   Item $ItemIndex : Process Project Teams   #"
            Write-Verbose '######################################'
            # Create or update Devops Project Teams
            $syncProjectTeamsInputObject = @{
                localTeams        = $project.teams
                Organization      = $definition.organizationName
                Project           = $project.projectName
                removeExcessItems = $removeExcessItems
                DryRun            = $dryRun
                Verbose           = $PSBoundParameters.ContainsKey('Verbose')
            }
            if ($pscmdlet.ShouldProcess(('[{0}] teams from project [{1}]' -f $project.teams.count, $project.projectName), 'Create, Update or Remove')) {
                Sync-ProjectTeamList @syncProjectTeamsInputObject
            }
        }

        if ($project.repositories.count -gt 0) {
            Write-Verbose '######################################'
            Write-Verbose "#   Item $ItemIndex : Process Project Repos   #"
            Write-Verbose '######################################'
            # Create or update Devops Project Repo
            $syncReposInputObject = @{
                localRepos        = $project.repositories
                ConfigurationRoot = $definitonBase
                Organization      = $definition.organizationName
                Project           = $project.projectName
                removeExcessItems = $removeExcessItems
                DryRun            = $dryRun
            }
            if ($pscmdlet.ShouldProcess(('[{0}] repositories from project [{1}]' -f $project.repositories.count, $project.projectName), 'Create or Remove')) {
                Sync-ProjectRepo @syncReposInputObject
            }
        }

        if ($configuredBacklogData.count -gt 0) {
            Write-Verbose "#########################################"
            Write-Verbose "#   Item $ItemIndex : Process Project Backlogs   #"
            Write-Verbose '#########################################'
            if ($configuredBacklogData.count -gt 0) {
                $inputParameters = @{
                    localBacklogData  = $configuredBacklogData
                    Organization      = $definition.organizationName
                    Project           = $project.projectName
                    removeExcessItems = $removeExcessItems
                    DryRun            = $DryRun
                    Verbose           = $PSBoundParameters.ContainsKey('Verbose')
                }
                if ($pscmdlet.ShouldProcess(('[{0}] work items from project [{1}]' -f $configuredBacklogData.Count, $project.projectName), 'Create, Update or Remove')) {
                    Sync-Backlog @inputParameters
                }
            }
        }
        $ItemIndex++
    }

    $elapsedTime = (get-date) - $HydrationProcessingStartTime
    $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
    Write-Verbose ("Hydration took [{0}]" -f $totalTime)
}