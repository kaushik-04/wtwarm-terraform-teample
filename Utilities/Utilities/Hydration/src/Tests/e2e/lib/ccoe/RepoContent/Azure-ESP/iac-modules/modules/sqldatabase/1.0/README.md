- [SQL Database  1.0](#sql-database-10)
  - [Overview](#overview)
    - [Azure resource Description](#azure-resource-description)
    - [Release Notes](#release-notes)
    - [Service Limits](#service-limits)
  - [Component Design](#component-design)
    - [Prerequisites](#prerequisites)
    - [RBAC](#rbac)
    - [Consumption endpoints (Data plane)](#consumption-endpoints-data-plane)
    - [Endpoint Authentication and Authorization](#endpoint-authentication-and-authorization)
  - [Operations](#operations)
    - [Deployment](#deployment)
      - [Parameters](#parameters)
      - [Outputs](#outputs)
      - [Secrets](#secrets)
      - [YAML Pipeline deployment](#yaml-pipeline-deployment)
  - [Security Framework](#security-framework)
    - [Controls](#controls)
    - [Policies](#policies)

# SQL Database 1.0
## Overview
### Azure resource Description

The following Azure resource will be deployed in this Component:

+ [SQL Database](https://docs.microsoft.com/en-us/azure/azure-sql/database/sql-database-paas-overview)

[Azure SQL Database](https://docs.microsoft.com/en-us/azure/azure-sql/database/sql-database-paas-overviewhttps://docs.microsoft.com/en-us/azure/key-vault/key-vault-overview) 
is a fully managed platform as a service (PaaS) database engine that handles most of the database management functions such as upgrading, patching, backups, and monitoring without user involvement. 
Azure SQL Database is running by default on the latest stable version of the SQL Server database engine and its PaaS features allows you to focus on the database administration tasks and optimization of critical business activities.

In this version of the Component, the SQL Database will be deployed with the following features:
+ A [SQL Database](https://docs.microsoft.com/en-us/azure/azure-sql/database/sql-database-paas-overview#deployment-models) deployed as single database of [GeneralPurpose tier](https://azure.microsoft.com/en-us/pricing/details/sql-database/single/)
+ [Backup short term retention policies](https://docs.microsoft.com/en-us/rest/api/sql/backupshorttermretentionpolicies/createorupdate) - This is how many days Point-in-Time Restore will be supported.
+ [Backup long term retention policies](https://docs.microsoft.com/en-us/azure/azure-sql/database/long-term-backup-retention-configure) (Optional) - define retention of database backups in separate Azure Blob storage containers for up to 10 years.
+ [Diagnostic Settings](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/diagnostic-settings) (Optional) - configure diagnostic settings to send logs and metrics about SQL Database usage to centralaized monitoring tools. Organisation wide Diagnistics Settings will be deployed via Remediative Policies ant management group levels by CCoE team. Module consumers can use this optional configuration to deploy additional settings.

### Release Notes

**[2021.02.16]**

> + Initial version of SQL Database component with the following parameters enabled: 
>   - **serverName**. Required. Name of the Azure SQL Server to which the database will be attached.
>   - **databaseName**. Required. Name of the Azure SQL Database.
>   - **location**. Optional. Location for the Azure SQL Database.
>   - **tags**. Required. Resource tags.
>   - **skuName**. "Optional. The name of the SKU, typically, a letter + Number code."
>   - **skuCapacity**. "Optional. Capacity of the particular SKU."
>   - **databaseMaxSize**. "Optional. The max size of the database expressed in bytes."
>   - **backupShortTermRetentionDays**. Optional. The backup retention period in days. This is how many days Point-in-Time Restore will be supported.
>   - **backupLongTermRetentionProperties**. Optional. Configuration of [long term retention policy object](https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/2017-03-01-preview/servers/databases/backuplongtermretentionpolicies). Expects key-value pairs with values in an ISO 8601 format.
>   - **diagnosticSettingsName**. Optional. Name of diagnostics settings.
>   - **diagnosticSettingsProperties**. Optional. Configuration of diagnostic settings (references to Event Hub, Log Analytics, logs & metrics). Expects a valid _Properties_ object as in [documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/samples/resource-manager-diagnostic-settings#diagnostic-setting-for-azure-sql-database).

### Service Limits

+ [Azure limits per subscription](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits)
+ [Azure SQL Database limits](https://docs.microsoft.com/en-us/azure/azure-sql/database/resource-limits-logical-server)


## Component DesignDesign

The Design can be found in the [Product Catalogue](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/446/Product-Catalog) - [SQL Database](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/453/SQL-Database)

### Prerequisites

The following prerequisites need to be in place before this Component can be provisioned:

+ Mandatory [Azure SQL Server](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fsqlserver&version=GBmaster) needs to be provisioned.
+ Optional [Azure Event Hub Namespace](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Feventhub&version=GBmaster) and [Azure Event Hub Instance](../../eventhubInstance) need to be provisioned, as well as an access policy defined at namespace level granting "manage|send|listen" permission. Moreover, the identity deploying the datbase needs the permission "Microsoft.EventHub/namespaces/authorizationrules/listkeys/action" over the target Event Hub namespace.
+ Optional [Log Analytics workspace](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Floganalytics&version=GBmaster) needs to be provisioned. Moreover, the identity deploying the datbase needs the permission "Microsoft.OperationalInsights/workspaces/sharedKeys/action" over the target workspace.

### RBAC

For SQL Databases we do not use RBACs to manage access. By Default consumers should get "Reader" role just to be able to confirm that the resource exists. Any access to SQL Databases is done in SQL via Groups & Roles.

## Operations

### Deployment

Deploys a "Microsoft.Sql/servers/databases" resource.

This ARM template is only applicable to Azure Sql Database resources, we use a separate one for Synapse databases (even if they have the same resource type).

#### Parameters
The following JSON serves as an example for the parameters

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "serverName": {
            "value": "pxs-bdp-demo-s-sql-2"
        },
        "databaseName": {
            "value": "sqldb-demo-s"
        },
        "location": {
            "value": "West Europe"
        },
        "tags": {
            "value": {
                "application-id": "azure",
                "cost-center": "azure",
                "deployment-id": "test",
                "environment": "s",
                "platform-id": "ccoe"
            }
        },
        "skuName": {
            "value": "GP_Gen5"
        },
        "skuCapacity": {
            "value": 2
        },
        "databaseMaxSize": {
            "value": 1073741824
        },
        "backupShortTermRetentionDays": {
            "value": 30
        },
        "backupLongTermRetentionProperties": {
            "value": {
                "weeklyRetention": "PT0S",
                "monthlyRetention": "P6W",
                "yearlyRetention": "P55W",
                "weekOfYear": 1
            }
        },
        "diagnosticSettingsName": {
            "value": "DiagnosticSettingsEventHub-Workspace-Demo"
        },
        "diagnosticSettingsProperties": {
            "value": {
                "workspaceId": "/subscriptions/e443f3cb-683d-4e36-a7e4-aee6c26dfaba/resourceGroups/pxs-bdp-demo-rg-s-sql/providers/microsoft.operationalinsights/workspaces/pxs-bdp-demo-s-law0",
                "eventHubAuthorizationRuleId": "/subscriptions/e443f3cb-683d-4e36-a7e4-aee6c26dfaba/resourceGroups/pxs-bdp-demo-rg-s-sql/providers/Microsoft.EventHub/namespaces/pxs-bdp-demo-s-evhns-1/authorizationrules/RootManageSharedAccessKey",
                "eventHubName": "sqldb-diagnosticlogs-demo",
                "logs": [
                    {
                      "category": "SQLInsights",
                      "enabled": true
                    },
                    {
                      "category": "AutomaticTuning",
                      "enabled": true
                    },
                    {
                      "category": "QueryStoreRuntimeStatistics",
                      "enabled": true
                    },
                    {
                      "category": "QueryStoreWaitStatistics",
                      "enabled": true
                    },
                    {
                      "category": "Errors",
                      "enabled": true
                    },
                    {
                      "category": "DatabaseWaitStatistics",
                      "enabled": true
                    },
                    {
                      "category": "Timeouts",
                      "enabled": true
                    },
                    {
                      "category": "Blocks",
                      "enabled": true
                    },
                    {
                      "category": "Deadlocks",
                      "enabled": true
                    }
                  ],
                  "metrics": [
                    {
                      "category": "Basic",
                      "enabled": true
                    },
                    {
                      "category": "InstanceAndAppAdvanced",
                      "enabled": true
                    },
                    {
                      "category": "WorkloadManagement",
                      "enabled": true
                    }
                  ]
            }
        }
    }
}
```

#### Outputs
The following outputs are returned by the ARM template:
   - **sqlDatabaseResourceId**. The Resource Id of the SQL Database.
   - **sqlDatabaseResourceGroup**. The name of the Resource Group the SQL Database was created in.
   - **sqlDatabaseName**. The Name of the SQL Database.

#### Secrets

No Secrets will be created during the provisioning for this version of the Component

#### YAML Pipeline deployment

The following [YAML pipeline stage](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/stages?view=azure-devops&tabs=yaml) can be used as a reference to deploy the Key Vault:

```yml
- stage: sqlDatabaseDeployment
  jobs:
  - template: /cicd/templates/pipeline.jobs.deploy.yml@IaC
    parameters:
      moduleName: sqldatabase
      moduleVersion: '1.0'
      displayName: Deploy_sqlDatabase
      deploymentBlocks:
      - path: {path_to_configuration_file}
      checkoutRepositories:
      - IaC
```

## Security Framework
### Controls
See Security Framework in article [Cloud Native Security](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/413/Cloud-Native-Security)

| Category | What | How |
| - | - | - | - | -
| Azure Defender for SQL | Virus and malware protection | At subscription level -> delivered by Foundation Team
| Diagnostic Settings for SQL | Central monitoring of logs & metrics | At resource level -> [delivered by Foundation team](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2FpolicyDefinitions%2Fsecurity&version=GBmaster)

### Policies

The following Policies are in place (see article [Foundation Design](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/410/Foundation-Design) > [Governance](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/496/Governance) in Wiki to learn more about Policies)

| Policy type | Policy Display Name | Policy description | Allowed values | Effect
| - | - | - | - | -
| custom | Restrict allowed SKUs for SQL Database | This policy restricts the SKUs you can specify when deploying Azure SQL Databases. | `"GP_Gen5"` | Audit
| built-in | Long-term geo-redundant backup should be enabled for Azure SQL Databases | This policy audits any Azure SQL Database with long-term geo-redundant backup not enabled. | n/a | AuditIfNotExists
 built-in | Deploy SQL DB transparent data encryption | Enables transparent data encryption on SQL databases. | n/a | DeployIfNotExists(1)

(1) This effect is equivalent to `Audit` when the resource already exists and no remediation task is created!