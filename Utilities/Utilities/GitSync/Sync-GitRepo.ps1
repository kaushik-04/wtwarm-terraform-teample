<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		Sync-GitRepo.ps1

		Purpose:	Syncronize a Git Repository to another Git service

		Version: 	1.0.0.0 - 20 November 2020 - Sergio Navar, Luke Snoddy, Mate Barabas.
		==============================================================================================

	.SYNOPSIS
		Syncronize a Git Repository to another Git service/repo

	.DESCRIPTION
		Syncronize a Git Repository to another Git service/repo

		Deployment steps of the script are outlined below.
		1) Determines if operating system is Windows or Linux/Unix. Adjusts file paths appropriately. 	
        2) Creates a secondary directory and changes the context to the secondary directory
        3) Initiate a new Git (init) Repository within the secondary directory and pulls the destination Git service/repo
        4) A filter file is parsed to determine extentions, file, and directories that will be ignored as part of the synchronization. This filter file must exist on the source side of the synchronization
        5) Folders/Files are synchronized from the source directory to the secondary directory
        6) Git will detect any changes to the secondary directory and commit will be initiated to the destination repository 
        7) Git Push the commit to the desination repository
        8) Returns the context to the initial folder context 
			
	.PARAMETER DestinationPat
        Mandatory. Specify the PAT of the desintation Git service/repository.
        
    .PARAMETER DestinationRepoURL
        Mandatory. Specify the PAT of the desintation Git service/repository.   
    
    .PARAMETER DestinationAlias
        Mandatory. Specify the username/alias of the person running the script for the desintation Git service/repository
    
    .PARAMETER Name
        Mandatory. First and Last name of the person running the script. Using for Git Commit Metadata
    
    .PARAMETER UserEmail
        Mandatory. Email of the person running the script. Using for Git Commit Metadata

    .PARAMETER FilterFilePath
        Mandatory. File path of the filter file found within the source repository. Can be named anything 
    
	.EXAMPLE
		Default:
		C:\PS>.\Sync-GitRepo.ps1 `
            -DestinationPat <"DestinationPatValue"> `
            -DestinationRepoURL "github.com/ProjectName/RepoName.git" `
            -DestinationAlias "jdoe" `
            -GitUsername "John Doe" `
            -GitEmail "jdoe@microsoft.com" `
            -FilterFilePath "Utilities/gitSync/filter.json" `
            -Verbose
    
    .NOTES
        This script is designed to be run in Azure DevOps pipelines with Microsoft Hosted Agents.
        Version:        1.0
        Creation Date:  2020-11-20
#>

[cmdletbinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $DestinationPat,

    [Parameter(Mandatory = $true)]
    [string] $DestinationRepoURL,

    [Parameter(Mandatory = $true)]
    [string] $DestinationAlias,

    [Parameter(Mandatory = $true)]
    [string] $GitUsername,

    [Parameter(Mandatory = $true)]
    [string] $GitEmail,

    [Parameter(Mandatory = $false)]
    [string] $FilterFilePath = "Utilities/gitSync/filter.json"
)

$OsVersion = [Environment]::OSVersion.VersionString
$RepoPath = $PSScriptRoot
$RootFolder = $FilterFilePath.Split('/')[0]

if ($osVersion -Match "Windows") {
    $FilterFilePath = $FilterFilePath.Replace('/', '\')
}

Do {
    $RepoPath = Split-Path $RepoPath -Parent
}
Until($RepoPath -notlike "*${RootFolder}")

$FilterFile = Join-Path $RepoPath $FilterFilePath
$RootPath = Split-Path $RepoPath -Parent
New-Item -Path $RootPath -Name "SecondaryRepo" -ItemType "directory" 
$SecondaryRepoPath = Join-Path $RootPath "SecondaryRepo" 
Set-Location -Path $SecondaryRepoPath

if ($RepoURL -like "*github.com/*") {
    $GitRepo = "https://${DestinationAlias}:${DestinationPat}@${DestinationRepoURL}"
    $Source = "Azure DevOps"
}
else {
    $GitRepo = "https://${DestinationPat}@${DestinationRepoURL}"
    $Source = "Github"
}

git config --global user.email $GitEmail
git config --global user.name $GitUsername
git init $SecondaryRepoPath
git remote add secondary $GitRepo
git fetch secondary --force --tags --prune --no-recurse-submodules
git -c advice.detachedHead=false checkout secondary/master --force 

if (Test-Path $FilterFile) {
    $FilterJson = Get-Content $FilterFile -Raw | ConvertFrom-Json
    $FilterbyFile = $FilterJson.Files
    $FilterbyExtension = $FilterJson.Extensions
    $FilterbyFolder = $FilterJson.Folders
}
else {
    Write-Error "Filter file path does not exist. Exiting..."
    exit
}

$SourceItems = Get-ChildItem $RepoPath -Recurse
foreach ($Item in $SourceItems) {

    $Filter = @()
    foreach ($File in $FilterbyFile) {
        $CheckIfInRoot = $File.Split('/').Length - 1
        if ($OsVersion -Match "Windows") {
            $File = $File.Replace('/', '\')
            if($CheckIfInRoot -eq 1){
                $File = $File.Split('\')[1]
                $File = Join-Path $RepoPath $File
                $File = "${File}*"
            }
        }
        else{
            if($checkIfInRoot -eq 1){
                $File = $File.Split('/')[1]
                $File = Join-Path $RepoPath $File
                $File = "${File}*"
            }
        }
        if ($Item.FullName -like $File) {
            $Filter += "True"
        }
    }
    foreach ($Folder in $FilterbyFolder) {
        $CheckIfInRoot = $Folder.Split('/').Length - 1
        if ($OsVersion -Match "Windows") {
            $Folder = $Folder.Replace('/', '\')
            if($CheckIfInRoot -eq 1){
                $Folder = $Folder.Split('\')[1]
                $Folder = Join-Path $RepoPath $Folder
                $Folder = "${Folder}*"
            }
        }
        else{
            if($CheckIfInRoot -eq 1){
                $Folder = $Folder.Split('/')[1]
                $Folder = Join-Path $RepoPath $Folder
                $Folder = "${Folder}*"
            }
        }
        if ($Item.FullName -like $Folder) {
            $Filter += "True"
        }
    }
    foreach ($Extension in $FilterbyExtension) {
        if ($Item.FullName -like $Extension) {
            $Filter += "True"
        }
    }

    $Filter = $Filter | Select-Object -unique

    if ($Filter -ne "True") {
        $CheckItem = Test-Path -Path $Item.FullName -PathType Container
        $DestinationPath = Join-Path $SecondaryRepoPath $Item.FullName.Substring($RepoPath.length)
        if ($CheckItem -eq "True") { 
            $DestinationCheck = Test-Path $DestinationPath
            if (-not $DestinationCheck) {
                Copy-Item -Path $Item.FullName -Destination $DestinationPath 
            }
        }
        else {
            Write-Verbose "Synchronizing $($Item.FullName) to $($DestinationPath)" 
            Copy-Item -Path $Item.FullName -Destination $DestinationPath -Force 
        }
    }
    else {
        Write-Verbose "$($Item.FullName) has been filtered and will not be synced"
    }
}


$DestinationItems = Get-ChildItem $SecondaryRepoPath -Recurse
foreach ($DestItem in $DestinationItems) {
    
    $Filter = @()
    foreach ($File in $FilterbyFile) {
        $CheckIfInRoot = $File.Split('/').Length - 1
        if ($OsVersion -Match "Windows") {
            $File = $File.Replace('/', '\')
            if($CheckIfInRoot -eq 1){
                $File = $File.Split('\')[1]
                $File = Join-Path $SecondaryRepoPath $File
                $File = "${File}*"
            }
        }
        else{
            if($CheckIfInRoot -eq 1){
                $File = $File.Split('/')[1]
                $File = Join-Path $SecondaryRepoPath $File
                $File = "${File}*"
            }
        }
        if ($DestItem.FullName -like $File) {
            $Filter += "True"
        }
    }
    foreach ($Folder in $FilterbyFolder) {
        $CheckIfInRoot = $Folder.Split('/').Length - 1
        if ($OsVersion -Match "Windows") {
            $Folder = $Folder.Replace('/', '\')
            if($CheckIfInRoot -eq 1){
                $Folder = $Folder.Split('\')[1]
                $Folder = Join-Path $SecondaryRepoPath $Folder
                $Folder = "${Folder}*"
            }
        }
        else{
            if($CheckIfInRoot -eq 1){
                $Folder = $Folder.Split('/')[1]
                $Folder = Join-Path $SecondaryRepoPath $Folder
                $Folder = "${Folder}*"
            }
        }
        if ($DestItem.FullName -like $Folder) {
            $Filter += "True"
        }
    }
    foreach ($Extension in $FilterbyExtension) {
        if ($DestItem.FullName -like $Extension) {
            $Filter += "True"
        }
    }

    $Filter = $Filter | Select-Object -unique

    if ($Filter -ne "True") {
        $DestinationPath = Join-Path $RepoPath $DestItem.FullName.Substring($SecondaryRepoPath.length)
        $DestinationCheck = Test-Path $DestinationPath
        if (-not $DestinationCheck) {
            Write-Verbose "Removing $($DestItem.FullName) from the Secondary Repository because it has been removed from the Source Repository"
            Remove-Item -Path $DestItem.FullName -Force -Recurse -ErrorAction "SilentlyContinue"
        }
    }

}


$date = Get-Date -Format "MM/dd/yyyy"
$commit = "Synchronize from $source on $date"
git add --all
git commit -a -m $commit
git push secondary HEAD:master --force

Set-Location -Path $PSScriptRoot