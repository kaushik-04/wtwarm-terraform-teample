!#/bin/bash
var4=`echo $http_proxy`
var5=`echo $https_proxy`
var6=`echo $no_proxy`
echo "Unsetting variables"
export http_proxy=''
export https_proxy=''
export no_proxy=''
echo "variables have been unset"
# Download the Microsoft repository GPG keys
 wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
# Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb
# Update the list of products
sudo apt-get update
# Enable the "universe" repositories
sudo add-apt-repository universe
# Install PowerShell
sudo apt-get install -y powershell
# Start PowerShell

pwsh -command 'Install-Module Az -AllowClobber -Confirm:$false -Force'
pwsh -command 'Install-Module Pester -SkipPublisherCheck -RequiredVersion 4.10.1 -Confirm:$false -Force'

export http_proxy=$var4
echo "Exported $http_proxy"
export https_proxy=$var5
echo "Exporting $https_proxy"
export no_proxy=$var6
echo "Exporting $no_proxy"
echo "Execution completed"