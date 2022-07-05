function Set-ADOServiceConnection {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,
        [Parameter(Mandatory)]
        [SecureString] $SPNSecret
    )
    if (Test-Path $Path) {
        $ServiceConnectionFileObj = Get-Content -Path $Path | ConvertFrom-Json -Depth 100
    } else {
        throw "File not found"
    }

    #TODO: Validate Schema
        
    # Find and set correct project
    $ProjectName = $ServiceConnectionFileObj.serviceEndpointProjectReferences.projectReference.name
    if ($ProjectName) {
        $Project = Get-ADOProject -ListAvailable | Where-Object name -eq $ProjectName
        if ($Project) {
            Set-ADOProject -ProjectName $ProjectName
        } else {
            throw "The specified project '$Project' doesnt exist, or access is restricted."
        }
    } else {
        throw "Project not specified"
    }

    Write-Output "Check if the Service Connection exists in the project - $($ServiceConnectionFileObj.name)"
    $Exists = Get-ADOServiceConnection -Name $ServiceConnectionFileObj.name -Exact
    if ($Exists) {
        Write-Output "This is an existing service connection, redeploying..."
        Remove-ADOServiceConnection -ID $Exists.ID
    } else {
        Write-Output "This is a new service connection"
    }

    Write-Output "Inject the SPNSecret in to the param file"
    $ServiceConnectionFileObj = Get-Content -Path $Path | ConvertFrom-Json -Depth 100
    $ServiceConnectionFileObj.authorization.parameters.serviceprincipalkey = $SPNSecret | ConvertFrom-SecureString -AsPlainText
    $ServiceConnectionFileObj | ConvertTo-Json -Depth 100 | Set-Content -Path $Path -Force

    Write-Output "Get and reset currently unsupported fields from the param file"
    $ServiceConnectionFileObj = Get-Content -Path $Path | ConvertFrom-Json -Depth 100
    try {
        $Authorized = [bool]::Parse($ServiceConnectionFileObj.authorized)
    } catch {
        $Authorized = $null
    }
    $ServiceConnectionFileObj.authorized = $null


    $administratorsGroups = $ServiceConnectionFileObj.administratorsGroup
    $ServiceConnectionFileObj.administratorsGroup = $null
    $readersGroups = $ServiceConnectionFileObj.readersGroup
    $ServiceConnectionFileObj.readersGroup = $null
    $usersGroups = $ServiceConnectionFileObj.usersGroup
    $ServiceConnectionFileObj.usersGroup = $null
    $ServiceConnectionFileObj | ConvertTo-Json -Depth 100 | Set-Content -Path $Path -Force

    Write-Output "Create the Service Connection"
    $NewServiceConnection = New-ADOServiceConnection -Parameterfile $Path

    Write-Output "Reset the Service Connection JSON file"
    $ServiceConnectionFileObj = Get-Content -Path $Path | ConvertFrom-Json -Depth 100
    $ServiceConnectionFileObj.authorization.parameters.serviceprincipalkey = $null
    $ServiceConnectionFileObj.authorized = $Authorized
    $ServiceConnectionFileObj.administratorsGroup = [string[]]$administratorsGroups
    $ServiceConnectionFileObj.readersGroup = [string[]]$readersGroups
    $ServiceConnectionFileObj.usersGroup = [string[]]$usersGroups
    $ServiceConnectionFileObj | ConvertTo-Json -Depth 100 | Set-Content -Path $Path -Force

    # Set permission on Service Connection
    if ($Authorized) {
        Set-ADOPermission -AllowAllPipelineAccess -ObjectID $NewServiceConnection.id
    }
    foreach ($Group in $administratorsGroups) {
        $Permission = "Administrator"
        $ADOGroup = Get-ADOGroup -Name $Group -Exact
        if ($ADOGroup) {
            try {
                Write-Verbose "Setting $Permission on $Group - $($ADOGroup.descriptor)"
                Set-ADOPermission -GroupID $ADOGroup.descriptor -ObjectID $NewServiceConnection.id -Allow $Permission
            } catch {
                Write-Warning $_
                Write-Warning "Failed setting $Permission on $Group"
            } 
        } else {
            Write-Warning "ADO group called $Group was not found, skipping"
            continue
        }
    }
    foreach ($Group in $readersGroups) {
        $Permission = "Reader"
        $ADOGroup = Get-ADOGroup -Name $Group -Exact
        if ($ADOGroup) {
            try {
                Write-Verbose "Setting $Permission on $Group - $($ADOGroup.descriptor)"
                Set-ADOPermission -GroupID $ADOGroup.descriptor -ObjectID $NewServiceConnection.id -Allow $Permission
            } catch {
                Write-Warning $_
                Write-Warning "Failed setting $Permission on $Group"
            } 
        } else {
            Write-Warning "ADO group called $Group was not found, skipping"
            continue
        }
    }
    foreach ($Group in $usersGroups) {
        $Permission = "User"
        $ADOGroup = Get-ADOGroup -Name $Group -Exact
        if ($ADOGroup) {
            try {
                Write-Verbose "Setting $Permission on $Group - $($ADOGroup.descriptor)"
                Set-ADOPermission -GroupID $ADOGroup.descriptor -ObjectID $NewServiceConnection.id -Allow $Permission
            } catch {
                Write-Warning $_
                Write-Warning "Failed setting $Permission on $Group"
            } 
        } else {
            Write-Warning "ADO group called $Group was not found, skipping"
            continue
        }
    }
        
    return $NewServiceConnection
}