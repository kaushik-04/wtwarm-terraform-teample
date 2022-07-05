function Get-Identity {
    Write-Host ""
    Write-Host ""
    Write-Host "-------------------------------------------------------------------------------------------------------------------"
    Write-Host "Checking RBAC permissions"
    Write-Host "-------------------------------------------------------------------------------------------------------------------"

    Write-Host "    Getting the Object ID of the User / Service Principal..."

    $Context = Get-AzContext
    $Account = $Context.Account

    if ($Account.Type -eq "User") {
        # Standard user
        $Obj = Get-AzADUser -UserPrincipalName $Account.Id
        if ($Obj) {
            $ObjId = $Obj.Id
            Write-Host "    The script is running on behalf of this User (Object ID): $ObjId"
        }
        # Guest user
        else {
            $UPN = $Account.Id.Replace('@', '_') + "#EXT#@$AadTenantFqdn"
            $Obj = Get-AzADUser -UserPrincipalName $UPN
            $ObjId = $Obj.Id
            Write-Host "    The script is running on behalf of this guest User (Object ID): $ObjId"
        }

    }
    elseif ($Account.Type -eq "ServicePrincipal") {
        $Obj = Get-AzADServicePrincipal -ApplicationId $Account.Id
        $ObjId = $Obj.Id
        Write-Host "    The script is running on behalf of this Service Principal (Object ID): $ObjId"
    }
    else {
        Write-Host "Unknown/Unsupported type of the principal: $($Account.Type), aborting the script !" -ErrorAction Stop
    }


    return $Obj
}