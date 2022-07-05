# Virtual Network 1.0

| **Status**    | <span style="color:orange">** DRAFT**</span> |
|-----------|---------------|
| **Version**   | v0.5         |
| **Edited By** | Frederik De Ryck |
| **Date**      | 04/02/2021     |
| **Approvers** | Dante Vanoplynus<br>Jonas De Troy              |
| **Deployment documentation** | [Virtual Network 1.0 Implementation Details](https://dev.azure.com/contoso-azure/building-blocks/_git/IaC?path=%2Fmodules%2Fvirtual-network%2F1.0%2FREADME.md&_a=preview) |
| **To Do**     | -  update deployment and implementation documentation <br> - develop dynamic NSG and rules for policies <br> - design some measures and create the policies <br> - depending the central logging development (deployIfNotExist policies) <br> - prepare and test multi module artifact|
|||
[[_TOC_]]

## 1. Introduction

### 1.1. Service Description

[Azure Virtual Network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)  is a cloud service that allows you to create a vnet(Virtual Network). Within a vnet resources are able to communicate with each other. Azure Networks are userd for:

- Communication to and from the internet
- Communication between Azure resources
- filtering network traffic
- routing traffic
 
In this version of the Certified Service, the Azure Virtual Network will be deployed with the following features:

- A free of charge [Virtual Network](https://azure.microsoft.com/en-us/pricing/details/virtual-network/).

- The virtual network will have a private address space as defined in (RFC 1918). It will be having at least 3 subnets, one reserved for gateway's, one for frontend and another for backend components.
- Each subnet should have a [Network Security Group](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview#network-security-groups) (NSG) in place for filtering. 
    NSG's should allow inbound and outbound to these services: 
- The vnet should have a routing table attached to it.

- Permission model for Azure Virtual Network is based on the RBAC rights:
- monitoring the network and changes to and on that network is key to the security posture, therefore we need:
    - the enablement of the network watcher capabilities and network map
    - the enablement of flow logs 
    - components logs to be collected and forwarded 

It will not: 
- have any public IP adresses linked to resources directly 
- have a public available component that is not a firewall of some kind
- be limited in subnetting or other flexibility constraints
  
## 2. Architecture

### 2.1. High Level Design

The following figure describes the overall architecture for this service:

<IMAGE TOBE UPDATED>
<span style="color:orange">**Image To Be Updated**</span>
![image.png](TBD)


### 2.2. Role Based Access Control (RBAC) 

Changes to networks - create, update, remove - are not supposed to be happening without infrastructure as code (IaC) therefore no human access to the management plane of networks is required.

RBAC Permission model provides the following roles: 

| **Built-in role**                        | **Description**          | **Accounts**|
|----|----------------------|----|
| Network Contributor              | Lets you manage networks, but not access to them. |  will not be granted  |


The following links in the Azure documentation give more information about Virtual Networks:

- [Azure Virtual Network service integrations](https://docs.microsoft.com/en-us/azure/virtual-network/vnet-integration-for-azure-services)

- [Azure Virtual Network Security control](https://docs.microsoft.com/en-us/azure/security/benchmarks/security-control-network-security)

- [Azure Virtual Network Security Baseline](https://docs.microsoft.com/en-us/azure/virtual-network/security-baseline)

- [Azure Virtual Network - NSG](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview#network-security-groups)

- [Azure Virtual network - best practices](https://docs.microsoft.com/en-us/azure/virtual-network/concepts-and-best-practices)

#### 2.2.1. DNS (Domain Name service) Server

DNS is of importance for systems in order to be able to communicate to each other.The service will be deployed using azure provided DNS service. 


#### 2.2.2. NSG (Network Security Groups)
An NSG needs to be in place for every subnet and should be configured based on the architecture in place. Rules should be known up front, service tags can be used. This product enforces you to have an NSG in place and will watch closely that some rules of the NSG stay in place. (Cfr. management inbound protocols)

#### 2.2.3. UDR (User Defined Routing)
The Route table should be present.

### 2.3 Management Plane 
RBAC for the Management Plane will be provided via the built-in role when creating a Virtual Network: [Network Contributor](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)

 ### 2.4. Service Limits

Following are the limits per subscriptions and per product:

- [Azure limits per subscription](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits)

- [Azure Virtual Network limits](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview#azure-vnet-limits)

 
## 3. Service Provisioning
In this chapter we discribe the details for the deployment of the service.

### 3.1. Prerequisites

The following Azure resources need to be in place before this Certified Service can be provisioned:

- Subscription
- Resource Group
- Central Log Analytics Workspace (See CN-SR-12)
- central Event Hub (see CN-SR-12)
- Central storage account (see CN-SR-12)

### 3.2 Deployment parameters

All Parameters indicated with Fixed will not be included as an option during deployment and will be set as default parameter:

|**Parameter**|**Prod**|**Non-Prod**| **Implementation** | **Implementation Status** |
|--|--|--|--|--|
|**Subscription**|N/A|N/A| <span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span>
|**Resource Group**|N/A|N/A|<span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span>
|**Name**|pxs-cn-p-<'platform>-<'name>-vnet<br>Enforced by Policy|pxs-cn-<'environment>-<'platform>-<'name>-vnet<br>Enforced by Policy|<span style="color:green">**PARAMETER to be enforced by policy**</span>|<span style="color:red">**To Be IMPLEMENTED<br>by Policy**</span>
|**Region**|West/North EU <br>Enforced by Policy|West/North EU <br>Enforced by Policy|<span style="color:green">**Policy on root**</span>|<span style="color:green">**IMPLEMENTED<br>Policy on root**</span>
|**vnetAddressPrefix**|CIDR block|CIDR block|<span style="color:green">**PARAMETER**</span>|<span style="color:green">**IMPLEMENTED**</span>
|**subnet1Prefix**|CIDR block|CIDR block |<span style="color:green">**PARAMETER**</span>|<span style="color:green">**IMPLEMENTED**</span>
|**Network Security Group (NSG)**|securityRules for inbound (Telnet, FTP, SSH, RDP,...) <br>Enforced by Policy|see prod <br>Enforced by Policy|<span style="color:green">**POLICIES**</span>|<span style="color:red">**PARTIALLY IMPLEMENTED<br>by Policy**</span>
|**Network Security Group (NSG)**|securityRules for outbound(HTTPS only)<br>Enforced by Policy|see prod <br>Enforced by Policy|<span style="color:green">**POLICIES**</span>|<span style="color:red">**TO BE IMPLEMENTED<br>by Policy**</span>
|**routeTable**|Optional<br>|Optional <br>|<span style="color:green">**PARAMETER**</span>|<span style="color:red">**Option not present<br>**</span>
|**EnableDdosProtection**|true (plan) <br>optional|true (plan)  <br>Optional|<span style="color:green">**PARAMETER**</span>|<span style="color:red">**partially implemented<br>**</span>
|**EnableVmProtection**|true <br>Optional|true  <br>Optional|<span style="color:green">**PARAMETER**</span>|<span style="color:red">**partially implemented<br>**</span>
|

Legenda:
- Fixed: The parameter will be hardcoded in the ARM template
- Enforced by policy: There will be a policy created to manage the parameter changes after deployment
- Cannot be changed after deployment: The parameter will be unchangeable after deployment.

## 4. Service Management for Virtual Network (TBD)

All product-specific MSMCF controls - for the current product version - can be found on the table below:

 

| **MSM Code** | **Functional Control Description** | **Product Assessment Q&A** | **Validated** | **Implementation** | **Status** |
|----------|----------------------------------------------------------------------------------------------------------------------------|------------------------|------------------------|------------------------|----|----|
| **M-STD01** | Health alerts are automatically generated, correlated and managed based on event monitoring.                            |   - Health alerts are automatically triggered by Azure. <br> - No product specific health alerting or dashboard/report requirements. <br> - Guidance for DevOps teams about monitoring best practices to be documented on the wiki product description. (e.g. B[asic Virtual Network metrics to monitor](https://docs.microsoft.com/en-us/azure/key-vault/general/alert#basic-key-vault-metrics-to-monitor) )<br><br>       |      Yes     |   - This control is applied by defining Resource Health Alerts on a subscription level, therefore provided for all certified products/platforms. <br> <br> - Additional resource monitoring is under the responsibility of each workload DevOps team.  <br> <br>           |  <span style="color:red">**TO BE IMPLEMTED**</span>   |

 

## 5. Security Controls for Virtual Network (TBS)

Microsoft Virtual Network best practices: 
All product-specific security controls - for the current product version - can be found on the table below:

| Index    | Security Requirement                                                                                 | Relevance                                                                                                                                                                                                                                         | Implementation details                                                                         | Policy Enforced / Audit | Design Status                                      |Implementation Status                                      |
|----------|------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|-------------------------|---------------------------------------------|---------------------------------------------|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later).                      | very relevant for all (in and outbound) flows.  <BR>__                                                                                                                                                                                   |  NA                                                                                             |  NA                  | <span style="color:green">**DRAFT**</span>  | <span style="color:green">**not defined how to enforce**</span>
| CN-SR-09 | Follow the principle of least privilege.                                                             | [RBAC access control](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles). A list of Service Principals object Ids can be provided as input to give them the role definition of 'network contributor'  |  no implementation on RBAC identified   |    N/A                 | <span style="color:green">**TBD**</span>  |<span style="color:red">**not defined**</span> 
| CN-SR-10 | Configure security log storage retention.                                                            | Log Analytics retention is configured on the LAW product itself. More information: https://docs.microsoft.com/en-us/azure/key-vault/key-vault-logging                                  |  NA                                                                                 | NA| <span style="color:green">**TBD**</span>  | <span style="color:green">**partially IMPLEMENTED**</span> 
| CN-SR-11 | Enable alerts for anomalous activity.                                                                | Maps, adaptive hardening and threat protection in Azure Security Center needs to be enforced using Defender for Virtual Network. https://docs.microsoft.com/en-us/azure/security-center/security-center-network-recommendations                                                                             |  Custom Policy                                                                                 |  Audit                  | <span style="color:green">**FINAL**</span>  | <span style="color:red">**TO BE IMPLEMENTED**</span>  
| CN-SR-12 | Configure central security log management.                                                           | Security logging needs to be implemented (enforced). Logging will be implemented using an eventHub. More information: https://docs.microsoft.com/en-us/azure/key-vault/general/howto-logging                                                                                                     | ARM template to send logs and metrics to the eventHub<br>Custom Policy<br>(Audit/DeployIfNotExists)                                                                                |  Audit                  | <span style="color:green">**TBD**</span>  |<span style="color:red">**TO BE IMPLEMENTED**</span>
| CN-SR-13 | Enable audit logging of Azure Resources.                                                            | Enable (enforce) diagnostic logs on the service to the Central Log Analytics Workspace and eventHub.<br>https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log and flow logs via: <br>                                                                                                                                                                                                  |  Custom Policy (Audit/DeployIfNotExists)                                                                                   |  Enforced | <span style="color:green">**TBD**</span>  | <span style="color:red">**TO BE IMPLEMENTED**</span> 
| CN-SR-14 | Enable MFA and conditional access with MFA.                                                          | Not applicable. Inherited from Azure AD                                                                                                                                                                                                                                  |  NA                                                                                            |  NA (inherited)                    | <span style="color:green">**TBD**</span>  |<span style="color:grey">**N/A**</span> 
| CN-SR-15 | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network.     | Not directly applicable. Needs to be implemented on NSG/Azure Firewall level.Access only for the LZ resources                                                                                                                                     |  NA                                                                                            |  NA                     | <span style="color:green">**TBD**</span>  |<span style="color:red">**TO BE IMPLEMENTED**</span>
| CN-SR-17 | Secure outbound communication to the internet.                                                       | Not applicable.      |  NA     |  NA                     | <span style="color:green">**TBD**</span>  | <span style="color:red">**TO BE IMPLEMENTED**</span>
| CN-SR-18 | Enable JIT network access.                                                         | Not applicable. |  NA |  NA | <span style="color:green">**TBD**</span>  | <span style="color:red">**TO BE IMPLEMENTED**</span>
| CN-SR-19 | Run automated vulnerability scanning tools.                                        | Not applicable. |  NA |  NA | <span style="color:green">**TBD**</span>  | <span style="color:grey">**N/A**</span>
| CN-SR-20 | Use automated tools to monitor network resource configurations and detect changes. | Not applicable. |  NA |  NA | <span style="color:green">**TBD**</span>  | <span style="color:red">**TO BE IMPLEMENTED**</span>
| CN-SR-21 | Disable remote user access ports (RDP,SSH,Telnet,FTP).                             | Not applicable. |  NA |  NA | <span style="color:green">**TBD**</span>  |<span style="color:red">**PARTIALLY IMPLEMENTED**</span>
| CN-SR-25 | Configure firewall rules of existing firewalls if necessary.                       | Firewall needs to be deployed first  |  NA   |  NA  | <span style="color:green">**TBD**</span>  |<span style="color:green">**TBD**</span>
| CN-SR-27 | Enable conditional access control.                                                 | Not applicable (only Service principal has access to AKV).  |  NA |  NA  | <span style="color:green">**TBD**</span>  |<span style="color:grey">**N/A**</span>  
| CN-SR-28 | Specify service tags to define network access controls on network security groups or Azure Firewall. | We have tags defined in the ARM template.  |  Not Embeded in the ARM template yet |    NA   | <span style="color:green">**TBD**</span>  | <span style="color:red">**to be IMPLEMENTED**</span>
| CN-SR-29 | Use Corporate Active Directory Credentials.         | Azure AD is the authentication mechanism, if AAD is synchronized with Corporate Active Directory then this requirement is compliant.|  NA  |  NA | <span style="color:green">**TBD**</span>  |<span style="color:grey">**N/A**</span>

<br>
<br>
<br>
<br>
<br>
<br>
<br>
<br>
Todo - add in security baseline:
- enable NSG Flows
- Deny communication with known-malicious IP addresses (Ddos, azure firewall, threat protection SC, adaptive network hardening in SC)
- Deploy IDS/IPS
- 

Build in policies to be added:
- All Internet traffic should be routed via your deployed Azure Firewall
- Deploy a flow log resource with target network security group
- Deploy network watcher when virtual networks are created
- Flow log should be configured for every network security group
- Network Watcher should be enabled
- RDP access from the Internet should be blocked
- SSH access from the Internet should be blocked
- TBD: Virtual networks should use specified virtual network gateway