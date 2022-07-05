function Invoke-PesterWrapper {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String] $root,
        [Parameter(Mandatory = $true)]
        [String] $TestFolder,
        [Parameter(Mandatory = $true)]
        [String] $ModuleFolder,
        [Parameter(Mandatory = $false)]
        [String] $IncludeTags = '*',
        [Parameter(Mandatory = $false)]
        [String] $TestCase,
        [Parameter(Mandatory = $false)]
        [String] $TestFile,
        [Parameter(Mandatory = $true)]
        [String] $OutputPath,
        [Parameter(Mandatory = $false)]
        [String] $CodeCoverageOutputPath,
        [Parameter(Mandatory = $false)]
        [switch] $cleanupE2Eproject
    )

    ####################
    #   PREAPARATION   #
    ####################

    $latestInstalledPesterVersion = ((Get-Module 'Pester' -ListAvailable).Version | Measure-Object -Maximum).Maximum.ToString()
    if ($latestInstalledPesterVersion -lt '5.1.1') {
        Write-Verbose "Installing latest Pester version as current [$latestInstalledPesterVersion] does not satisfy the requirements."
        Install-Module -Name 'Pester' -Force -Scope 'CurrentUser'
        $latestInstalledPesterVersion = ((Get-Module 'Pester' -ListAvailable).Version | Measure-Object -Maximum).Maximum.ToString()
    }
    else {
        Write-Verbose "Required PowerShell module 'Pester' with version [$latestInstalledPesterVersion] available"
    }
    Import-Module Pester -RequiredVersion $latestInstalledPesterVersion

    if (-Not (Get-Module 'PSScriptAnalyzer' -ListAvailable)) {
        Write-Verbose "Adding PowerShell module 'PSScriptAnalyzer'"
        Install-Module -Name 'PSScriptAnalyzer' -Force -Scope 'CurrentUser'
    }
    else {
        Write-Verbose "Required PowerShell module 'PSScriptAnalyzer' available"
    }

    if (-Not (Get-Module 'ImportExcel' -ListAvailable)) {
        Write-Verbose "Adding PowerShell module 'ImportExcel'"
        Install-Module -Name 'ImportExcel' -Force -Scope 'CurrentUser'
    }
    else {
        Write-Verbose "Required PowerShell module 'ImportExcel' available"
    }

    if ((az extension list-available -o json | ConvertFrom-Json).Name -notcontains 'azure-devops') {
        Write-Verbose "Adding CLI extension 'azure-devops'"
        az extension add --name 'azure-devops'
    }
    else {
        Write-Verbose "Required CLI extension 'azure-devops' available"
    }

    ###########################
    #   BUILD CONFIGURATION   #
    ###########################

    $pesterConfig = @{
        Run        = @{}
        Filter     = @{
            Tag = $IncludeTags
        }
        TestResult = @{
            TestSuiteName = 'Global Module API Tests'
            OutputPath    = $OutputPath
            OutputFormat  = 'NUnitXml'
            Enabled       = $true
        }
        Output     = @{
            Verbosity = 'Detailed'
        }
    }
    if ($IncludeTags -eq 'Acceptance') {
        $pesterConfig.Run = @{
            Container = New-PesterContainer -Path "$TestFolder/e2e/Integration/Invoke-Template.Tests.ps1" -Data @{
                paths             = @(
                    @{ path = "$TestFolder/e2e/lib/ccoe/hydration.definition.json" },
                    @{ path = "$TestFolder/e2e/lib/ccoe/hydration.definition.update.json" }
                )
                cleanupE2Eproject = $cleanupE2Eproject
            }
        }
    }
    elseif (-not [String]::IsNullOrEmpty($TestFile)) {
        # Only invoke specific file with current tag
        if (-not $TestFile.EndsWith(".ps1")) {
            $TestFile = "$TestFile.ps1"
        }
        Write-Verbose "Search file '$TestFile' in dir '$TestFolder'"
        $testFileObject = Get-ChildItem -Path $TestFolder -Recurse -File -Filter $TestFile
        if ($testFile) {
            $testFilePath = Join-Path $testFileObject.DirectoryName $testFileObject.Name
            $pesterConfig.Run = @{
                Path        = $testFilePath
                ExcludePath = @(
                    "$TestFolder/e2e/Integration/Invoke-Template.Tests.ps1",
                    "$TestFolder/e2e/lib/*"
                )
            }
        }
        else {
            throw "File by name $TestFile not found."
        }
    }
    else {
        # Default case: Search all
        $pesterConfig.Run = @{
            Path        = "$TestFolder/*.tests.ps1"
            ExcludePath = @(
                "$TestFolder/e2e/Integration/Invoke-Template.Tests.ps1",
                "$TestFolder/e2e/lib/*"
            )
        }
    }

    if (-not [String]::IsNullOrEmpty($TestCase)) {
        $pesterConfig.Filter['FullNameFilter'] = $TestCase
    }

    #####################
    #   INVOKE PESTER   #
    #####################

    Write-Verbose "Pester is invoked with:"
    Write-Verbose ("`n{0}" -f ($pesterConfig | ConvertTo-Json -Depth 5 | Out-String))

    $result = Invoke-Pester -Configuration $pesterConfig -ErrorAction 'Stop'
    Write-Verbose "Exported test results to $OutputPath"
    $result
}