- [SQL Synapse  1.0](#sql-synapse-10)
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

# SQL Synapse 1.0
## Overview
### Azure resource Description

The following Azure resource will be deployed in this Component :

+ [Synapse dedicated SQL pool](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/overview-architecture)

Azure Synapse Analytics is an analytics service that brings together enterprise data warehousing and Big Data analytics. Dedicated SQL pool (formerly SQL DW) refers to the enterprise data warehousing features that are available in Azure Synapse Analytics.

Most security settings are configured at [server-level](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fsqlserver&version=GBmaster) meaning that all the databases attached to the server inherit those settings, including a Synapse dedicated SQL pool (a Synapse dedicated SQL pool can be thought as a special type of SQL database in Azure and, as such, is also linked to a server).

In this version of the Component, the Synapse dedicated SQL pool is deployed with the following characteristics :
+ [Transparent data encryption (TDE)](https://docs.microsoft.com/en-us/azure/azure-sql/database/transparent-data-encryption-tde-overview)
+ [Diagnostic Settings](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/diagnostic-settings) (Optional) - configure diagnostic settings to send logs and metrics about Synapse dedicated SQL pool usage to centralized monitoring tools. Organisation wide diagnostics settings will be deployed via remediative policies ant management group levels by CCoE team. Module consumers can use this optional configuration to deploy additional settings and / or send logs to yet another location.

### Release Notes

**[2021.02.24]**

> + Initial version of SQL Synapse component.

### Service Limits

+ [Azure limits per subscription](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits)
+ [Azure limits for dedicated SQL pools in Azure Synapse Analytics](https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-service-capacity-limits)

## Design

The design can be found in the [Product Catalogue](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/446/Product-Catalog) - [SQL Synapse](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/455/Azure-Synapse).

### Prerequisites

The following prerequisites need to be in place before this Component can be provisioned :
+ [Azure SQL Server](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fsqlserver&version=GBmaster) needs to be provisioned.

### RBAC

For Synapse dedicated SQL pools, we do not use RBACs to manage access to the data plane. By default, consumers should get "Reader" role just to be able to confirm that the resource exists. Access management in Synapse dedicated SQL pools is done via AAD groups & database roles.

## Operations

### Deployment

Deploys a "Microsoft.Sql/servers/databases" resource.

The ARM template behind this Component is only applicable to Synapse dedicated SQL pools, we use a separate one for Azure SQL databases (even if they share the same resource type).

#### Parameters

>   - **serverName**. Required. Name of the Azure SQL Server to which the Synapse dedicated SQL pool will be attached.
>   - **databaseName**. Required. Name of the Synapse dedicated SQL pool.
>   - **tags**. Required. Resource tags.
>   - **location**. Optional. Location for the Synapse dedicated SQL pool.
>   - **skuCapacity**. Optional. Capacity of the Synapse dedicated SQL pool (size of compute). To determine the available capacities in the target region, use the following command : Get-AzSqlServerServiceObjective -Location "West Europe".
>   - **diagnosticSettingsName**. Optional. Name of diagnostics settings.
>   - **diagnosticSettingsProperties**. Optional. Configuration of diagnostics settings (references to Event Hub, Log Analytics, logs & metrics).

The following JSON serves as an example for the parameters :

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "serverName": {
            "value": "pxs-bdp-demo-s-sql-2"
        },
        "databaseName": {
            "value": "sqlsyn-demo-s"
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
        "location": {
            "value": "West Europe"
        },
        "skuCapacity": {
            "value": 900
        },
        "diagnosticSettingsName": {
            "value": "DiagnosticSettingsEventHub-Workspace-Demo"
        },
        "diagnosticSettingsProperties": {
            "value": {
                "eventHubAuthorizationRuleId": "/subscriptions/b9bc4b81-2c1d-46bb-a1d6-6e0970f05f3c/resourceGroups/pxs-bdp-demo-rg-s-sql/providers/Microsoft.EventHub/namespaces/pxs-ccoe-demo-s-evhns-1/authorizationrules/RootManageSharedAccessKey",
                "eventHubName": "sqldb-diagnosticlogs-demo",
                "logs": [
                    {
                      "category": "DmsWorkers",
                      "enabled": true
                    },
                    {
                      "category": "ExecRequests",
                      "enabled": true
                    },
                    {
                      "category": "RequestSteps",
                      "enabled": true
                    },
                    {
                      "category": "SqlRequests",
                      "enabled": true
                    },
                    {
                      "category": "Waits",
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

The following outputs are returned by the ARM template :
   - **sqlDatabaseResourceId**. The Resource Id of the Synapse dedicated SQL pool.
   - **sqlDatabaseResourceGroup**. The name of the Resource Group the Synapse dedicated SQL pool was created in.
   - **sqlDatabaseName**. The name of the Synapse dedicated SQL pool.

#### Secrets

No Secrets will be created during the provisioning for this version of the Component.

#### YAML Pipeline deployment

## Security Framework
### Controls
See Security Framework in article [Cloud Native Security](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/413/Cloud-Native-Security).

| Category | What | How |
| - | - | - | - 
| Azure Defender for SQL | Virus and malware protection | At subscription level -> delivered by Foundation Team
| Diagnostic Settings for SQL | Central monitoring of logs & metrics | At resource level -> [delivered by Foundation team](https://dev.azure.com/contoso-azure/building-blocks/_git/Platform?path=%2Fpxs-cloudnative-mg%2Fparameters%2FpolicyDefinitions%2Fsecurity&version=GBmaster)

### Policies

The following policies are in place (see article [Foundation Design](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/410/Foundation-Design) > [Governance](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/496/Governance) in Wiki to learn more about policies).

| Policy type | Policy Display Name | Policy description | Allowed values | Effect
| - | - | - | - | -
| custom | Restrict allowed SKUs for Synapse dedicated SQL pool | This policy restricts the SKUs you can specify when deploying Synapse dedicated SQL pools. | list of valid SKUs for DataWarehouse tier (e.g. 'DW500c') | Audit
built-in | Deploy SQL DB transparent data encryption | Enables transparent data encryption on SQL databases. | n/a | DeployIfNotExists(1)

(1) This effect is equivalent to `Audit` when the resource already exists and no remediation task is created !