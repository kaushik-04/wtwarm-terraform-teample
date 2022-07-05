# Introduction

Enterprise Agreement (EA) subscriptions can be created via PowerShell. Although the actual code to create the subscription is very simple, some pre-requisites need to be fulfilled (see below). When everything is setup correctly, a pipeline can run with given parameters (new subscription name and a management group ID, where the subscription should be placed) and create the subscription. The following diagram shows the conceptual architecture. Additional three Azure Active Directory (AAD) groups will be created and assigned to the new subscription as owner, contributor and reader.

![CreateSubscriptions.png](.attachments/CreateSubscription.png =70%x)

# Limitations

The API for creating subscriptions via code has some limitations, see [Limitations of Azure Enterprise subscription creation API](https://docs.microsoft.com/en-us/azure/azure-resource-manager/programmatically-create-subscription?tabs=rest#limitations-of-azure-enterprise-subscription-creation-api):
- the used enrollment account needs to have created at least one subscription manually before it can be done programmatically
- an enrollment account can only create 2.000 subscriptions in its life-time, after that it will not be able to create new subscriptions (that limit was raised several times in the last years)

# Prerequisites

In order to create a subscription via code, the following pre-requisites are necessary:

- the used enrollment account is active and had created at least one subscription manually
- the pipeline uses a service connection that runs under the context of a SPN with the following permissions
  - SPN has owner rights on the billing scope of an EA enrollment account
  - SPN has owner rights on management group level (to move subscriptions to the correct management group)
  - SPN has AAD read/write permissions (to create AAD groups and assign them to the subscription)

## Create and prepare an Enterprise Enrollment Account

The Enterprise Enrollment Account (EEA) is a very powerful role. Unfortunately it cannot be added in the Azure portal, but in the EA portal, see [Add an account](https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/ea-portal-get-started#add-an-account). It is important to highlight, that the EA account is not a separate entity in AAD (or somewhere else), but adds special permissions to an existing account (AAD or even Microsoft consumer account, like *@hotmail.com). The best practice is to only allow AAD accounts to have any role in the EA portal. The following steps should be followed to create and activate an EA enrollment account:

1. create a new user in AAD through Azure portal (the user does not need any special permissions yet)
1. set the usage location of the new user in AAD (if this step is ommited, the role assignment will fail)
1. create a new EEA user in the EA portal (see screenshot below this list) and use the email address from the user created in step one
1. login with this new EEA in the EA portal and accept the license terms
1. create one subscription through the UI of the EA portal (still with the new EEA user) and again accept license terms

The Enterprise Enrollment Account is now prepared to be used in the automatic subscription creation.

![create-ea-add-an-account.png](.attachments/create-ea-add-an-account.png =70%x)

## Create and prepare a Service Principal

The pipeline that creates the subscription will run under the context of a Service Principal (SPN). This SPN needs to have the permissions from the EAA to create the subscription on his behalf. The following steps should be followed to create a SPN and link it to an EA enrollment account: 

1. create SPN and grant owner rights on a management group level
1. assign owner permissions over billing scope of the EEA to the SPN
1. allow the SPN API permissions on AAD (read/write) if new groups should be created and assigned to the new subscription

Here are all the necessary steps in detail:

### Create SPN

```powershell
Import-Module Az

$spDisplayName = 'SubscriptionCreator01'
$servicePrincipal = New-AzAdServicePrincipal -DisplayName $spDisplayName -Role Owner -scope /providers/Microsoft.Management/managementGroups/{MgID}
```
### Add permissions from EEA to SPN

In order to run the following commands successfully, the EEA needs to authenticate the PowerShell session so it runs under his context.

```powershell
#get enrollment account GUID
$enrollmentId = Get-AzEnrollmentAccount | Select-Object -first 1 | select ObjectId

#set owner to enrollment account
New-AzRoleAssignment -RoleDefinitionName Owner -ObjectId $servicePrincipal.Id -Scope /providers/Microsoft.Billing/enrollmentAccounts/$enrollmentId
```
**Information**: do use *ObjectId* and not *ApplicationId* for the role assignment

### Add AAD read/write API permissions to SPN

This needs to be done in the Azure portal under AAD (by an AAD admin), see screenshot below.

![AAD_permissions.png](.attachments/AAD_permissions.png =50%x)

## Create and prepare a Azure DevOps Service Connection

In the project settings in Azure DevOps (ADO), the service connection needs to be set up with the advanced dialog. The following steps should be followed to create a Service Connection that runs under the SPNs context (the dialog should look like the screenshot below this list):

1. scope level should be management group
1. management group ID and name need to be filled out
1. the Service Principle Id is the Application (client) ID from the App Registration

![ADO_serviceconnection.png](.attachments/ADO_serviceconnection.png =50%x)

Now everything is setup to run the pipeline that is in this directory. The pipeline will run the New-AzureSubscription.ps1 file with the given parameters. The EnrollmentAccountObjectId in the pipeline file needs to be updated with the actual Enrollment Account ObjectId.

![Pipeline.png](.attachments/Pipeline.png =50%x)
