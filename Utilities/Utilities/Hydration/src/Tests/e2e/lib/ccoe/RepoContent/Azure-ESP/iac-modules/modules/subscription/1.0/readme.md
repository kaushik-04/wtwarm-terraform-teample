# Subscription

This template will create a subscription based on the provided parameter.

## Resource types

| Resource Type                             | Api Version        |
| :---------------------------------------- | :----------------- |
| `Microsoft.Resources/deployments`         | 2019-10-01         |
| `Microsoft.Subscription/aliases`          | 2020-09-01         |
| `Microsoft.Resources/tags`                | 2020-10-01         |
| `Microsoft.Authorization/roleAssignments` | 2018-09-01-preview |

### Resource dependency

The following resources are required to be able to deploy this resource:

- *None*

## Parameters

| Parameter Name            | Type   | Default Value | Possible values     | Description                                                               |
| :------------------------ | :----- | :------------ | :------------------ | :------------------------------------------------------------------------ |
| `subscriptionAliasName`   | string |               |                     | Required. Unique alias name.                                              |
| `displayName`             | string |               |                     | Required. Subscription display name.                                      |
| `targetManagementGroupId` | string | ""            |                     | Optional. Target management group where the subscription will be created. |
| `billingScope`            | string |               |                     | Required. The account to be invoiced for the subscription.                |
| `workload`                | string | Production    | Production, DevTest | Optional. Subscription workload.                                          |
| `tags`                    | object |               |                     | Optional. Tags of the storage account resource.                           |
| `roleAssignments`         | array  |               |                     | Optional. Array of role assignment objects.                               |

### Parameter Usage: `tags`

Tag names and tag values can be provided as needed. A tag can be left without a value.

```json
"tags": {
    "value": {
        "Environment": "Non-Prod",
        "Contact": "test.user@testcompany.com",
        "PurchaseOrder": "1234",
        "CostCenter": "7890",
        "ServiceName": "DeploymentValidation",
        "Role": "DeploymentValidation"
    }
}
```

### Parameter Usage: `roleAssignments`

```json
"roleAssignments": {
    "value": [
        // Built-in Role Definition, referenced by Name
        {
          "roleDefinitionIdOrName": "Owner",
          "principalIds": [
            "12345678-1234-1234-1234-123456780123"
            "abcd5678-1234-1234-1234-123456780123"
          ]
        },
        // Built-in Role Definition, referenced by ID
        {
            "roleDefinitionIdOrName": "/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11",
            "principalIds": [
                "12345678-1234-1234-1234-123456780123"
                "abcd5678-1234-1234-1234-123456780123"
            ]
        },
        // Custom Role Definition on Subscription scope
        {
            "roleDefinitionIdOrName": "/subscriptions/bbfef42b-7d75-4e17-9f39-bd431e69189f/providers/Microsoft.Authorization/roleDefinitions/54597af5-2126-5a52-a2ce-4bb56e90d3c8",
            "principalIds": [
                "12345678-1234-1234-1234-123456780123"
                "abcd5678-1234-1234-1234-123456780123"
            ]
        },
        // Custom Role Definition on Resource Group scope
        {
            "roleDefinitionIdOrName": "/subscriptions/bbfef42b-7d75-4e17-9f39-bd431e69189f/resourceGroups/rbacTest/providers/Microsoft.   Authorization/roleDefinitions/08e417aa-3d20-5a4e-94da-b2aa45bd5929",
            "principalIds": [
                "12345678-1234-1234-1234-123456780123"
                "abcd5678-1234-1234-1234-123456780123"
            ]
        }
    ]
}
```

## Outputs

| Output Name       | Type   | Description                                      |
| :---------------- | :----- | :----------------------------------------------- |
| `subscriptionId`  | string | The subscription Id of the created subscription. |
| `tags`            | object | The tags applied to the subscription.            |
| `roleAssignments` | array  | Array of role assignment objects.                |

## Considerations

This template is meant to **Tenant level deployment**, meaning the user/principal deploying it needs to have the [proper access](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-tenant#required-access)

> If owner access is too excessive, the following rights roles will grant enough rights:
> **Automation Job Operator** at management group **tenant** root level (scope '/') or at the target management group<br>.

A custom role can also be created for least scope/privilege with following permissions (scope 'targetManagementGroup'):
- `"Microsoft.Management/managementGroups/read"`
- `"Microsoft.Management/managementGroups/write"`
- `"Microsoft.Management/managementGroups/subscriptions/delete"` //disassociation not delete
- `"Microsoft.Management/managementGroups/subscriptions/write"`
- `"Microsoft.Resources/deployments/*"`

Scope: `"/providers/Microsoft.Management/managementGroups/<targetManagementGroup>"`

**Prerequisites**

In order to create a subscription via code, the following pre-requisites are necessary:

- the used enrollment account in the billing scope is active and created at least one subscription manually
- the used SPN used for the template deployment needs the following permissions
  - Owner permissions on the billing scope of the used EA enrollment account
  - (Owner permissions on the target management group (tenant root '/' not needed)) - only via MG scope deployments but needs to be validated

#Assign EA billing permission on Platform management SPN.
**Prerequisite:**

To allow a service principal to create subscriptions, access to an enrollment account that has a billing id associated is required!

([cfr. Wiki: Enterprise Agreement enrollment](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/495/Enterprise-Agreement-enrollment))

**Login and fetch access token**

Login with an enrollment account (e.g. with Login-AzAccount) and execute the following commands to fetch a valid access token for the account:

**Fetch the serviceprincipal you want to use:**
```
$spn = Get-AzADServicePrincipal -DisplayName <spnname>
$AccountId = "<Enrollment ID>"
```
**Provide the objectId of the service principal to grant access to enrolment account:** 
```
$spnObjectId = $spn.Id
```
**Fetching new token:**
```
$token = Get-AzAccessToken
```
**Request billing accounts that the identity has access to:**
```
$listOperations = @{
    Uri     = "https://management.azure.com/providers/Microsoft.Billing/billingaccounts?api-version=2020-05-01"
    Headers = @{
        Authorization  = "Bearer $($token.Token)"
        'Content-Type' = 'application/json'
    }
    Method  = 'GET'
}
$listBillingAccount = Invoke-RestMethod @listOperations

# List billing accounts
$listBillingAccount | ConvertTo-Json -Depth 100

#Select first billing account and the corresponding enrollment account
$billingAccount = $listBillingAccount.value[0].id
```
*Because the api doesn't react like described in the documentation, we need to create the enrollmentAccountId manually like below:*
```
$enrollmentAccountId = $billingAccount + "/enrollmentAccounts/$AccountId"
```

Multiple role definitions exists on an enrollment account. At the time of writing this documentation, the following role definitions exist:
| Role name                               | ID                                       |
| :-------------------------------------- | :--------------------------------------- |
| Enrollment account owner                | c15c22c0-9faf-424c-9b7e-bd91c06a240b     |
| Enrollment account subscription creator | **a0bcee42-bf30-4d1b-926a-48d21664ef71** |

Both role definitions have the Microsoft.Subscription/subscriptions/write permission required to create subscriptions. 

*Following the least privileged principle we recommend to use the _Enrollment account_ subscription creator for the Service Principal. (The one in bold)*

**Get billing roleDefinitions available at scope**
```
$listRbacObj = @{
    Uri = "https://management.azure.com/$($enrollmentAccountId)/billingRoleDefinitions?api-version=2019-10-01-preview"
    Headers = @{
        Authorization  = "Bearer $($token.Token)"
        'Content-Type' = 'application/json'
    }
    Method = "GET"
}
$listRbac = Invoke-WebRequest @listRbacObj
$listRbac.Content | ConvertFrom-Json | ConvertTo-Json -Depth 100
```

**Assign enrollment account subscription creator to the service principal**
 *(roledefinitonId (billingRoleDefinitions) has be equal to the role id of the "enrollment account subscription creator" role listed in the $listRbac.Content object)*
```
$roleAssignmentBody = @"
{
    "properties": {
        "principalId": "$($spnObjectId)",
        "roleDefinitionId": "$($enrollmentAccountId)/billingRoleDefinitions/a0bcee42-bf30-4d1b-926a-48d21664ef71"
      }
}
"@

# Generate new GUID for the role assignment
$rbacGuid = New-Guid

# Assign 'Enrollment account subscription creator' role to the SPN
 
$assignRbac = @{
    Uri = "https://management.azure.com/$($enrollmentAccountId)/billingRoleAssignments/$($rbacGuid)?api-version=2019-10-01-preview"
    Headers = @{
        Authorization  = "Bearer $($token.Token)"
        'Content-Type' = 'application/json'
    }
    Method = "PUT"
    Body = $roleAssignmentBody
    UseBasicParsing = $true
}
$assignedRbac = Invoke-RestMethod @assignRbac
```

[Link to original github: Enable subscription creation to a service principal](https://github.com/Azure/Enterprise-Scale/blob/main/docs/Deploy/enable-subscription-creation.md)

## Additional resources

- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)
- [Azure Resource Manager template reference](https://docs.microsoft.com/en-us/azure/templates/)
- [Deployments](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Resources/2019-10-01/deployments)
- [Aliases](https://docs.microsoft.com/en-us/azure/templates/Microsoft.Subscription/2020-09-01/aliases)
- [Programmatically create Azure subscriptions with preview APIs](https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/programmatically-create-subscription-preview)