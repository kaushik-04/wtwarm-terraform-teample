This page describes how to deploy either an windows or linux custom image and use it with a ScaleSet for Build Agents.

[[_TOC_]]

---
---

# Custom Image
The image creation uses several components:
| Resource | Description |
|--|--|
| Resource Group | The resource group hosting our image resources |
| Storage Account | The storage account that hosts our image customization scripts used by the _Azure Image Building_ when executing the image template |
| User-Assigned Managed Identity | Azure Active Directory feature that eliminates the need for credentials in code, rotates credentials automatically, and reduces identity maintenance. In the context of the imaging solution, the managed identity (MSI) is used by the Image Builder Service. It requires contributor permissions on the subscription to be able to bake the image. |
| Shared Image Gallery | Azure service that helps to build structure and organization for managed images. Provides global replication, versioning, grouping, sharing across subscriptions and scaling. The plain resource in itself is like an empty container. |
| Image Definition | Created within a gallery and contains information about the image and requirements for using it internally. This includes metadata like whether the image is Windows or Linux, release notes and recommended compute resources. Like the image gallery itself it acts like a container for the actual images. |
| Image Template | A standard Azure Image Builder template that defines the parameters for building a custom image with AIB. The parameters include image source (Marketplace, custom image, etc), customization options (i.e., Updates, scripts, restarts), and distribution (i.e., managed image, shared image gallery). The template is not an actual resource. Instead, when an image template is created, Azure stores all the metadata of the referenced image definition alongside other image backing instructions as a hidden resource in a temporary resource group. This resource group is removed once an image creation is triggered based on the template. | 
| Image Version | An image version is what you use to create a VM when using a gallery. You can have multiple versions of an image as needed for your environment. This value **cannot** be influenced. E.g. `0.24322.55884` |

![ImageBuilderElements](./src/imageBuilderimage.png =60%x)

## Process
### Deployment
The creation of the image alongside its resources is handled by the `pipeline.image.yml` pipeline. Given the proper configuration, it creates all required resources in the designated environment and optionally triggers the image creation right after. 

So let's take a look at the different configuration options when running the pipeline:

<div class="row">
<div style="float: left; width: 80%;">

- **_'Environment to deploy to'_ selection:**
  Here you can choose where you want to create the image. You can choose in between: SBX, DEV, INT & PRD. Stages have approvers set.

- **_'Create image for OS'_ selection:**
  The OS type of the image you want to create. You can choose either _Windows_ or _Linux_. 

- **_'Scope of deployment'_ selection:**
  Select whether you want to deploy all resources, all resources without triggering the image build, or only the image build. If the script used during the image backing (as referenced in the image template parameter file) has changed, make sure you always also re-deploy the infrastructure to make sure the new file is uploaded to the storage account.
  
- **_'Wait for image build'_ switch:**
  Specify whether to wait for the image build process during the pipeline run or not. The process itself is triggered asynchronously. If not selected, you can use the 'Wait-ForImageBuild' script to check the status yourself (located at: `PipelineAgentsScaleSet\Scripts\Wait-ForImageBuild.ps1`). To trigger it you will need the image template name (output value of the image template deployment) and the resource group of your image template deployment.

</div>
<div style="float: left; width: 20%;">

![imagePipelineParameters](./src/imagetrigger.png =150x)

</div>
</div>

<div style="clear:both"></div>

### Configuration

#### First deployment
For the first deployment make sure all paramater files for the target location (e.g. sbx) are properly configured and available in the _'Parameters'_ folder (`PipelineAgentsScaleSet\Parameters`). The pipeline decides which parameter files to choose based on the environment and uses it as a suffix to find the correct file. For example, the name `sbx.parameters.windows.json` implies a the SBX environment while the DEV deployment would search for a file `dev.parameters.windows.json` in the same folder.

When triggering the pipeline first the first time for an environment, make sure you either select _'All'_ or _'Only Infrastructure'_ for the first run. In either case the pipeline will deploy all resources and scripts you will subsequently need to create the images. 
For any subsequent run, you can go with any option you need.

#### Consecutive deployments
To update an image you first have to decide whether you want to build an image from the ground up (using e.g. a marketplace image as the basis) or build on an existing one. In either case you have to configure the image template parameter file in question with regards to the `imageSource` parameter.
To reference a marketplace image use the syntax:
```Json
@{
  "imageSource": {
     "value": {
	"type": "PlatformImage",
	"publisher": "MicrosoftWindowsDesktop",
	"offer": "Windows-10",
	"sku": "19h2-evd",
	"version": "latest"
      }
   }
}
```
To reference a custom image use the syntax (where the ID is the resourceId of the image version in the shared image gallery):
```Json
@{
  "imageSource": {
      "value": {
         "type": "SharedImageVersion",
         "imageVersionID": "/subscriptions/c64d2kd9-4679-45f5-b17a-e27b0214acp4d/resourceGroups/scale-set-rg/providers/Microsoft.Compute/galleries/mygallery/images/mydefinition/versions/0.24457.34028"
      }
   }
}
```
The steps the _Azure Image Builder_ performs on the image are defined by elements configured in the `customizationSteps` parameter of the image template parameter file. In our setup we reference one or multiple custom scripts that are uploaded by the pipeline to a storage account ahead of the image deployment.
The scripts are different for the type of OS and hence are also stored in two different folders in the `PipelineAgentsScaleSet` module:
- Windows: `PipelineAgentsScaleSet\Scripts\Uploads\windows`
- Linux: `PipelineAgentsScaleSet\Scripts\Uploads\linux`

One of the main tasks perform in these scripts are the installation of the baseline modules and software we want to have installed on the image. Prime candidates are for example the Az-Modules.

## Installed Components

| OS |   |   | Windows | Linux |
| -  | - | - | -       | -     |
| Base Image | | | `Windows-10 19h2-evd` | `UbuntuServer 18.04-LTS` |
| Software | `Choco` | | :heavy_check_mark: | |
| | `Azure-CLI` | | :heavy_check_mark: | :heavy_check_mark: |
| | `PowerShell Core (7.*)` | | :heavy_check_mark: | :heavy_check_mark:  |
| | `.NET SDK` | | | :heavy_check_mark: |
| | `.NET Runtime` | | | :heavy_check_mark: |
| | `Nuget Package Provider` | | :heavy_check_mark: | :heavy_check_mark: (`dotnet nuget`) |
| | `Terraform` | | :heavy_check_mark: (`latest`) | :heavy_check_mark: (`0.12.30`)  |
| | `azcopy` | |  :heavy_check_mark: (`latest`) |  :heavy_check_mark: (`latest`) |
|
| Modules
| | PowerShell 
| | | `PowerShellGet` | :heavy_check_mark: | :heavy_check_mark: |
| | | `Pester` | :heavy_check_mark: | :heavy_check_mark: |
| | | `PSScriptAnalyzer` | :heavy_check_mark: | :heavy_check_mark: |
| | | `powershell-yaml` | :heavy_check_mark: | :heavy_check_mark: |
| | | `Azure.*` | :heavy_check_mark: | :heavy_check_mark: |
| | | `Logging` | :heavy_check_mark: | :heavy_check_mark: |
| | | `PoshRSJob` | :heavy_check_mark: | :heavy_check_mark: |
| | | `ThreadJob` | :heavy_check_mark: | :heavy_check_mark: |
| | | `JWTDetails` | :heavy_check_mark: | :heavy_check_mark: |
| | | `OMSIngestionAPI` | :heavy_check_mark: | :heavy_check_mark: |
| | | `Az.*` | :heavy_check_mark: | :heavy_check_mark: |
| | | `AzureAD` | :heavy_check_mark: | :heavy_check_mark: |
| | | `ImportExcel` | :heavy_check_mark: | :heavy_check_mark: |
| Extensions
| | CLI 
| | | `kubenet` | :heavy_check_mark: | :heavy_check_mark: |
| | | `azure-devops` | :heavy_check_mark: | :heavy_check_mark: |
---
---

# Scale Set Agents
The scale set agents deployment includes several components:

| Resource | Description |
|--|--|
| Resource Group | The resource group hosting our scale set resources |
| Virtual Machine Scale Set | The scale set that will host our pipeline agents |


## Advantages
> Compared to classic single build host (with multiple agents installed)
- Each pipeline job can use a dedicated new host (if configured accordingly)
- We can safe money as the scale set can be configured to e.g. scale down to 0 and spin up a new VM only if a job is scheduled
  - As a single agent is installed on a new instance, VMs don't have to have a strong SKU

---

## Use in DevOps

In general the process works as follows:
1. Deploy a VMSS to Azure
   Create a VMSS and select the previously created custom image as the base image. Make sure the scaling is configured as `'manual'`. The amount of initial VMs does not matter as they are scaled down anyways.
1. Register the VMSS from Azure DevOps
    - Navigate to the ADO project / Project Settings / Agent Pools and create a new Agent Pool.
      - As a type select VMSS and further select the created VMSS
      - Configure further properties like the amount of instances at rest (can be 0) or that you want to read down agents after every use (for that to work make sure the MaxCount is sufficiently high - otherwise it still reuses idle agents)
    - Subsequently an extension is applied by ADO to the VMSS that takes care of registering the agents. ADO will also take care of the scaling as per the configured values
    - Now you can reference the created pool in your pipelines
      - With the image provided in this solution it takes
        - About 8 Minutes for a Windows Agent to come to life
        - About 4 Minutes for a Linux Agent to come to life

---

## Additional Considerations

### Apply a new image
The image used in the scale set can be idempotently updated. Once a new image is available just restart the ScaleSet deployment pipeline and wait for it to complete.
New build agents will be based on the new image.

### Cross VNET communication
Would we need to handle resources across non-peered VNETs with firewall configured, then we have to make sure the Scale Set is able to do so too.
The simpliest solution to archieve this is to place the `VMSS` in a Subnet of a VNET and assign a `NAT Gateway` to it. This `NAT Gateway` should have a Public-IP or IP-Prefix assigned.
Once done, communication to
- resources in the same VNET is routed via private IPs and hence require the corresponding VMSS subnet to be whitelisted
- resources in any other non-peered VNET are routed via the `NAT Gateways` public IP (or prefixes) and hence require this one to be whitelisted

#### NAT Gateway sidenotes
##### Scalability
NAT uses "port network address translation" (PNAT or PAT) and is recommended for most workloads. Dynamic or divergent workloads can be easily accommodated with on-demand outbound flow allocation. Extensive pre-planning, pre-allocation, and ultimately over provisioning of outbound resources is avoided. SNAT port resources are shared and available across all subnets using a specific NAT gateway resource and are provided when needed.

A public IP address attached to NAT provides up to 64,000 concurrent flows for UDP and TCP. You can start with a single IP address and scale up to 16 public IP addresses. A Public IP Prefix can be assigned.

NAT allows flows to be created from the virtual network to the Internet. Return traffic from the Internet is only allowed in response to an active flow.

Unlike load balancer outbound SNAT, NAT has no restrictions on which private IP of a virtual machine instance can make outbound connections. Secondary IP configurations can create outbound Internet connection with NAT.

The VNET NAT Gateway can have easily up to 2K open SNAT connections/flows per VM, as shown in below exhibit (Only one VM is running in this example with 1300 flows). This means, a VNET NAT Gateway with 16 Public IP's can provide up to 512 concurrent running VM's.

##### Limitations
- NAT is compatible with standard SKU public IP, public IP prefix, and load balancer resources. Basic resources (for example basic load balancer) and any products derived from them aren't compatible with NAT. Basic resources must be placed on a subnet not configured with NAT.
- IPv4 address family is supported. NAT doesn't interact with IPv6 address family. NAT cannot be deployed on a subnet with IPv6 prefix.
- NSG flow logging isn't supported when using NAT.
- NAT can't span multiple virtual networks.

---
---

# Sources
- [VMSS for ADO agents](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops)