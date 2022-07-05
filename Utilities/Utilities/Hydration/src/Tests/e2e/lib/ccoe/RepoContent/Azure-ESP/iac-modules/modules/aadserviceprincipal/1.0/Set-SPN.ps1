#
# Set-SPN
#
[cmdletbinding()]
param (
    [parameter(mandatory)]
    [String]
    $Directory
)

Write-Output "Set-SPN - $Directory"
if (Test-Path -Path $Directory) {
    Write-Output "Processing directory $Directory"
    $Files = Get-ChildItem -Path $Directory -Include '*.json' -Recurse
    Write-Output "Processing directory $Directory - Found $($Files.count) file(s)"

    #$File = $Files[0]
    foreach ($File in $Files) {
        Write-Output "Processing file $($File.Name)"
        $FilePath = $File.FullName
        $SPNObjects = Get-Content -Raw -Path $FilePath | ConvertFrom-Json
    
        #TODO: Validate schema / format of object

        #$SPNObject = $SPNObjects[0]
        foreach ($SPNObject in $SPNObjects) {
            #region Set App Object
            $SPNName = $SPNObject.Name
            Write-Output "Processing SPN: $SPNName - App Registration Object"
            $App = Get-AzAdApplication -DisplayName $SPNName
            if ($App) {
                Write-Output "Processing SPN: $SPNName - App Registration Object - Already exists"
            } else {
                Write-Output "Processing SPN: $SPNName - App Registration Object - Creating"
                $App = New-AzAdApplication -DisplayName $SPNName -IdentifierUris "http://$SPNName" -HomePage "http://$SPNName"
                Write-Output "Processing SPN: $SPNName - App Registration Object - Creating - Successfull"
            }
            if ($App) {
                Write-Output "Processing SPN: $SPNName - App Registration Object - ID      - $($App.ObjectId)"
                Write-Output "Processing SPN: $SPNName - App Registration Application - ID - $($App.ApplicationId)"
            } else {
                throw "Processing SPN: $SPNName - App Registration Object - Creating/Getting - Failed"
            }
            #endregion

            #region Set App Object
            $SPN = Get-AzAdServicePrincipal -DisplayName $SPNName
            if ($SPN) {
                Write-Output "Processing SPN: $SPNName - Enterprise Application Object - Already exists"
            } else {
                Write-Output "Processing SPN: $SPNName - Enterprise Application Object - Creating SPN"
                $SPN = New-AzAdServicePrincipal -DisplayName $SPNName -ApplicationId $App.ApplicationId -SkipAssignment
                Write-Output "Processing SPN: $SPNName - Enterprise Application Object - Creating SPN - Successfull"
            }
            if ($SPN) {
                Write-Output "Processing SPN: $SPNName - Enterprise Application Object - ID - $($SPN.ID)"
            } else {
                throw "Processing SPN: $SPNName - Enterprise Application Object - Creating/Getting SPN - Failed"
            }
            #endregion

            #region Set owners
            # Currently not supported in Az.Resources
            # If required, it has to be inplemented with AzureCLI or REST
            #endregion
        }
    }
} else {
    throw "Set-SPN - $Directory - Folder does not exist"
}