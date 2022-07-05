<#

    Platyps will generate the respective help file in the folder `docs`.
    When using VSCode the extension will generate a help blueprint when pressing `###` on the top of a function e.g. 

    ```
        
        .SYNOPSIS
        Creates a new Azure DevOps Project given parameter file

        .DESCRIPTION
        Creates a new Azure DevOps Project given parameter file

        .PARAMETER Path
        Path to the parameter file that matches the schema (Get-Schema)

        .EXAMPLE
        New-Project -Path $path
    ```

    platyPS picks it up and generates Markdown and XML for external help.
    Using this we make sure documentation stays up to date with the functionality. 

    Also, when running `get-help New-Project`, PowerShell will print inline help of the function.

    ```
    NAME
    New-Project
        
    SYNOPSIS
    Creates a new Azure DevOps Project given parameter file
        
        
    SYNTAX
    New-Project [-Path] <String> [-WhatIf] [-Confirm] [<CommonParameters>]
        
        
    DESCRIPTION
    Creates a new Azure DevOps Project given parameter file
        

    RELATED LINKS

    REMARKS
    To see the examples, type: "Get-Help New-Project -Examples"
    For more information, type: "Get-Help New-Project -Detailed"
    For technical information, type: "Get-Help New-Project -Full"
    ```

#>

function New-Docs {
    param (
        $OutputFolder = 'docs',
        $Module = 'Hydra'
    )

    Remove-Item $OutputFolder -Recurse -Force

    $parameters = @{
        Module                = $Module 
        OutputFolder          = $OutputFolder
        AlphabeticParamsOrder = $true
        WithModulePage        = $true
        ExcludeDontShow       = $true
    }
    New-MarkdownHelp @parameters

    New-ExternalHelp $OutputFolder -OutputPath (Join-Path $OutputFolder 'en-US')

    # New-MarkdownAboutHelp -OutputFolder $OutputFolder -AboutName $Module
}

try {
    if (-Not (Get-Module platyPS -ListAvailable)) {
        Install-Module -Name platyPS -Scope CurrentUser -Force
    }

    Import-Module platyPS
}
catch {
    Write-Error "Please install platyps from {0}" -f "https://github.com/PowerShell/platyPS"
}
try {
    $path = (Join-Path $PSScriptRoot 'src' 'Hydra')
    Write-Verbose "Import {$path}"
    import-module $path -force

    New-Docs
}
catch {
    Write-Error $_
    Write-Error $_.ScriptStackTrace
}
