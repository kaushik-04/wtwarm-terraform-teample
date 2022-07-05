[[_TOC_]]

# Overview

Git is a distributed version-control system for tracing changes in any files within a repository. This, in combination with Visual Studio Code, will be used to manage the changes made in any file locally on your computer, user versioning through branch, and manage the transfer to and from the Repos in Azure DevOps.

# Installation

To install Git in your VM follow these instructions:

1. Open **Software Center**.
2. Select the **Application** menu in the left-side bar.
3. Search for **Git for Windows** and select it.
4. Click on the **install selected** button at the top-right of the screen.

This action will install the tools Git along with the *Git Bash* application.

# Configuration

## Set up Git in your cmd

For using Git commands in your Windows cmd you need to update the Path variable for your user by performing the following steps:

1. Type **Control Panel** in your search bar.
2. Select **User Accounts**.
3. Again, select **User Accounts**.
4. On the left-side menu, select **Change my environment variables**
5. In the *User Variables* section, edit the **Path** variable value by adding a new path pointing to your **Git** installation folder.

## Set up your Git account

To effectively clone a work with repositories, please execute the following commands in your cmd:

```console
    git config --global user.name <Firstname Lastname>
    git config --global user.email <@contoso.com email address>
    git config --global http.proxy http://:@userproxydc1.glb.ebc.local:8080
    git config --global http.sslVerify false
```
