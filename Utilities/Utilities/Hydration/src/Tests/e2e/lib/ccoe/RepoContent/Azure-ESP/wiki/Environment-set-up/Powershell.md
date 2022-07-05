[[_TOC_]]

# Overview

With PowerShell you can manage Azure resources directly from the command line. We will be using Azure PowerShell to automate some of the deployments to Azure, along with other modules to test our scripts.

# Installation

PowerShell should be installed by default. As part of the toolset, also Azure CLI should be installed in your VM. To allow the IT team to install AzCLI in your VM, please raise a request in [IMA](https://intra.web.bc/IMAEMPS/imaEmployees/portals/std/index-portal.jsp) with the following ID ```MICROSOFT_AZURE_CLI_X```

# Configuration

For configuring the PowerShell blade with all the required modules, please execute the following commands.

## Install Gallery for Powershell

```console
    Install-Module -Name PowerShellGet -RequiredVersion 2.2.5 -Force -Scope CurrentUser -AllowClobber
```

## Configure TLSv1.2 for PSGallery

```console
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    New-Item -Path “$([Environment]::GetFolderPath(“MyDocuments”))\WindowsPowerShell” -ItemType Directory -EA 0
```

## Install Az Modules

Open a new Powershell window and run the following commands.

```console
    Install-Module -Name Az -AllowClobber -Scope CurrentUser -SkipPublisherCheck -Force
    Import-Module -Name Az
```

## Setup connection to use proxy to connect to Azure via Az

Open a new cmd window and run the following commands.

``` console
    setx HTTP_PROXY http://:@userproxydc1.glb.ebc.local:8080
    setx HTTPS_PROXY http://:@userproxydc1.glb.ebc.local:8080
``` 
Please be aware that you need to start a new session of cmd in order for the new variables to be available!

## Install Pester 5.0 Module

Open a new Powershell window and run the following commands.
```console
    Install-Module -Name Pester -RequiredVersion 5.0.4 -Scope CurrentUser -AllowClobber -Force
    Import-Module -Name Pester -RequiredVersion 5.0.4
```

## Install AzureAD Module

```console
    Install-Module AzureAD
    Import-module AzureAD
```



