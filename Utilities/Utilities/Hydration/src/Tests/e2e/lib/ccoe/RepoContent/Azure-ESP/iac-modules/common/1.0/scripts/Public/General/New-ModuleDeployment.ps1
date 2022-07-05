<#
.SYNOPSIS
Run a template deployment using a given parameter file

.DESCRIPTION
Run a template deployment using a given parameter file.
Works on a resource group, subscription, managementgroup and tenant level

.PARAMETER moduleName
Mandatory. The name of the module to deploy

.PARAMETER componentsBasePath
Mandatory. The path to the component/module root

.PARAMETER parametersBasePath
Mandatory. The path to the root of the parameters folder to test with

.PARAMETER modulePath
Mandatory. Path to the module from root.

.PARAMETER parameterFilePath
Mandatory. Path to the parameter file from root.

.PARAMETER location
Mandatory. Location to test in. E.g. WestEurope

.PARAMETER resourceGroupName
Optional. Name of the resource group to deploy into. Mandatory if deploying into a resource group (resource group level) 

.PARAMETER subscriptionName
Optional. Only used for subscription-level deployments.
The name of the subscription to deploy into. If left blank the current context is used.
If deploying with a management group level service connection, this allows setting the context.

.PARAMETER managementGroupId
Optional. Name of the management group to deploy into. Mandatory if deploying into a management group (management group level) 

.PARAMETER removeDeployment
Optional. Set to 'true' to add the tag 'RemoveModule = <ModuleName>' to the deployment. Is picked up by the removal stage to remove the resource again.

.PARAMETER Retry
Number of retries that the deployment will do, in case of failure.

.PARAMETER RetryInterval
Number of seconds between retries.

.EXAMPLE
New-ModuleDeployment -ModuleName 'KeyVault' -componentsBasePath '$(System.DefaultWorkingDirectory)' -parametersBasePath "$(Build.Repository.LocalPath)" -modulePath 'Modules/ARM/KeyVault' -parameterFilePath 'Modules/ARM/KeyVault/Parameters/parameters.json' -location 'WestEurope' -resourceGroupName 'aLegendaryRg'

Deploy the deploy.json of the KeyVault module with the parameter file 'parameters.json' using the resource group 'aLegendaryRg' in location 'WestEurope'

.EXAMPLE
New-ModuleDeployment -ModuleName 'KeyVault' -componentsBasePath '$(System.DefaultWorkingDirectory)' -parametersBasePath "$(Build.Repository.LocalPath)" -modulePath 'Modules/ARM/ResourceGroup' -parameterFilePath 'Modules/ARM/ResourceGroup/Parameters/parameters.json' -location 'WestEurope'

Deploy the deploy.json of the ResourceGroup module with the parameter file 'parameters.json' in location 'WestEurope'
#>
function New-ModuleDeployment {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string] $moduleName,

        [Parameter(Mandatory)]
        [string] $componentsBasePath,

        [Parameter(Mandatory)]
        [string] $parametersBasePath,

        [Parameter(Mandatory)]
        [string] $modulePath,

        [Parameter(Mandatory)]
        [string] $parameterFilePath,

        [Parameter(Mandatory)]
        [string] $location,

        [Parameter(Mandatory = $false)]
        [string] $resourceGroupName,

        [Parameter(Mandatory = $false)]       
        [string] $subscriptionName,

        [Parameter(Mandatory = $false)]       
        [string] $managementGroupId,

        [Parameter(Mandatory = $false)]       
        [bool] $removeDeployment,

        [Parameter(Mandatory = $false)]       
        [int] $Retry = 5,

        [Parameter(Mandatory = $false)]       
        [int] $RetryInterval = 20

    )
    
    begin {
        Write-Debug ("{0} entered" -f $MyInvocation.MyCommand) 
    }
    
    process {

        # Getting parameters full file path
        $parameterFilePath = Join-Path $parametersBasePath $parameterFilePath

        if (Test-Path -Path "$componentsBasePath/$modulePath/pre-deploy.ps1") {
            $scriptFilePath = "$componentsBasePath/$modulePath/pre-deploy.ps1"
            Write-Output "Deploying pre configuration from $scriptFilePath"

            if (-not (Test-Path -Path $parameterFilePath)) {
                Throw "New-ModuleDeployment - Path '$parameterFilePath' not found"
            }
            for ($i = 1; $i -le $Retry; $i++) {
                try {
                    Write-Output "Pre-deploy - Attempt #$i"
                    Invoke-Expression -Command "$scriptFilePath -ParametersFilePath $parameterFilePath"
                }
                catch {
                    if ($i -ne $Retry) {
                        $_
                        Write-Output "Pre-deploy - Attempt #$i - Failed, retry in $RetryInterval seconds"
                        Start-Sleep -Seconds $RetryInterval
                        continue
                    }
                    else {
                        Write-Output "Pre-deploy - Attempt #$i - Failed. Throwing error."
                        throw $_
                    }
                }
                break
            }
        }
        if (Test-Path -Path "$componentsBasePath/$modulePath/deploy.ps1") {

            $scriptFilePath = "$componentsBasePath/$modulePath/deploy.ps1"
            Write-Output "Deploying configuration from $scriptFilePath"

            if (-not (Test-Path -Path $parameterFilePath)) {
                Throw "New-ModuleDeployment - Path '$parameterFilePath' not found"
            }
            for ($i = 1; $i -le $Retry; $i++) {
                try {
                    Write-Output "Deploy - Attempt #$i"
                    Invoke-Expression -Command "$scriptFilePath -ParametersFilePath $parameterFilePath"
                }
                catch {
                    if ($i -ne $Retry) {
                        $_
                        Write-Output "Deploy - Attempt #$i - Failed, retry in $RetryInterval seconds"
                        Start-Sleep -Seconds $RetryInterval
                        continue
                    }
                    else {
                        Write-Output "Deploy - Attempt #$i - Failed. Throwing error."
                        throw $_
                    }
                }
                break
            }
        }
        elseif (Test-Path -Path "$componentsBasePath/$modulePath/deploy.json") {

            $templateFilePath = "$componentsBasePath/$modulePath/deploy.json"
            Write-Output "Deploying configuration from $scriptFilePath"

            Write-Verbose "Got path: $templateFilePath"
            $DeploymentInputs = @{
                Name                  = "$moduleName-$(-join (Get-Date -Format yyyyMMddTHHMMssffffZ)[0..63])"
                TemplateFile          = $templateFilePath
                TemplateParameterFile = $parameterFilePath
                Verbose               = $true
                ErrorAction           = 'Stop'
            }

            if ($removeDeployment) {
                # Fetch tags of parameter file if any (- required for the remove process. Tags may need to be compliant with potential customer requirements)
                $parameterFileTags = (ConvertFrom-Json (Get-Content -Raw -Path $parameterFilePath) -AsHashtable).parameters.tags.value
                if (-not $parameterFileTags) {
                    $parameterFileTags = @{}
                }
                $parameterFileTags['RemoveModule'] = $moduleName
            }

            #######################
            ## INVOKE DEPLOYMENT ##
            #######################
            $deploymentSchema = (ConvertFrom-Json (Get-Content -Raw -Path $templateFilePath)).'$schema'
            switch -regex ($deploymentSchema) {
                '\/deploymentTemplate.json#$' {
                    if (-not (Get-AzResourceGroup -Name $resourceGroupName -ErrorAction 'SilentlyContinue')) {
                        if ($PSCmdlet.ShouldProcess("Resource group [$resourceGroupName] in location [$location]", "Create")) {
                            New-AzResourceGroup -Name $resourceGroupName -Location $location
                        }
                    }
                    if ($removeDeployment) {
                        Write-Verbose "Because the subsequent removal is enabled after the Module $moduleName has been deployed, the following tags (RemoveModule: $moduleName) are now set on the resource."
                        Write-Verbose "This is necessary so that the later running Removal Stage can remove the corresponding Module from the Resource Group again."
                        # Overwrites parameter file tags parameter  
                        $DeploymentInputs += @{ 
                            Tags = $parameterFileTags
                        }
                    }
                    if ($PSCmdlet.ShouldProcess("Resource group level deployment", "Create")) {
                        New-AzResourceGroupDeployment @DeploymentInputs -ResourceGroupName $resourceGroupName
                    }
                    break
                }
                '\/subscriptionDeploymentTemplate.json#$' {
                    if ($removeDeployment) {
                        Write-Verbose "Because the subsequent removal is enabled after the Module $moduleName has been deployed, the following tags (RemoveModule: $moduleName) are now set on the resource."
                        Write-Verbose "This is necessary so that the later running Removal Stage can remove the corresponding Module from the Resource Group again."
                        # Overwrites parameter file tags parameter  
                        $DeploymentInputs += @{ 
                            Tags = $parameterFileTags
                        }
                    }
                    if ($PSCmdlet.ShouldProcess("Subscription level deployment", "Create")) {
                        if ($subscriptionName) {
                            $Context = Get-AzContext -ListAvailable | Where-Object Name -match $subscriptionName
                            if ($Context) {
                                $Context | Set-AzContext
                            }
                        }
                        New-AzSubscriptionDeployment @DeploymentInputs -location $location
                    }
                    break
                }
                '\/managementGroupDeploymentTemplate.json#$' {
                    if ($PSCmdlet.ShouldProcess("Management group level deployment", "Create")) {
                        New-AzManagementGroupDeployment @DeploymentInputs -location $location -managementGroupId $managementGroupId
                    }
                    break
                }
                '\/tenantDeploymentTemplate.json#$' {
                    if ($PSCmdlet.ShouldProcess("Tenant level deployment", "Create")) {
                        New-AzTenantDeployment @DeploymentInputs -location $location
                    }
                    break
                }
                default {
                    throw "[$deploymentSchema] is a non-supported ARM template schema"
                }
            }
        }
        else {
            throw "No deployment file found in path $componentsBasePath/$modulePath"
        }      
        if (Test-Path -Path "$componentsBasePath/$modulePath/post-deploy.ps1") {

            $scriptFilePath = "$componentsBasePath/$modulePath/post-deploy.ps1"
            Write-Output "Deploying post-configuration from $scriptFilePath"

            if (-not (Test-Path -Path $parameterFilePath)) {
                Throw "New-ModuleDeployment - Path '$parameterFilePath' not found"
            }
            for ($i = 1; $i -le $Retry; $i++) {
                try {
                    Write-Output "Post-deploy - Attempt #$i"
                    Invoke-Expression -Command "$scriptFilePath -ParametersFilePath $parameterFilePath"
                }
                catch {
                    if ($i -ne $Retry) {
                        $_
                        Write-Output "Post-deploy - Attempt #$i - Failed, retry in $RetryInterval seconds"
                        Start-Sleep -Seconds $RetryInterval
                        continue
                    }
                    else {
                        Write-Output "Post-deploy - Attempt #$i - Failed. Throwing error."
                        throw $_
                    }
                }
                break
            }
        }
    }
    
    end {
        Write-Debug ("{0} exited" -f $MyInvocation.MyCommand)  
    }
}
