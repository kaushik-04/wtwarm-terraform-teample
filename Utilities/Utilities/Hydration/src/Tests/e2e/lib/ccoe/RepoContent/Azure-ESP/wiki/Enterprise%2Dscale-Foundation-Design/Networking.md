After several discussions on the Network Architecture, contoso decided to implement a Foundation architecture without a Hub-Spoke model. 
As contoso prefers PaaS over IaaS services, and PaaS services will be published to the Internet using their Public IP address, a Hub-Spoke design is not preferable at this moment. 

The security requirements and limitations for each of the PaaS services will be included in development and documentation of the PaaS service (as a Certified Product) and will be controlled using Azure Policies to disallow incidental changes to the security requirements.
For the basic neworking deliverables of a Landing Zone, the CCoE will deliver a Virtual Network (vNet).

A virtual network (VNet) is a contoso managed network overlay in Azure Private. Azure resources such as virtual machines (VMs) and VNet injected resources like App Service Environment (ASE) that are part of the same virtual network can access each other. However, services outside a VNet have no way to identify or connect to services hosted within VNets, unless VNet Peering is configured. As already mentioned above, no inter connectivity between vNat is required using peering's.

If the Virtual networks must be geo-redundant, a VNet is always part of a single region. To achieve redundancy every VNet will be created in 2 regions and interconnected. 

The network product consist of the following resources and is described in [Virtual Network](/Product-Catalog/Virtual-Network):

- **Virtual network** 
- **Subnet** enables the segmentation of VNETs into one or more segments and allocate a portion of the VNET’s address space to each subnet. Azure resources can be deployed into specific subnets. Access to resources within subnets can be secured using Network Security Groups.
- **Network Security Groups** can filter and monitor network traffic to and from Azure resources in a VNET. An NSG contains security rules that allow or deny inbound network traffic to, or outbound network traffic from, Azure resources.
- **User Defined Routing**: Azure automatically creates a route table for each subnet within a VNET and adds system default routes to the table. Custom routes can be created to override Azure’s default system routes, or to add additional routes to a subnet’s route table.

- **Network Watcher** is a collection of tools to monitor, diagnose, view metrics, and enable or disable logs for resources in a VNET and is deployed with Vnet. 

The vNet requires a Log Analytics workspace to be in place. The Log Analytics workspace to be used is the central one. All available diagnostic settings are enabled.

All **Diagnostic settings** sent to centralized Log Analytics Workspace:

- **[Virtual Network](https://docs.microsoft.com/en-us/azure/network-watcher/network-watcher-monitoring-overview#diagnostics)**
  - VMProtectionAlerts
  - AllMetrics

- **Required parameters**:

|  |  **Description**| **Example** |
|--|--|--|
| **workload_id** | Workload code | wrlkdnm
| **env**  | Environment id character | l/d/t/p/g
| **tags** | A map of tags | ```tags = {scope = "core", tier = "integration", env = "dev",  workload = "spokeint",  owner = "CCoE-platform",  owneremail  = "ccoe_team@contoso.be",  customeremail   = "-",  costcenter      = "-"}```
| **resource_group_name** | Name of the resource group to deploy resources | rsg-wrlkdnm-weu1-p-001
| **region** | Region map describing where to deploy resources | ```region = { short_name = "weu1", name= "westeurope"}```
| **vnet_name** | VNET name| vnt-wrlkdnm-weu1-p-001
| **vnet_address_space** | VNET reserved address| ["10.1.0.0/16"]
| **create_network_watcher** | If set to true, it will deploy "NetworkWatcherRSG" resource group and a network watcher instance in the target region|  true -> NetworkWatcher_westeurope
| **storage_account_id** | The ID of the storage account for NSG Flow Logs | stawrlkdnmweu1p001
| **law_region** | The region where the centralized log analytics resiged. String. | westeurope
| **law_resource_id** | The Log Analytics resource ID | /subscriptions/525b1215-ac09-47ed-9612-a815458d7a72/resourcegroups/rsg-platform-weu1-l-002/providers/microsoft.operationalinsights/workspaces/law-platform-weu1-l-001
| **law_workspace_id** | The Log Analytics workspace ID | eb9ba1d4-0fd5-4e26-aa68-a15a8734008d
| **subnets** | Subnet Definition including: subnet_name, subnet_address_prefix, delegation, nsg_inbound_rules, nsg_outbound_rules, routes, enforce_private_link_endpoint_network_policies, enforce_private_link_service_network_policies | See below|

