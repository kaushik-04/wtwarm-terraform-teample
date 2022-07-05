param
(
    [parameter(Mandatory = $true)]
    [String] 
    $EnrollmentAccountObjectId,
    [parameter(Mandatory = $true)]
    [String]
    $OfferType,
    [parameter(Mandatory = $true)]
    [String]
    $SubscriptionName,
    [parameter(Mandatory = $true)]
    [String]
    $ManagementGroupId,
    [parameter(Mandatory = $false)]
    [String]
    $AadGroupPrefix
)

Install-Module Az.Subscription -Scope CurrentUser -AllowPrerelease -Force

$subscription = Get-AzSubscription -SubscriptionName $SubscriptionName -ErrorAction SilentlyContinue

if (-not $subscription) {
    $subscription = New-AzSubscription -Name $SubscriptionName -OfferType $OfferType -EnrollmentAccountObjectId $EnrollmentAccountObjectId
    # move subscription under a management group
    New-AzManagementGroupSubscription -GroupName $ManagementGroupId -SubscriptionId $subscription.Id
}

$subscriptionScope = "/subscriptions/" + $subscription.Id
$ownergroupName = $AadGroupPrefix + $subscription.Name + "-owner"
$contributorgroupName = $AadGroupPrefix + $subscription.Name + "-contributor"
$readergroupName = $AadGroupPrefix + $subscription.Name + "-reader"
$ownerGroupDescription = "RBAC group for subscription " +  $subscription.Name + " with owner rights"
$contributorGroupDescription = "RBAC group for subscription " +  $subscription.Name + " with contributor rights"
$readerGroupDescription = "RBAC group for subscription " +  $subscription.Name + " with reader rights"

$ownerGroup = Get-AzADGroup -DisplayName $ownergroupName
if (-not $ownerGroup) {
    $ownerGroup = New-AzADGroup -DisplayName $ownergroupName -MailNickname ownergroupName -Description $ownerGroupDescription
    Start-Sleep -Seconds 3
}

$contributorGroup = Get-AzADGroup -DisplayName $contributorgroupName
if (-not $contributorGroup) {
    $contributorGroup = New-AzADGroup -DisplayName $contributorgroupName -MailNickname contributorgroupName -Description $contributorGroupDescription
    Start-Sleep -Seconds 3
}

$readerGroup = Get-AzADGroup -DisplayName $readergroupName
if (-not $readerGroup) {
    $readerGroup = New-AzADGroup -DisplayName $readergroupName -MailNickname readergroupName -Description $readerGroupDescription
    Start-Sleep -Seconds 3
}

$ownerRoleAssignment = Get-AzRoleAssignment -ObjectId $ownerGroup.Id -RoleDefinitionName "Owner" -Scope $subscriptionScope
if (-not $ownerRoleAssignment) {
    New-AzRoleAssignment -ObjectId $ownerGroup.Id -RoleDefinitionName "Owner" -Scope $subscriptionScope
}

$contributorRoleAssignment = Get-AzRoleAssignment -ObjectId $contributorGroup.Id -RoleDefinitionName "Contributor" -Scope $subscriptionScope
if (-not $contributorRoleAssignment) {
    New-AzRoleAssignment -ObjectId $contributorGroup.Id -RoleDefinitionName "Contributor" -Scope $subscriptionScope
}

$readerRoleAssignment = Get-AzRoleAssignment -ObjectId $readerGroup.Id -RoleDefinitionName "Reader" -Scope $subscriptionScope
if (-not $readerRoleAssignment) {
    New-AzRoleAssignment -ObjectId $readerGroup.Id -RoleDefinitionName "Reader" -Scope $subscriptionScope
}

return $subscription