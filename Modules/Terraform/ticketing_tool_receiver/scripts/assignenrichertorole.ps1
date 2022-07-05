
[CmdletBinding()]
param (    
    [Parameter(Mandatory = $true)]
    [Guid]
    $enricherMSIIdentity = '6881519c-7542-4815-bb00-e02fcb64dd15',
    [Parameter(Mandatory = $true)]
    [string]
    $receiverEntAppName ,
    [String]
    $tenantId = '72f988bf-86f1-41af-91ab-2d7cd011db47'

)

# you may not need tenantId, but if it is ambiguous you should set it here
Connect-AzureAd
# name of your MSI service principal, in my case msi-func. You can also get the ID from Enterprise Applications in AAD (not App Reg)
$msifunc = Get-AzureADServicePrincipal -ObjectId $enricherMSIIdentity


# name of your AAD service principal, in my case aad-func. You can also get the ID from App Registrations in AAD
$aadapp = Get-AzureADServicePrincipal -SearchString $receiverEntAppName

# Id - the ID of the role. You can get it from the app's manifest
# PrincipalId - the object ID of the MSI principal
# ObjectId - the object ID of the MSI principal
# ResourceId - the object ID of the AAD app
New-AzureADServiceAppRoleAssignment -Id $aadapp.AppRoles[0].Id -PrincipalId $msifunc.ObjectId -ObjectId $msifunc.ObjectId -ResourceId $aadapp.ObjectId.ToString()

# connect PLS to PE
# az network private-endpoint create --connection-name enricherPE --name enricherPE --private-connection-resource-id /subscriptions/9e9d8a58-6c9b-4cdb-8a7b-6450e36a6f51/resourceGroups/tick-receiverdemo-eastus2-rg/providers/Microsoft.Network/privateLinkServices/jstartrcvr102320pls --resource-group tick-enricherdemo-eastus2-rg --subnet integration --vnet-name ticketing
# az network private-endpoint create --connection-name receiverPE --name receiverPE --private-connection-resource-id /subscriptions/9e9d8a58-6c9b-4cdb-8a7b-6450e36a6f51/resourceGroups/tick-receiverdemo-eastus2-rg/providers/Microsoft.Network/privateLinkServices/jstartrcvr102320pls --resource-group tick-receiverdemo-eastus2-rg --subnet integration --vnet-name ticketing_receiver

