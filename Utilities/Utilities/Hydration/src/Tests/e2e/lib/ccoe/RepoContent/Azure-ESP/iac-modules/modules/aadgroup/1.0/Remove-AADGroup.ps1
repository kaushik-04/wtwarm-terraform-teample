#
# Set-AADGroup
#
[cmdletbinding()]
param (
    [parameter(mandatory)]
    [string]
    $Directory
)

Write-Output "Remove-AADGroup - $Directory"
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
                Write-Output "Processing Group: $GroupName - Group Object - Group exists - Removing"
                try {
                    $Group | Remove-AzADGroup -Force
                    Write-Output "Processing Group: $GroupName - Group Object - Group exists - Removing - Successfull"
                } catch {
                    Write-Warning $_
                    Write-Output "Processing Group: $GroupName - Group Object - Group exists - Removing - Failed"
                    continue
                }
            } else {
                Write-Output "Processing Group: $GroupName - Group Object - Group does not exist"
            }
            #endregion
        }
    }
} else {
    throw "Remove-AADGroup - $Directory - Folder does not exist"
}