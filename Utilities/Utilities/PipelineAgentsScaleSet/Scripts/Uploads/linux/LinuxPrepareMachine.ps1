$env:TEMP = '/tmp'

#region Functions
function LogInfo($message) {
    Log "Info" $message
}
function LogError($message) {
    Log "Error" $message
}
function LogWarning($message) {
    Log "Warning" $message
}

function Log {

    <#
    .SYNOPSIS
    Creates a log file and stores logs based on categories with tab seperation

    .PARAMETER category
    Category to put into the trace

    .PARAMETER message
    Message to be loged

    .EXAMPLE
    Log 'Info' 'Message'

    #>

    Param (
        [Parameter(Mandatory = $false)]
        [string] $category = 'Info',

        [Parameter(Mandatory = $true)]
        [string] $message
    )

    $date = get-date
    $content = "[$date]`t$category`t`t$message`n"
    Write-Verbose $Content -Verbose

    $FilePath = Join-Path $env:TEMP "log.log"
    if (-not (Test-Path $FilePath)) {
        Write-Verbose "Log file not found, create new in path: [$FilePath]" -Verbose
        $null = New-Item -ItemType 'File' -Path $FilePath -Force
    }
    Add-Content -Path $FilePath -Value $content -ErrorAction 'Stop'
}

function Copy-FilesAndFolders {

    param(
        [string] $sourcePath,
        [string] $targetPath
    )

    $itemsFrom = Get-ChildItem $sourcePath
    foreach ($item in $itemsFrom) {
        if ($item.PSIsContainer) {
            $subsourcePath = $sourcePath + "\" + $item.BaseName
            $subtargetPath = $targetPath + "\" + $item.BaseName
            $null = Copy-FilesAndFolders -sourcePath $subsourcePath -targetPath $subtargetPath
        }
        else {
            $sourceItemPath = $sourcePath + "\" + $item.Name
            $targetItemPath = $targetPath + "\" + $item.Name
            if (-not (Test-Path $targetItemPath)) {
                # only copies non-existing files
                if (-not (Test-Path $targetPath)) {
                    # if folder doesn't exist, creates it
                    $null = New-Item -ItemType "directory" -Path $targetPath -Verbose
                }
                $null = Copy-Item $sourceItemPath $targetItemPath
            }
            else {
                Write-Verbose "[$sourceItemPath] already exists" -Verbose
            }
        }
    }
}

function Install-CustomModule {
    <#
    .SYNOPSIS
    Installes given PowerShell module and saves it to a local store

    .PARAMETER Module
    Module to be installed, must be Object
    @{
        Name = 'Name'
        Version = '1.0.0' # Optional
    }

    .EXAMPLE
    Install-CustomModule @{ Name = 'Pester' } C:\Modules
    Installes pester and saves it to C:\Modules
    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory = $true)]
        [Hashtable] $Module
    )

    # Remove exsisting module
    if (Get-Module $Module -ErrorAction SilentlyContinue) {
        try {
            Remove-Module $Module -Force
        }
        catch {
            LogError("Unable to remove module $($Module.Name)  : $($_.Exception) found, $($_.ScriptStackTrace)")
        }
    }

    # Install found module
    $moduleImportInputObject = @{
        name       = $Module.Name
        Repository = 'PSGallery'
    }
    if ($module.Version) {
        $moduleImportInputObject['RequiredVersion'] = $module.Version
    }
    $foundModules = Find-Module @moduleImportInputObject
    foreach ($foundModule in $foundModules) {

        $localModuleVersions = Get-Module $foundModule.Name -ListAvailable 
        if ($localModuleVersions -and $localModuleVersions.Version -contains $foundModule.Version ) {
            LogInfo("Module [{0}] already installed with latest version [{1}]" -f $foundModule.Name, $foundModule.Version)
            continue
        }      
        if ($module.ExcludeModules -and $module.excludeModules.contains($foundModule.Name)) {
            LogInfo("Module {0} is configured to be ignored." -f $foundModule.Name)
            continue
        }

        LogInfo("Install module [{0}] with version [{1}]" -f $foundModule.Name, $foundModule.Version)
        if ($PSCmdlet.ShouldProcess("Module [{0}]" -f $foundModule.Name, "Install")) {
            $foundModule | Install-Module -Force -SkipPublisherCheck -AllowClobber
            if ($installed = Get-Module -Name $foundModule.Name -ListAvailable) {
                LogInfo("Module [{0}] is installed with version [{1}]" -f $installed.Name, $installed.Version)
            }
            else {
                LogError("Installation of module [{0}] failed" -f $foundModule.Name)
            }
        }
    }
}
#endregion


$StartTime = get-date

###########################
##   Install Azure CLI   ##
###########################
LogInfo("Install azure cli start")
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
LogInfo("Install azure cli end")

###############################
##   Install Extensions CLI   #
###############################

LogInfo("Install cli exentions start")
$Extensions = @(
    'azure-devops'
)
foreach ($extension in $Extensions) {
    if ((az extension list-available -o json | ConvertFrom-Json).Name -notcontains $extension) {
        Write-Verbose "Adding CLI extension '$extension'"
        az extension add --name $extension
    }
}
LogInfo("Install cli exentions end")

#########################
##   Install Kubectl    #
#########################
LogInfo("Install kubectl start")
sudo az aks install-cli
LogInfo("Install kubectl end")

###########################
##   Install Terraform   ##
###########################
LogInfo("Install Terraform start")
$TFVersion = '0.12.30' # Required for layered TF approach (01.2021)
if ([String]::IsNullOrEmpty($TFVersion)) {
    $terraformReleasesUrl = 'https://api.github.com/repos/hashicorp/terraform/releases/latest'
    $latestTerraformVersion = (Invoke-WebRequest -Uri $terraformReleasesUrl -UseBasicParsing | ConvertFrom-Json).name.Replace('v', '')
    LogInfo("Fetched latest available version: [$TFVersion]")
    $TFVersion = $latestTerraformVersion
} 

LogInfo("Using version: [$TFVersion]")
sudo apt-get install unzip
wget ('https://releases.hashicorp.com/terraform/{0}/terraform_{0}_linux_amd64.zip' -f $TFVersion)
unzip ('terraform_{0}_linux_amd64.zip' -f $TFVersion )
sudo mv terraform /usr/local/bin/
terraform --version 
LogInfo("Install Terraform end")

#######################
##   Install AzCopy   #
#######################
# Cleanup
sudo rm ./downloadazcopy-v10-linux*
sudo rm ./azcopy_linux_amd64_*
sudo rm /usr/bin/azcopy

# Download
wget https://aka.ms/downloadazcopy-v10-linux -O 'downloadazcopy-v10-linux.tar.gz'

# Expand (to azcopy_linux_amd64_x.x.x)
tar -xzvf downloadazcopy-v10-linux.tar.gz

# Move
sudo cp ./azcopy_linux_amd64_*/azcopy /usr/bin/

##################################
##   Install .NET (for Nuget)   ##
##################################
# Source: https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#1804-
LogInfo("Install dotnet (for nuget) start")
$ubuntuBaseVersion = 18.04

# .NET-Core Runtime
wget https://packages.microsoft.com/config/ubuntu/$ubuntuBaseVersion/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb

# .NET-Core SDK
sudo apt-get update
sudo apt-get install -y apt-transport-https && sudo apt-get update && sudo apt-get install -y dotnet-sdk-5.0

# .NET-Core Runtime
sudo apt-get update
sudo apt-get install -y apt-transport-https && sudo apt-get update && sudo apt-get install -y aspnetcore-runtime-5.0
LogInfo("Install dotnet (for nuget) end")

###############################
##   Install PowerShellGet   ##
###############################
LogInfo("Install latest PowerShellGet start")
$null = Install-Module "PowerShellGet" -Force
LogInfo("Install latest PowerShellGet end")

LogInfo("Import PowerShellGet start")
$null = Import-PackageProvider PowerShellGet -Force
LogInfo("Import PowerShellGet end")

####################################
##   Install PowerShell Modules   ##
####################################
$Modules = @(
    @{ Name = "Pester"; Version = '5.1.1' },
    @{ Name = "PSScriptAnalyzer" },
    @{ Name = "powershell-yaml" },
    @{ Name = "Azure.*" },
    @{ Name = "Logging" },
    @{ Name = "PoshRSJob" },
    @{ Name = "ThreadJob" },
    @{ Name = "JWTDetails" },
    @{ Name = "OMSIngestionAPI" },
    @{ Name = "Az.*" },
    @{ Name = "AzureAD" },
    @{ Name = "ImportExcel" }
)
$count = 0
LogInfo("Try installing:")
$modules | ForEach-Object {
    LogInfo("- [{0}]. [{1}]" -f $count, $_.Name)
    $count++
}

LogInfo("Install-CustomModule start")
$count = 0
Foreach ($Module in $Modules) {
    LogInfo("=====================")
    LogInfo("HANDLING MODULE [{0}] [{1}/{2}]" -f $Module.Name, $count, $Modules.Count)
    LogInfo("=====================")
    # Installing New Modules and Removing Old
    $null = Install-CustomModule -Module $Module
    $count++
}
LogInfo("Install-CustomModule end")


#########################################
##   Post Installation Configuration   ##
#########################################
LogInfo("Copy PS modules to '/opt/microsoft/powershell/7/Modules' start")
$null = Copy-FilesAndFolders -sourcePath '/home/packer/.local/share/powershell/Modules' -targetPath '/opt/microsoft/powershell/7/Modules'
LogInfo("Copy PS modules end")

$elapsedTime = (get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
LogInfo("Execution took [$totalTime]")
LogInfo("Exiting LinuxPrepareMachine.ps1")

return 0;
#endregion