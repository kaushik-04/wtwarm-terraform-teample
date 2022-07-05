[Cmdletbinding()]
param()

$ModuleRoot = $PSScriptRoot | Get-Item

Write-Verbose "Importing subcomponents from $($ModuleRoot.FullPath)"
$Folders = Get-ChildItem $ModuleRoot -Directory

# Import everything in these folders
foreach ($Folder in $Folders) {
    Write-Verbose "Processing folder: $Folder"
    if (Test-Path -Path $Folder) {
        Write-Verbose "Getting all files in $Folder"
        $Files = $null
        $Files = Get-ChildItem -Path $Folder -Include '*.ps1', '*.psm1' -Recurse
        foreach ($File in $Files) {
            Write-Verbose "Importing $($File)"
            Import-Module $File
            Write-Verbose "Importing $($File): Done"
        }
    }
}

$Param = @{
    Function = (Get-ChildItem -Path "$ModuleRoot\Public" -Include '*.ps1' -Recurse).BaseName
    Variable = '*'
    Cmdlet   = '*'
    Alias    = '*'
}
Export-ModuleMember @Param
