# AAD Group 1.0

[[_TOC_]]

## Overview

This module will deploy and keep AAD groups in sync with the single source of truth in the form of a json file.

In this version of the module, Groups will be created and members will be added/removed.
This version will not be handling the owners of groups. This functionality is not available in powershell at the time of coding.
Implementation of group owners has to be done trough the use of az cli

## Input

The module takes a path to a folder where the group definitions are stored. Only json files will be picked up under that folder.

### Group definition

Groups are defined using json in the following format

``` json
{
    "name": "grp-groupname",
    "owners": [
        "owner1@contoso.com",
        "owner2@contoso.com"
    ],
    "members" : [
        "user1@contoso.com",
        "user2@contoso.com"
    ]      
}
```

The "name" should always start with "grp-"
The "members" takes users, groups and service principals
Members have to be defined like this:
    User: have "@" in the string
    Group: Start with "grp-"
    Service principal: start with "pxs-"

"owners" are currently not being handled

## Output

The module will handle the json files according to the definition and will output what it is doing in the terminal.
Key points of the output are:

 - Directory of where the script is getting the input
 - Group(s) being handled
 - Member evaluation (no change, remove, add)

What is reflected in the terminal is what is being changed in AAD.
