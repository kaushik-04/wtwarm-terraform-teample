- [SQL Server  1.0](#sql-server-10)
  - [Overview](#overview)
    - [Azure resource Description](#azure-resource-description)
    - [Release Notes](#release-notes)    
    - [Service Limits](#service-limits)
  - [Design](#design)
    - [Prerequisites](#prerequisites)
    - [RBAC](#rbac)
  - [Operations](#operations)
    - [Deployment](#deployment)
      - [Parameters](#parameters)
      - [Outputs](#outputs)
      - [Secrets](#secrets)
      - [YAML Pipeline deployment](#yaml-pipeline-deployment)
  - [Security Framework](#security-framework)
    - [Controls](#controls)
    - [Policies](#policies)

# SQL Server 1.0
## Overview
### Azure resource Description

The following Azure resource will be deployed in this Component :

+ [SQL Server](https://docs.microsoft.com/en-us/azure/azure-sql/database/logical-servers)

A logical SQL Server is required in order to create a database in Azure SQL Database, an elastic pool or a Synapse dedicated SQL pool.
The server is a logical construct that acts as a central administrative point for a collection of databases.

Some security settings can be configured at the server level meaning that all the databases attached to the server inherit those settings.

In this version of the Component, the SQL Server is deployed with the following characteristics :
+ [AAD administrator](https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-overview#administrator-structure)
+ [Allowed connections from Azure services](https://docs.microsoft.com/en-us/azure/azure-sql/database/firewall-configure#connections-from-inside-azure)
+ [Advanced Threat Protection](https://docs.microsoft.com/en-us/azure/azure-sql/database/threat-detection-overview)
+ [SQL Vulnerability Assessment](https://docs.microsoft.com/en-us/azure/azure-sql/database/sql-vulnerability-assessment)
+ [Auditing](https://docs.microsoft.com/en-us/azure/azure-sql/database/auditing-overview). Audit logs at server level are currently sent to a storage account (Log Analytics and Event Hub still in preview).

### Release Notes

**[2021.02.17]**

> + Initial version of SQL Server component.

### Service Limits

+ [Azure limits per subscription](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits)
+ [Azure limits for SQL Database and Synapse servers](https://docs.microsoft.com/en-us/azure/azure-sql/database/resource-limits-logical-server)

## Design

The design can be found in the [Product Catalogue](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/446/Product-Catalog) - [SQL Database](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/453/SQL-Database).

### Prerequisites

The following prerequisites need to be in place before this Component can be provisioned :
+ [Key Vault](../../keyvault). Also, a dedicated secret to store the administrator login password (parameter named 'administratorLogin'. Note this is a SQL user, not an AAD identity).
+ [Storage Account](../../storageaccount). Containers will be automatically created and access is granted at deployment time ('Blob Storage Account Contributor' role is assigned to the managed identity of the server).
Important note : hierarchical namespace for Azure Data Lake Storage Gen2 storage account is currently not supported.

### RBAC

## Operations

### Deployment

Deploys :
+ A "Microsoft.Sql/servers" resource.
+ A "Microsoft.Sql/servers/administrators" resource.
+ At least one "Microsoft.Sql/servers/firewallRules" resource. More rules can be passed by using the 'firewallRules' array.

#### Parameters

>   - **serverName**. Required. Name of the server.
>   - **resourceGroupName**. Required. Specifies the name of the resource group to deploy..
>   - **tags**. Required. Resource tags.
>   - **location**. Optional. Location of the server.
>   - **administratorLogin**. Optional. Administrator username for the server. Once created it cannot be changed.
>   - **administratorLoginPassword**. Required. The administrator login password (required for server creation). Should be provided as a Key Vault reference.
>   - **aadAdministratorLogin**. Required. AAD login name of the server administrator. Supports user / service principal or AAD group.
>   - **aadAdministratorSid**. Required. SID (object ID) of the server administrator.
>   - **enableIdentity**. Optional. Set this to false in order to NOT automatically create and assign an Azure Active Directory principal for the resource.
>   - **firewallRules**. Optional. Accepts an array of objects (one object per firewall rule).
>   - **removeUndocumentedFirewallRules**. Optional. Set this to false in order to NOT remove undocumented firewall rules.
>   - **storageAccountName**. Required. The storage account name for audit logs.
>   - **notificationRecipientsEmails**. Required. Email address(es) to receive Vulnerability Assessment scan reports.
>   - **azureADOnlyAuth**. Required. Set to true if you want to restrict authentication mechanism for SQL Server to Azure Active Directory only.

The following JSON serves as an example for the parameters :

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "serverName": {
            "value": "pxs-bdp-demo-s-sql-2"
        },
        "resourceGroupName": {
            "value": "validation-rg"
        },
        "tags": {
            "value": {
                "application-id": "demo",
                "cost-center": "demo",
                "deployment-id": "manual",
                "environment": "s",
                "platform-id": "bdp"
            }
        },        
        "administratorLogin": {
            "value": "sqlAdmin"
        },
        "administratorLoginPassword": {
            "reference": {
                "keyVault": {
                "id": "/subscriptions/b9bc4b81-2c1d-46bb-a1d6-6e0970f05f3c/resourceGroups/pxs-bdp-demo-rg-s-sql/providers/Microsoft.KeyVault/vaults/pxs-ccoe-demo-s-kv-sqlsa"
                },
                "secretName": "pxs-bdp-demo-s-sql-2-sa-pwd"
              }
        },
        "aadAdministratorLogin": {
            "value": "pxs-bdp-n-sp"
        },
        "aadAdministratorSid": {
            "value": "40dc163b-e2c9-49d0-bf51-b795188eb5cb"
        },
        "firewallRules": {
            "value": [
                { "ruleName": "firewallRule1", "startIpAddress": "85.26.47.19", "endIpAddress": "85.26.47.19"},
                { "ruleName": "firewallRule2", "startIpAddress": "85.26.47.20", "endIpAddress": "85.26.47.20"}                
            ]
        },
        "storageAccountName": {
            "value": "pxssqlstordemo03"
        },
        "notificationRecipientsEmails": {
            "value": [ "cedric.casoli@contoso.com" ]
        },
        "azureADOnlyAuth": {
            "value": false
        }   
    }    
}
```

#### Outputs

The following outputs are returned by the ARM template :
   - **sqlServerResourceId**. The Resource Id of the SQL Server.
   - **sqlServerResourceGroup**. The name of the Resource Group the SQL Server was created in.
   - **sqlServerName**. The Name of the SQL Server.

#### Secrets

No Secrets will be created during the provisioning for this version of the Component.
Note that you have to provide a secret as input paramater (administratorLoginPassword).

#### YAML Pipeline deployment

## Security Framework
### Controls
See Security Framework in article [Cloud Native Security](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/413/Cloud-Native-Security)

| Category | What | How |
| - | - | - | - 
| Azure Defender for SQL | Virus and malware protection | At subscription level -> delivered by Foundation Team
| Diagnostic Settings for SQL | Central monitoring of logs & metrics | At resource level -> [delivered by Foundation team](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2FpolicyDefinitions%2Fsecurity&version=GBmaster)

### Policies

The following Policies are in place

| Policy type | Policy Display Name | Policy description | Allowed values | Effect
| - | - | - | - | -
| custom | Azure SQL Database should have the minimal TLS version of 1.2. | Setting minimal TLS version to 1.2 improves security by ensuring your Azure SQL Database can only be accessed from clients using TLS 1.2. Using versions of TLS less than 1.2 is not recommended since they have well documented security vulnerabilities. | `"1.2"` | Deny
| custom | Azure SQL Server should only allow Azure Active Directory authentication. | This policy can be used to audit SQL Server's authentication mechanism. | `azureADOnlyAuthentications = true` | Audit
| built-in | An Azure Active Directory administrator should be provisioned for SQL servers. | Audit provisioning of an Azure Active Directory administrator for your SQL server to enable Azure AD authentication. Azure AD authentication enables simplified permission management and centralized identity management of database users and other Microsoft services. | `` | AuditIfNotExists
| built-in | Deploy Threat Detection on SQL servers. | This policy ensures that Threat Detection is enabled on SQL Servers. | `` | DeployIfNotExists
| built-in | Auditing on SQL server should be enabled. | Auditing on your SQL Server should be enabled to track database activities across all databases on the server and save them in an audit log. | `` | AuditIfNotExists
| built-in | Vulnerability Assessment settings for SQL server should contain an email address to receive scan reports. | Ensure that an email address is provided for the 'Send scan reports to' field in the Vulnerability Assessment settings. This email address receives scan result summary after a periodic scan runs on SQL servers. | `` | AuditIfNotExists