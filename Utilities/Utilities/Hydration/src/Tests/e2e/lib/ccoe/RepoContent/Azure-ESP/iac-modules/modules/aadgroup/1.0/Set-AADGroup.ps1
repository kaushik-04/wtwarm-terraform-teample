#
# Set-AADGroup
#
[cmdletbinding()]
param (
    [parameter(mandatory)]
    [string]
    $Directory
)

Write-Output "Set-AADGroup - $Directory"
if (Test-Path -Path $Directory) {
    Write-Output "Processing directory $Directory"
    $Files = Get-ChildItem -Path $Directory -Include '*.json' -Recurse
    Write-Output "Processing directory $Directory - Found $($Files.count) file(s)"
    foreach ($File in $Files) {
        Write-Output "Processing file $($File.Name)"
        $FilePath = $File.FullName
        $GroupObjects = Get-Content -Raw -Path $FilePath | ConvertFrom-Json
    
        #TODO: Validate schema / format of object

        foreach ($GroupObject in $GroupObjects) {
            #region Set Group Object
            $GroupName = $GroupObject.Name
            Write-Output "Processing Group: $GroupName - Group Object"
            $Group = Get-AzADGroup -DisplayName $GroupName
            if ($Group) {
                Write-Output "Processing Group: $GroupName - Group Object - Already exists"
            } else {
                Write-Output "Processing Group: $GroupName - Group Object - Creating group"
                $Group = New-AzADGroup -DisplayName $GroupName -MailNickname $GroupName
                Write-Output "Processing Group: $GroupName - Group Object - Creating group - Successfull"
            }
            if ($Group) {
                Write-Output "Processing Group: $GroupName - Group Object - ID - $($Group.ID)"
            } else {
                throw "Processing Group: $GroupName - Group Object - Creating/Getting group - Failed"
            }
            #endregion

            #region Set members
            Write-Output "Processing Group: $GroupName - Members"
            $ExistingMembers = @()
            $Members = Get-AzADGroupMember -GroupDisplayName $GroupName
            Write-Output "Processing Group: $GroupName - Members - Found $($Members.count) existing members"
            foreach ($Member in $Members) {
                switch ($Member.Type) {
                    "User" {
                        $ExistingMembers += $Member.UserPrincipalName
                    }
                    "ServicePrincipal" {
                        $ExistingMembers += $Member.DisplayName
                    }
                    "Group" {
                        $ExistingMembers += $Member.DisplayName
                    }
                }
            }

            $DeclaredGroupMembers = $GroupObject.Members
            $Diffs = Compare-Object -ReferenceObject $DeclaredGroupMembers -DifferenceObject $ExistingMembers -IncludeEqual
            foreach ($Diff in $Diffs) {
                $Name = $Diff.InputObject
                switch -Wildcard ($Name) {
                    "*@*" {
                        $Type = "User"
                        $ObjectID = (Get-AzADUser -UserPrincipalName $_).Id
                    }
                    "pxs-*" {
                        $Type = "ServicePrincipal"
                        $ObjectID = (Get-AzADServicePrincipal -DisplayName $_).Id
                    }
                    "grp-*" {
                        $Type = "Group"
                        $ObjectID = (Get-AzADGroup -DisplayName $_).Id
                    }
                }
                switch ($Diff.SideIndicator) {
                    "==" { $Action = "No change" }
                    "=>" { $Action = "Remove" }
                    "<=" { $Action = "Add" }
                }
                if ($ObjectID) {
                    Write-Output "Processing Group: $GroupName - Members - $Name - $Type - $Action"
                    try {
                        switch ($Action) {
                            "Add" {
                                Add-AzADGroupMember -MemberObjectId $ObjectID -TargetGroupDisplayName $GroupName
                            }
                            "Remove" {
                                Remove-AzADGroupMember -MemberObjectId $ObjectID -GroupDisplayName $groupName
                            }
                        }
                    } catch {
                        Write-Warning "Processing Group: $GroupName - Members - $Name - $Type - $Action - Failed"
                    }
                } else {
                    Write-Output "Processing Group: $GroupName - Members - $Name - $Type - $Action - Member object not found"
                    continue
                }
                
            }
            #endregion

            #region Set owners
            # Currently not supported in Az.Resources
            # If required, it has to be inplemented with AzureCLI or REST
            #endregion
        }
    }
} else {
    throw "Set-AADGroup - $Directory - Folder does not exist"
}