<!-- 
Links:     
    https://docs.microsoft.com/en-us/azure/azure-maps/choose-pricing-tier
	rotate secret for resources
	https://docs.microsoft.com/en-us/azure/key-vault/secrets/tutorial-rotation-dual
	https://docs.microsoft.com/en-us/azure/azure-maps/azure-maps-authentication


 -->
# Azure Maps 1.0

| **Status** | <span style="color:orange">**DRAFT**</span> |
|--|--|
| **Version** | v0.1 |
| **Edited By** | Michaël Tonneau-Midol |
| **Date** | 10/01/2021  |
| **Approvers** | Frederik DE RYCK <br> Jonas DE TROY |
| **Deployment documentation** | <link to GIT Module missing> |
| **To Do** |  |

[[_TOC_]]

## 1. Introduction
### 1.1. Service Description
Azure Maps is a collection of multiple geospatial services and SDKs that Developers can use to provide geographic context to web and mobile applications supported by fresh mapping data. Azure Maps provides:
+ REST APIs to render vector and raster maps in multiple styles and satellite imagery.
+ Creator services (Preview) to create and render maps based on private indoor map data.
+ Search services to locate addresses, places, and points of interest around the world.
+ Various routing options; such as point-to-point, multipoint, multipoint optimization, isochrone, electric vehicle, commercial vehicle, traffic influenced, and matrix routing.
+ Traffic flow view and incidents view, for applications that require real-time traffic information.
+ Mobility services (Preview) to request public transit information, plan routes by blending different travel modes and real-time arrivals.
+ Time zone and Geolocation (Preview) services.
+ Elevation services (Preview) with Digital Elevation Model
+ Geofencing service and mapping data storage, with location information hosted in Azure.
+ Location intelligence through geospatial analytics.
## 2. Architecture
### 2.1. High Level Design
The following figure describes the overall Azure Maps architecture:

![Architure](/.attachments/azuremaps_architecture.jpg)
#### 2.1.1. Azure Maps Services
**Azure Maps** provides the following services:
+ **Search:** Create apps that provide details about nearby points of interest (POI), render locations on a map, and geocode (or reverse geocode) addresses to get corresponding latitude/longitude coordinates.
+ **Traffic:** Develop mobility solutions that improve travel time and avoid gridlock. Offer multiple alternate routes around traffic jams, insight into the length of the backup and the time it takes to get through it, and a faster travel experience during rush hour.
+ **Maps:** Integrate clear, easy-to-read maps into your solutions with the JavaScript Map Control or the Render API. The maps update dynamically, so your customers get constantly refreshed information. Build web and mobile apps with web and Android SDKs.
+ **Routing:** Present the shortest or fastest routes available—to multiple destinations at a time—or provide specialized routes and facts for walkers, bicyclists, and commercial vehicles. Optimize route calculations with isochrones, matrix routing, and batch routing.
+ **Time zones:** Make it easy for users to see what time it is anywhere in the world. Select a location to find the time zone, its offset to Coordinated Universal Time (UTC), and daylight saving time updates.
+ **Spatial operations:** Enhance your location intelligence with a library of common geospatial mathematical calculations, including geofencing, closest point, great circle distance, and buffers.
+ **Geolocation:** Look up the country of an IP address. Customize content and services based on user location and gain insight on customer geographic distribution.
+ **Elevation Preview:** Lookup elevation data for locations anywhere on the surface of the Earth. Create valuable data products and apps that utilize globally consistent digital terrain model datasets served through Azure Maps APIs.
+ **Data Service:** Upload and store geospatial data for use with spatial operations or image composition to reduce latency, increase productivity, and enable new scenarios within your applications.
+ **Mobility:** Provide real-time location intelligence on nearby public transit services, including stops, route information, and travel time estimations.
+ **Weather Service:** Obtain current weather conditions, weather forecast, and weather along a route to enable weather based decisions within your applications.
+ **Creator:** Create and publish your maps maintaining control of design, distribution, scale and access by converting various mapping file formats to be used in conjunction with Azure Maps and other Azure services.

| ***Service in preview:** Geolocation, Elevation, Data Service, Mobility, Weather Service and Creator*

#### 2.1.2. Azure Maps Tiers

#### 2.1.2.1 Tiers Description
| **Tier** | **Description** |
|-- | -- | 
| S0 | Tier S0 works for applications in all stages of production: from proof-of-concept development and early stage testing to application production and deployment. However, this tier is designed for small-scale development, or customers with low concurrent users, or both. | 
 | S1 | Tier S1 is for customers with large-scale enterprise applications, mission-critical applications, or high volumes of concurrent users. It's also for those customers who require advanced geospatial services. | 

#### 2.1.2.1 Tiers Capabilities
| **Capability** | **S0** | **S1** | 
|-- | ----- | -- | 
| Map Render 				| x | x |
| Satellite Imagery  		|   | x |
| Search 					| x | x | 
| Batch Search 				|   | x | 
| Route 					| x | x | 
| Batch Routing 			|	| x | 
| Matrix Routing 			|   | x | 
| Route Range (Isochrones) 	|   | x | 
| Traffic 					| x | x | 
| Time Zone 				| x | x | 
| Geolocation (Preview) 	| x | x | 
| Spatial Operations 		| 	| x | 
| Geofencing 				| 	| x | 
| Azure Maps Data (Preview) | 	| x | 
| Mobility (Preview) 		| 	| x | 
| Weather (Preview) 		| x | x | 
| Creator (Preview) 		|	| x | 
| Elevation (Preview) 		| 	| x | 

> Design Decision: Tier S0 will be enforced in the ARM template. The use of Tear S1 will be evaluated later

### 2.2. Authentication
Azure Maps supports 2 types of authentication: 
+ Shared Key authentication
+ Azure Active Directory

#### 2.2.1 Shared Key authentication
A primary and secondary key is generated during the provisioning of the Azure Maps resource.  A best practise is to use the primary key when calling Azure Maps with this authentication method.  it is recommended to rotate between the primary and secondary keys.  Update the app to use the secondary key, before regenerating the primary key. this will disable the old primary key. after the refresh of they key, the app can be reconfigured to use the new primary key.  
![Automate Azure Maps Key Rotation](/.attachments/azuremaps_keyrotation.jpg)
1. Before the expiration date of a secret, Key Vault publishes the near expiry event to Event Grid.
2. Event Grid checks the event subscriptions and uses HTTP POST to call the function app endpoint that's subscribed to the event.
3. The function app identifies the alternate key (not the latest one) and calls the storage account to regenerate it.
4. The function app adds the new regenerated key to Azure Key Vault as the new version of the secret.
5. Webapp gets the key from the Key Vault.
6. Webpp uses the key from the Key Vault to authenticate to Azure Maps.

#### 2.2.2 Azure Active Directory
Azure Maps support Azure AD as an authentication mechanism. Azure AD provides identity-based authentication for users and applications registered in the Azure AD tenant.  

#### 2.2.2 Role Based access control
Azure Maps is integrated with Azure RBAC. this allows Azure Maps to set different type of permissions to users, groups, applications, Azure resources and Azure Managed Identities.

RBAC Permission model provides the following roles:

| **Built-in role**                        | **Description**          | **Accounts**|
|----|----------------------|----|
| Azure Maps Data Reader 		| Provides access to immutable Azure Maps REST APIs. ||
| Azure Maps Data Contributor	| Provides access to mutable Azure Maps REST APIs. Mutability is defined by the actions: write and delete. | |
| Custom Role Definition		| Create a crafted role to enable flexible restricted access to Azure Maps REST APIs. ||

> Design Decision: Both authentication method will be supported

### 2.3. Service Limits
Following are the limits per subscriptions and per product:
+ [Azure limits per subscription](https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits)

## 3. Service Provisioning

### 3.1. Prerequisites
The following Azure resources need to be in place before this Certified Service can be provisioned:
+ Subscription
+ Resource Group
+ Central Log Analytics Workspace
### 3.2. Deployment parameters
All Parameters indicated with Fixed will not be included as an option during deployment and will be set as default parameter:

|**Parameter**|**Type**|**Prod**|**Non-Prod**| **Implementation** | **Implementation Status** |
|--|--|--|--|--|--|
|**Subscription**	|string|N/A|N/A| <span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span>
|**Resource Group**	|string|N/A|N/A|<span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span>
|**Name**			|string|<name>|<name>|<span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span>
|**Tier**			|string|<name>|<name>|<span style="color:green">**PARAMETER**</span>|<span style="color:grey">**N/A**</span>
|**location**		|string|Global (Fixed)|Global (Fixed)|<span style="color:green">**DEFAULT**</span>|<span style="color:grey">**N/A**</span>

Legend:
+ Fixed: The parameter will be hardcoded in the ARM template
+ Enforced by policy: There will be a policy created to manage the parameter changes after deployment
+ Cannot be changed after deployment: The parameter will be unchangeable after deployment.

## 4. Service Management 

## 5. Security Controls 

All product-specific security controls - for the current product version - can be found on the table below:

| Index | Security Requirements | Relevance | Implementation details  | Policy Enforced / Audit | Status  |
|--|--|--|--|--|--|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later).  | |   |  |  |
| CN-SR-02 | Secret and Key management needs to be done by a dedicated database/vault.  |   |   |   |  |
| CN-SR-03 | Encrypt information at rest (Disc encryption).  |  |   |  |  |
| CN-SR-04 | Maintain an inventory of sensitive Information.  |   |   |   |  |
| CN-SR-05 | Use an active discovery tool to identify sensitive data.  |  |   |   |  |
| CN-SR-06 | Protect the database from permanently deleting data by enabling soft delete functionality.  |  |  |   |  |
| CN-SR-07 | Ensure regular automated back ups  |  |  |   |  |
| CN-SR-08 | Enforce the use of Azure Active Directory.  |  |  |   |  |
| CN-SR-09 | Follow the principle of least privilege.  |  |  |   |  |
| CN-SR-10 | Configure security log storage retention.  |  |  |   |  |
| CN-SR-11 | Enable alerts for anomalous activity.  |  |  |   |  |
| CN-SR-12 | Configure central security log management.   |  |  |   |  |
| CN-SR-13 | Enable audit logging of Azure Resources.  |  |  |   |  |
| CN-SR-14 | Enable MFA and conditional access with MFA.  |  |  |   |  |
| CN-SR-15 | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network.  |  |  |   |  |
| CN-SR-16 | Ensure that the endpoint protection for all Virtual Machines is installed.  |  |  |   |  |
| CN-SR-17 | Secure outbound communication to the internet.  |  |  |   |  |
| CN-SR-18 | Enable JIT network access.  |  |  |   |  |
| CN-SR-19 | Run automated vulnerability scanning tools.  |  |  |   |  |
| CN-SR-20 | Use automated tools to monitor network resource configurations and detect changes.  |  |  |   |  |
| CN-SR-21 | Disable remote user access ports (RDP,SSH,Telnet,FTP).  |  |  |   |  |
| CN-SR-22 | Enable automated Patching/ Upgrading.  |  |  |   |  |
| CN-SR-23 | Enable transparent data encryption.  |  |  |   |  |
| CN-SR-24 | Enable OS vulnerabilities recommendations.  |  |  |   |  |
| CN-SR-25 | Configure firewall rules of existing firewalls if necessary.  |  |  |   |  |
| CN-SR-26 | Enable command-line audit logging.  |  |  |   |  |
| CN-SR-27 | Enable conditional access control.  |  |  |   |  |
| CN-SR-28 | Specify service tags to define network access controls on network security groups or Azure Firewall. |  |  |   |  |
| CN-SR-29 | Use Corporate Active Directory Credentials.  |  |  |   |  |


