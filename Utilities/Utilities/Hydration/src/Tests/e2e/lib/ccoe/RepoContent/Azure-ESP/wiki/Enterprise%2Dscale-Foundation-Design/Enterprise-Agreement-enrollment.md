[[_TOC_]]

# Overview

contoso has arranged the EA structure under Cloud Native department, as shown below

![Overview of Enterprise enrollment](/.attachments/images/Foundation-Design/platform-design-ea.png)

> NOTE: the diagram can be modified using the Visio file on [Teams GRP MCS Cloud-native Engagement > Agile Delivery](https://teams.microsoft.com/_?lm=deeplink&lmsrc=homePageWeb&cmpid=WebSignIn#/conversations/Agile%20Delivery?threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&ctx=channel) > Files > [01 - Design Documents](https://contoso.sharepoint.com/sites/GRP_001608-AgileDelivery/Shared%20Documents/Forms/AllItems.aspx?RootFolder=%2Fsites%2FGRP%5F001608%2DAgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20%2D%20Design%20Documents&FolderCTID=0x01200001544C4EB547E84DB41D1C6FCCD4BEA9) > [PXS - Diagrams.vsdx](https://teams.microsoft.com/l/file/6F59E176-935C-450C-B8A0-A23AB3831B4C?tenantId=e7ab81b2-1e84-4bf7-9dcb-b6fec01ed138&fileType=vsdx&objectUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20-%20Design%20Documents%2FPXS%20-%20Diagrams.vsdx&baseUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery&serviceName=teams&threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&groupId=348f9039-5718-417a-8e56-85e2957e26be)

# Design decisions
It is important that you prevent being accidentally locked out of your Azure Active Directory (Azure AD) organization because you can't sign in or activate another user's account as an administrator. You can mitigate the impact of accidental lack of administrative access by creating two or more emergency access accounts in your organization.
Emergency access accounts are highly privileged, and they are not assigned to specific individuals. Emergency access accounts are limited to emergency or "break glass"' scenarios where normal administrative accounts can't be used. We recommend that you maintain a goal of restricting emergency account use to only the times when it is absolutely necessary.
Create 2 break glass accounts that will become the only accounts with Enterprise Administrator role in the organization [EA-portal](https://ea.azure.com). 
These emergency access accounts are limited to emergency or "break glass" scenarios where normal administrative accounts can't be used. 

For all administrator roles in the EA portal, it is recommended that work/school accounts are used. Avoid Microsoft accounts and other non-regulated accounts from a foreign directory.

More information about emergency-access accounts [here](https://docs.microsoft.com/en-us/azure/active-directory/roles/security-emergency-access)

**Process of using break glass accounts** 

When configuring break glass (emergency) accounts, the following requirements must be met: 
- The emergency access accounts should not be associated with any individual user in the organization. 
- Make sure that your accounts are not connected with any employee-supplied mobile phones, hardware tokens that travel with individual employees, or other employee-specific credentials. 
- The authentication mechanism used for an emergency access account should be distinct from that used by your other administrative accounts, including other emergency access accounts. For example, if your normal administrator sign-in is via on-premises MFA, then Azure MFA would be a different mechanism (or preferably should even disable MFA for this account). However, if Azure MFA is your primary part of authentication for your administrative accounts, then consider a different approach for these, such as using Conditional Access with a third-party MFA provider via Custom controls. 
- Credentials **must not expire** or be **in scope of automated cleanup** due to lack of use. 
- At least one of your emergency access accounts should not have the same multi-factor authentication mechanism as your other non-emergency accounts, or any kind of MFA at all. This includes third-party multi-factor authentication solutions. 
- At least one of your emergency access accounts should not be a part of Conditional Access policies.
- Some organizations use AD Domain Services and ADFS or similar identity provider to federate to Azure AD. There should be no on-premises accounts with administrative privileges. Mastering and/or sourcing authentication for accounts with administrative privilege outside Azure AD adds unnecessary risk in the event of an outage or compromise of those system(s). 
- Organizations need to ensure that the credentials for emergency access accounts are kept secure and known only to individuals who are authorized to use them. Some customers use a smartcard and others use passwords. A password for an emergency access account is usually separated into two or three parts, written on separate pieces of paper, and stored in secure, fireproof safes that are in secure, separate locations.
- If using passwords, make sure the accounts have strong passwords that do not expire. Ideally, the passwords should be at least 16 characters long and randomly generated.
- Monitor sign-in and audit logs.
- You should make the Global Administrator role assignment permanent for your emergency access accounts. 

**Monitor sign-in and audit logs**

Organizations should monitor sign-in and audit log activity from the emergency accounts and trigger notifications to other administrators. When you monitor the activity on break glass accounts, you can verify these accounts are only used for testing or actual emergencies. You can use Azure Log Analytics to monitor the sign-in logs and trigger email and SMS alerts to your admins whenever break glass accounts sign in.

Disable notifications on Enterprise Administrator (EA-portal) accounts (no real person behind that account and no mailbox either) and assign notification contact details to the Azure Enrollment Portal. Mailbox should be monitored for notifications by a relevant admin team working with Azure admin activities. For instance the CCoE shared mailbox.

How to setup monitoring on the use of emergency accounts (https://docs.microsoft.com/en-us/azure/active-directory/roles/security-emergency-access#monitor-sign-in-and-audit-logs)

**Validate accounts regularly**

When you train staff members to use emergency access accounts and validate the emergency access accounts, at minimum do the following steps at regular intervals:
- Ensure that security-monitoring staff are aware that the account-check activity is ongoing.
- Ensure that the emergency break glass process to use these accounts is documented and current.
- Ensure that administrators and security officers who might need to perform these steps during an emergency are trained on the process.
- Update the account credentials, in particular any passwords, for your emergency access accounts, and then validate that the emergency access accounts can sign-in and perform administrative tasks.
- Ensure that users have not registered Multi-Factor Authentication or self-service password reset (SSPR) to any individual user’s device or personal details.
- If the accounts are registered for Multi-Factor Authentication to a device, for use during sign-in or role activation, ensure that the device is accessible to all administrators who might need to use it during an emergency. Also verify that the device can communicate through at least two network paths that do not share a common failure mode. For example, the device can communicate to the internet through both a facility's wireless network and a cell provider network.

## Billing Accounts

| Company Name | Billing account ID | Type                 |
| ------------ | ------------------ | -------------------- |
| contoso NV  | 60287334           | Enterprise Agreement |

## Departments

| Department Name | Department ID |
| --------------- | ------------- |
| Cloud Native    | 129273        |

## Accounts

| Account Name        | Account owner         | Department ID | Enrollment ID | Comments                                        |
| ------------------- | --------------------- | ------------- | ------------- | ----------------------------------------------- |
| az-playground-admin | id700024@contoso.com | 129273        | 271887        | Sandbox subscriptions                           |
| az-non-prod-admin   | id700029@contoso.com | 129273        | 272438        | Non-prod subscriptions                          |
| az-prod-admin       | id700081@contoso.com | 129273        | 275943        | Production (including management) subscriptions |

## Permissions

| Service Principal                         | Role                                                                                                                                                                                                | Account |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| pxs-buildingblocks-buildingblocks-d-mg-sp | [Enrollment account subscription creator](https://docs.microsoft.com/en-us/rest/api/billing/2019-10-01-preview/billingroledefinitions/listbyenrollmentaccount#enrollmentaccountroledefinitionslist) | 271887  |
| pxs-buildingblocks-buildingblocks-d-mg-sp | [Enrollment account subscription creator](https://docs.microsoft.com/en-us/rest/api/billing/2019-10-01-preview/billingroledefinitions/listbyenrollmentaccount#enrollmentaccountroledefinitionslist) | 272438  |
| pxs-buildingblocks-buildingblocks-d-mg-sp | [Enrollment account subscription creator](https://docs.microsoft.com/en-us/rest/api/billing/2019-10-01-preview/billingroledefinitions/listbyenrollmentaccount#enrollmentaccountroledefinitionslist) | 275943  |

## Break-glass accounts

The break glass accounts for the EA-portal (https://ea.azure.com) in the AAD:
| Account Name                               | ObjectId                             |
|--------------------------------------------|--------------------------------------|
| ea-brk-glass1@contoso.onmicrosoft.com | 3267dcec-ef3f-4577-9fc3-80eb19d58299 |
| ea-brk-glass2@contoso.onmicrosoft.com | fd97468c-48f0-4762-a9c0-fb38d87bdc87 |

Both break-glass accounts are defined as EA administrators:

![EA-break-glass-account!](/.attachments/images/EA-enrollment/ea-break-glass-account.png)

The name of these accounts cannot be associated with any individual contoso employee nor the contoso id97/id99 type accounts.

The passwords of these accounts are generated by a password generated tool and satisfy to:
- minimum password length (16)
- a mix of numbers, special characters, uppercases and lowercases

The passwords are stored in the CCoE teams vault (CyberArk: USR IPRAM TS ccoe_ea_brkglass TM)

# Planned work

::: query-table 9154c501-b898-4910-96cb-fcfb91accb5d
:::

# Configuration details 
## Configuration details EA-portal setup.
![EA-enrollment structure!](/.attachments/images/EA-enrollment/EA-portal-structure.png)
### To add a department
*As an enterprise administrator:*
1.	Sign in to the Azure Enterprise portal https://ea.azure.com.
1.	In the left pane, select **Manage**.
1.	Select the **Department** tab, then select **+ Add Department**.
1.	Enter the information. The department name is the only required field. It must be at least three characters. For instance “Cloud Native” or "Cloud Enabled"
1.	When complete, select **Add**.

### To add an administrator to a department
*As an enterprise administrator:*
1.	Sign in to the Azure Enterprise portal.
1.	In the left pane, select **Manage**.
1.	Select the **Department** tab and then select the department.
1.	Select **+ Add Administrator** and add the required information.
1.	For read-only access, set the **Read-Only** option to **Yes** and then select **Add**.

### To associate an account to a department
*As an enterprise administrator:*
1.  Select **Manage** on the left navigation.
1.	Select **Department**.
1.	Hover over the row with the account and select the pencil icon on the right.
1.	Select the department from the drop-down menu.
1.	Select **Save**.

### To transfer account ownership for a single subscription:
*As an enterprise administrator:*
1.	In the left navigation area, select **Manage**.
1.	Select the **Account** tab and hover over an account.
1.	Select the transfer subscriptions icon on the right. The icon resembles a page.

![Move subscription screen shot!](/.attachments/images/EA-enrollment/ea-transfer-subscriptions.png)
1.	Choose the destination account to transfer the subscription and then select **Next**.
1.	If you want to transfer the subscription ownership across Azure AD tenants, select the **Move the subscriptions to the recipient's Azure AD tenant** checkbox.
1.	Confirm the transfer and then select **Submit**.

### Associate an existing account
1.	In the Azure Enterprise portal, select **Manage**.
1.	Select the **Account** tab.
1.	Select **+ Add an account**.
1.	Enter the work, school, or Microsoft account associated with the existing Azure account.
1.	Confirm the account associated with the existing Azure account.
1.	Provide a name you would like to use to identify this account in reporting.
1.	Select **Add**.
1.	To add an additional account, you can select the **+ Add an Account** option again or return to the homepage by selecting the Admin button.
1.	If you view the **Account** page, the newly added account will appear in a **Pending** status.

### Change the account from pending to active:
When new Account Owners (AO) are added to the enrollment for the first time, they will always show as "pending" under status. 
Upon receiving the activation welcome email, AO can sign in to activate their account. 
Signing in will update the account status from "pending" to "active".
Open a Chrome browser as guest. (See arrows)

![Open a Chrome guest session!](/.attachments/images/EA-enrollment/EA-portal-guest.png)
log in with the credentials of the new account owner.

More detailed information about managing EA-portal:
https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/ea-portal-administration

### Request an "id97/99" contoso account
1.  Create a request via link: https://intra.web.bc/SSEP/Forms/form.aspx?id=933
1.  Fill in the mandatory fields of the request. Remark: *only a manager can be owner of an id97/99 contoso account.*

![Move subscription screen shot!](/.attachments/images/EA-enrollment/SRS-id700024.png)
1.  After creation of the account (closure of the request), the owner of the account (team manager), can request the password reset of the account.
1.  By default the account is created like: idxxxxxx@contoso.onmicrosoft.com. 

### Change the domain from contoso.onmicrosoft.com to contoso.com
1.  Create ticket or request for team **AS-COMMUNICATION AND COLLAB SOLUTIONS** and ask for executing: 
    
    **Set-ADUser -Identity 'CN=idxxxxxx,OU=Process,OU=All_Logins,DC=BGC,DC=NET' -UserPrincipalName idxxxxxx@contoso.com**

    (where idxxxxxx is replaced by the actual account)

## Configuration details "break glass" accounts + monitoring
1. The signin logs are send to the log analytics workspace **pxs-mgmt-p-log-ccoe-law** (in the **pxs-mgmt-p-log-sub** subscription).

    *More info about the setup:* [send logs to Azure monitor](https://docs.microsoft.com/en-us/azure/active-directory/reports-monitoring/howto-integrate-activity-logs-with-log-analytics#send-logs-to-azure-monitor)

2. An alert rule will send a mail to the ccoe@contoso.com mailbox when 1 of the break glass account is used to login.

    **Log Analytics workspace > pxs-mgmt-p-log-ccoe-law > alerts > Manage alert rules**

![Alert-rule-ccoe-mail-detail!](/.attachments/images/EA-enrollment/Alert-rule-ccoe-mail-detail.png)

The alert rule will start the action (sending the mail to ccoe), when the number of records returned by the below query greater is than 0. The UserId values are the objectIds of the break glass accounts.
(*This check is done each 5 minutes.*)
```
SigninLogs
| project UserId
| where UserId == '3267dcec-ef3f-4577-9fc3-80eb19d58299' or UserId == 'fd97468c-48f0-4762-a9c0-fb38d87bdc87'
```
*More information about how to monitor signin logs:* [here](https://docs.microsoft.com/en-us/azure/active-directory/roles/security-emergency-access#monitor-sign-in-and-audit-logs)

