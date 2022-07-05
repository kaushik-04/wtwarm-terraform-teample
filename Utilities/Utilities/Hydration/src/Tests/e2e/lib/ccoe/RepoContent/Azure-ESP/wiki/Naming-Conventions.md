# General Principles

- Names must avoid collisions between resources across different workloads
- Names must be predictable so that they can be used in the different processes
- Only lowercase alphanumeric characters for consistency
   - Lower case is required for some object names such as Storage, Containers, and Queues
   - Some object names, such as storage blobs, are case sensitive
- Avoid special characters as first or last character in any name. 
- Names should include semantic information, according to their scope. 
- Names are constructed of segments. 
- Hyphen will be used to separate segments. Hyphens will be omitted when not allowed (such as for storage accounts).

|  Hostplan               |  <client>-<platform-id>-<application-id>-<env>-<region>-hostplan                                                                                    |  pxs-pxbem-pxbemws-d-westeurope-hostplan                          |
|-------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| Management Group        | <client>-<deploy-zone>-mg for the top level building-blocks management groups                                                                       | pxs-cloudnative-mg, <br> pxs-management-mg                        |
|                         | <client>-<deploy-zone-abreviated>-<env-id>-mg for environment (child) management groups                                                             | pxs-cn-s-mg, <br> pxs-cn-n-mg, <br> pxs-cn-p-mg                   |
|                         | Deploy-zone = management (mgmt), cloudnative (cn); env-id = production (p), non-prod (n), sandbox (s)                                               |                                                                   |
| Subscription            | <client>-<deploy-zone-abbreviated>-<env-id>-<platform-id>-sub                                                                                       | pxs-cn-p-bdp-sub, <br> pxs-cn-s-ccoe-sub                          |
| Resource group          | <client>-<deploy-zone-abbreviated>-<env-id>-<platform-id>-<freetext>-rg                                                                             | pxs-cn-s-ccoe-networking-rg, <br> pxs-cn-p-bdp-appb-rg            |
| Key Vault          | <client>-<deploy-zone-abbreviated>-<env-id>-<platform-id>-<freetext>-kvt                                                                             | pxs-cn-s-ccoe-networking-kvt, <br> pxs-cn-p-bdp-appb-kvt            |
| Service Principal       | <client>-foundation-sp                                                                                                                              | pxs-bdp-n-sp                                                      |
|                         | <client>-<platform-ID>-<n/p>-sp                                                                                                                     |                                                                   |
|                         | <client>-<application-ID>-<n/p>-sp                                                                                                                  |                                                                   |
|                         | n = non-prod; p = prod                                                                                                                              |                                                                   |
| Policy Definition       | <client>-<deploy-zone-abbreviated>-<service>-<freetext>-pd                                                                             | pxs-cn-kvt-purge-pd                                                     |
| Policy Initiative       | <client>-<deploy-zone-abbreviated>-<service>(-<freetext>)-pi                                                                             | pxs-cn-kvt-pi, <br>pxs-cn-sub-security-pi                                                   |
| Policy Assignment       | <client>-<deploy-zone-abbreviated>-<env-id>-<platform-id>-<freetext>-pa                                                                             | pxs-cn-p-bdp-kvt-pa                                               |
| VM (Linux)              | <client>-<app-id>-l-<mod>-vm<number>                                                                                                                | pxs-myt-l-vm1                                                     |
|                         | Note: ‘l’ stands for Linux, ‘w’ for windows                                                                                                         | pxs-myt-l-vm99                                                    |
|                         | Note 1: the mod is optional                                                                                                                         | pxs-myt-l-decod-vm1                                               |
|                         | Note 2: the module is helpful for operations, can be put as tag as well and then be removed from the NC                                             | pxs-myt-l-decod-vm2                                               |
|                         |                                                                                                                                                     | pxs-myt-l-mongo-vm1                                               |
|                         |                                                                                                                                                     | pxs-myt-l- mongo -vm2                                             |
| VM (Windows)            | <client>-<appid>-w-vm<number>                                                                                                                       | pxs-myt-w-vm1                                                     |
|                         | Note: ‘l’ stands for Linux, ‘w’ for windows                                                                                                         | pxs-myt-w-vm2                                                     |
|                         | Note: mod has been omitted due to the maximum here is 15 characters for windows                                                                     | pxs-myt-w-vm123                                                   |
| OS Disk                 | <client>-<appid>-w-vm<number>-os                                                                                                                    | pxs-myt-w-vm1-os                                                  |
|                         | <client>-<appid>-l-vm<number>-os                                                                                                                    | pxs-myt-l-vm2-os                                                  |
|                         | based upon definition VM                                                                                                                            |                                                                   |
| Event Hub Namespace     | <client>-<appid>-<purpose>-ehn                                                                                                                      | pxs-azure-nonprod-ehn                                             |
| Data Disk               | <client>-<appid>-w-vm<number>-data<number>                                                                                                          | pxs-myt-w-vm1-data1                                               |
|                         | <client>-<appid>-l-vm<number>- data<number>                                                                                                         | pxs-myt-l-vm2-data2                                               |
|                         | based upon definition VM                                                                                                                            |                                                                   |
| Network Interface       | <client>-<appid>-w-vm<number>-nic<number>                                                                                                           | pxs-myt-w-vm1-nic1                                                |
|                         | <client>-<appid>-l-vm<number>- nic<number>                                                                                                          | pxs-myt-l-vm2-nic2                                                |
|                         |                                                                                                                                                     | pxs-myt-l-vm2-admin-nic1                                          |
|                         | Note. For admin interfaces, we use the prefix admin based upon definition VM                                                                        |                                                                   |
| Public IP               | <client>-<appid>-<env>-<mod>-pip<number>                                                                                                            | pxs-myt-p-decod-pip1                                              |
|                         | <client>-<appid>-<env>-pip<number>                                                                                                                  | pxs-myt-p-pip1                                                    |
|                         | Note: module is optional                                                                                                                            |                                                                   |
| Availability Set        | This will be replaced by zones.                                                                                                                     |                                                                   |
| VNET                    | <client>-<appid>-<env>vnet                                                                                                                          | pxs-myt-p-vnet                                                    |
|                         | <client>-<appid>-<env>-vnet<number>                                                                                                                 | pxs-myt-p-vnet1   pxs-myt-p-vnet2                                 |
| SubNet                  | <client>-<appid>-<env>-<use>-subnet                                                                                                                 | pxs-myt-p-admin-subnet                                            |
|                         | Note: the use groups together, e.g. frontend, backend, database                                                                                     | pxs-myt-p-frontend-subnet                                         |
| APIM                    | <client>-<appid>-<env>-<use>-apim                                                                                                                   | pxs-1in-p-invoice-apim                                            |
|                         | <client>-<appid>-<env>-apim<number>                                                                                                                 | pxs-1in-p-apim  pxs-1in-p-apim1                                   |
| LogicApp                | <client>-<appid>-<env>-<use>-logic                                                                                                                  | pxs-1in-p-invoice-logic                                           |
|                         | <client>-<appid>-<env>-<use>-logic<number>                                                                                                          | pxs-1in-p-logic1 pxs-1in-p-logic                                  |
| Network Security Group  | <client>-<appid>-<env>-<use>-nsg                                                                                                                    | pxs-1in-p-invoice-logicpxs-myt-p-decod-nsg                        |
|                         | Note: the use groups together, e.g. frontend, backend, database                                                                                     | pxs-myt-p-admin-nsg                                               |
| Load Balancer           | <client>-<appid>-<env>-<use>-lbl                                                                                                                    | pxs-myt-p-sense-lbl                                               |
|                         | Note: the use groups together, e.g. frontend, backend, database                                                                                     |                                                                   |
| Storage-Account         | <client><appid><env>sa<number>                                                                                                                      | pxsmytpsa                                                         |
|                         | Note : the number is optional                                                                                                                       | pxsmytpsa1                                                        |
| DB                      | <client>-<appid>-<env>-<DbIndicator>-db<number> <DbIndicator>: mssqm / mysql / mondodb db1, db2, …                                                  | pxs-myt-p-mysql-db1                                               |
| Azure Resources         |                                                                                                                                                     |                                                                   |
| Groups: CCoE            | grp-ccoe-<level>-<group>                                                                                                                            | grp-ccoe-root                                                     |
|                         | grp-ccoe-<level>-<group>-admin                                                                                                                      | grp-ccoe-root                                                     |
|                         | level: root/ cn (cloud native) / ce (cloud native). The root is only used for policy definitions and the azure zones were deployments are allowed   | grp-ccoe-cn-finops                                                |
|                         | group: devops/finops/secops                                                                                                                         | grp-ccoe-cn-fino                                                  |
|                         | For the admininistration tasks, the 'admin' suffix is added                                                                                         | grp-ccoe-cn-devops                                                |
|                         |                                                                                                                                                     | grp-ccoe-cn-devops-admin                                          |
|                         |                                                                                                                                                     | grp-ccoe-cn-secops                                                |
|                         |                                                                                                                                                     | grp-ccoe-cn-secops-admin                                          |
| Groups:                 | 2 sort of groups exist in this category:                                                                                                            | AD groups for Azure DevOps                                        |
| Cloud Native AD Groups  | AD Groups used for Azure DevOps                                                                                                                     | ·         grp-cn-bdp-build                                        |
|                         | grp-cn-<platform>-[build | team | release | admin]                                                                                                  | ·         grp-cn-bdp-team                                         |
|                         | AD Groups used for Azure Resources                                                                                                                  | ·         grp-cn-bdp-release                                      |
|                         | grp-cn-<platform>-<community>-<application>                                                                                                         | ·         grp-cn-bdp-admin                                        |
|                         | Communities are defined in 3 groups of people:                                                                                                      | AD groups for Azure Resources                                     |
|                         | ·         SD Software Developers (or Engineers)                                                                                                     | ·         grp-cn-bdp-sd-dwh                                       |
|                         | ·         AS Application Support                                                                                                                    | ·         grp-cn-bdp-as-dwh                                       |
|                         | ·         US End-Users                                                                                                                              | ·         grp-cn-bdp-us-dwh                                       |
|                         |                                                                                                                                                     | ·         grp-cn-bdp-sd-ppa                                       |
|                         |                                                                                                                                                     | ·         grp-cn-bdp-as-ppa                                       |
|                         |                                                                                                                                                     | More Azure resources groups examples: Azure AD Groups Definitions |
| Groups:                 | Out of scope but will follow similar naming convention.                                                                                             |                                                                   |
| Cloud Enables AD Groups | grp-ce-<platform>-<community>-<application>                                                                                                         |                                                                   |
| Groups:                 | grp-sb-<purpose>                                                                                                                                    | grp-sb-sentinel                                                   |
| Sandbox AD groups       |                                                                                                                                                     |                                                                   |


The denoted naming conventions are applicable for the different Azure zones. Azure zones can be:
- CN: cloud native
- CE: Cloud Enabled
- PG: Playground

Specific for the CCoE

| Component                | Syntax/Explanation                                                                             | Example                   |
|--------------------------|------------------------------------------------------------------------------------------------|---------------------------|
| Groups Generic           | grp-ccoe-<level>-<group>                                                                       |                           |
|                          | grp-ccoe-<level>-<group>-admin                                                                 |                           |
|                          | level: root (no abbreviation) / cn (cloud native) / ce (cloud native) / pg (playground).       |                           |
|                          | The root is only used for policy definitions and the azure zones were deployments are allowed. |                           |
|                          |                                                                                                |                           |
|                          | Groups: devops/finops/secops                                                                   |                           |
|                          | For the admininistration tasks, the 'admin' suffix is added                                    |                           |
|  CCOE Groups             | Overall administration group                                                                   | grp-ccoe-admin            |
|  CCOE DevOps Groups      |  DevOps related projects                                                                       | grp-ccoe-azure-admin      |
|                          |                                                                                                | grp-ccoe-azure-build      |
|                          |                                                                                                | grp-ccoe-azure-release    |
|                          |                                                                                                | grp-ccoe-azure-team       |
| Groups Cloud Enabled     |                                                                                                | grp-ccoe-cn-finops-admin  |
|                          |                                                                                                | grp-ccoe-cn-finops-reader |
|                          |                                                                                                | grp-ccoe-cn-secops-admin  |
|                          |                                                                                                | grp-ccoe-cn-secops-reader |
|                          |                                                                                                | grp-ccoe-cn-devops-admin  |
|                          |                                                                                                | grp-ccoe-cn-devops-reader |
| Groups Cloud Enabled     |                                                                                                | grp-ccoe-ce-finops-admin  |
|                          |                                                                                                | grp-ccoe-ce-finops-reader |
|                          |                                                                                                | grp-ccoe-ce-secops-admin  |
|                          |                                                                                                | grp-ccoe-ce-secops-reader |
|                          |                                                                                                | grp-ccoe-ce-reader        |
| Groups Cloud Playground  |                                                                                                |                           |
|  Other groups            | Tooling                                                                                        | grp-ccoe-tools            |
|                          | CDI                                                                                            | grp-cdi-team              |
