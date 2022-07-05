# Machine Learning 1.0

| **Status** | <span style="color:orange">**DRAFT**</span> |
|--|--|
| **Version** | v0.1 |
| **Edited By** | <author> |
| **Date** | 10/01/2021  |
| **Approvers** |  |
| **Deployment documentation** | <link to GIT Module missing> |
| **To Do** |  |

[[_TOC_]]

## 1. Introduction

### 1.1. Service Description

Azure Machine Learning can be used for any kind of machine learning, from classical ml to deep learning, supervised, and unsupervised learning. Whether preferred to write Python or R code with the SDK or work with no-code/low-code options in the studio. Azure Machine Learning Workspace is a service to build, train, and track machine learning and deep-learning models. Training can start on a local machine and then scale out to the cloud.

The service also interoperates with popular deep learning and reinforcement open-source tools such as PyTorch, TensorFlow, scikit-learn, and Ray RLlib.

Azure Machine Learning even support use MLflow to track metrics and deploy models or Kubeflow to build end-to-end workflow pipelines.

## 2. Architecture

### 2.1. High Level Design

![contoso_azure_ml_architecture.png](/.attachments/contoso_azure_ml_architecture-11c5d5d8-c906-4a8e-a485-a4cc2d4f54eb.png)

This product focuses on Azure Machine Learning. Individual services that Azure ML have dependencies must provide their own RBAC settings or ACL. For example,

- Dependencies
- Managed resources
- Linked Services

#### 2.1.1 Map Workspaces to Business Divisions

AML Workspaces have to be assigned based on a related group of people working together collaboratively. This also helps in streamlining the access control matrix within the workspace (datastores, experiments, models etc.) and also across all resources that the workspace interacts with (datastores, compute etc.). This type of division scheme is also known as the Business Unit/Workgroup Subscription design pattern.

#### 2.1.2 Azure ML workloads

There are two options for supporting Interactive workloads on AML:

1.) Deployment of a shared workspace, where user with the same data access requirements are working interactively together.

2.) Configure a batch workspace for instance for production environments, where users will not have access:

How interactive workloads are different from batch workloads:

| | **Prod** | **Non-Prod** | **Non-Prod** |
| --  | --  | --  | -- |
|**Workload** |	Batch |	Interactive |	Batch |
|**Target User** |	Technical User |	Data Scientist |	Technical User
 |**Best Use** |	Batch Jobs Pipeline |	Data Exploration |	Batch Jobs Pipeline |
 |**Security Model** |	Single User |	Multi User |	Single User |
 |**Isolation**  |	Medium |	Low |	Medium |

Depending on the workload two configuration options are available:

- Interactive AML Workspace as analytics platform for collaboration between data engineers, data scientists, and machine learning engineers.
- Batch AML Workspace data processing for batch workloads

### 2.2. Data plane

#### 2.2.1. Endpoint Access

Data scientist developers in Azure Machine Learning can connect to Azure ML service CLI, SDK, Notebook, Web Portal. The studio combines no-code and code-first experiences for an inclusive data science platform:

https://ml.azure.com/?tid=<tennat_id>&wsid=/subscriptions/<subscription_id>/resourcegroups/<resource_group>/workspaces/<workspace_name>

**Non-Prod** (Sandbox)

![AML_Sandbox1.jpg](/.attachments/AML_Sandbox1-f6d5696e-740a-44f7-bd44-ed9c998c0a80.jpg)

**Prod** (Public network access is disabled)

![AML_Prod1.jpg](/.attachments/AML_Prod1-a7fefcee-3de3-4f70-bb3c-a34be12a1392.jpg)

**Prod** (Very limited scenario with Data Scientist who require prod data access)

![AML_Prod_PAW1.jpg](/.attachments/AML_Prod_PAW1-83a340bf-a892-49c0-bb87-98f102f5a226.jpg)

#### 2.2.2. Endpoint Authorization and Authentication

Machine Learning is integrated with Azure Active Directory, use Azure Active Directory SSO instead of configuring individual stand-alone credentials per-service. Use Azure Security Center identity and access recommendations.

#### 2.2.3. Secure Secrets

Azure Machine Learning uses an associated Key Vault instance to store the following credentials:

- The associated storage account connection string
- Passwords to Azure Container Repository instances
- Connection strings to data stores

### 2.3. Management Plane

The workspace is the top-level resource for Azure Machine Learning, providing a centralized place to work with all the artifacts when using Azure Machine Learning. The workspace keeps a history of all training runs, including logs, metrics, output, and a snapshot of your scripts. This information is valuable to determine which training run produces the best model.

Azure ML provides three authentication workflows that you can use when connecting to the workspace:

**Interactive**: A user account in Azure Active Directory to either directly authenticate, or to get a token that is used for authentication. Interactive authentication is used during experimentation and iterative development.

**Service principal**: Creation of a service principal account in Azure Active Directory, and for use of authentication or get a token. A service principal is used when an automated process needs to authenticate to the service without requiring user interaction.

**Managed identity**: When using the Azure Machine Learning SDK on an Azure Virtual Machine, the VM can configured with managed identity for Azure. This workflow allows the VM to connect to the workspace using the managed identity, without storing credentials in Python code or prompting the user to authenticate. Azure Machine Learning compute clusters can also be configured to use a managed identity to access the workspace when training models.

#### 2.3.1 Azure ML Role

When a new Azure Machine Learning workspace is created, it comes with three default roles. You can add users to the workspace and assign them to one of these built-in roles.

**Reader**: Read-only actions in the workspace. Readers can list and view assets, including datastore credentials, in a workspace. Readers can't create or update these assets.

**Contributor**: View, create, edit, or delete (where applicable) assets in a workspace. For example, contributors can create an experiment, create or attach a compute cluster, submit a run, and deploy a web service.

Since **SSH access isn't allowed** to access virtual machines via Visual Studio Code to have a integrated development environment, Developers require **Contributor** Role for Non-Prod environments to create managed compute.

Azure Machine Learning Workspace Roles:

| Personas | Non-Prod | Prod |
|-- | -- | -- |
| Devops Principal | LZ Owner| LZ Owner |
| Data Scientist | MLS Data Scientist - #11505 | Reader |
| Workspace Administrator | MLS Workspace Admin - #11906 | Reader |
| Workspace Operator | - | MLS Workspace Ops |

#### 2.3.2 Azure Machine Learning compute (managed)

A managed compute resource is created and managed by AML. This compute is optimized for machine learning workloads. AML compute clusters and compute instances are the only managed computes that can be created. When created, these compute resources can be enabled for SSH to support developers IDE experience. The Compute instances are automatically part of AML workspace, unlike other kinds of compute targets and cannot be accessed from public.

### 2.4. Service Limits

[The latest values for Azure Machine Learning Compute quotas can be found in the Azure Machine Learning quota page](https://docs.microsoft.com/en-us/azure/machine-learning/how-to-manage-quotas)

## 3. Service Provisioning

### 3.1. Prerequisites

| Field | Description |
|--|--|
| Workspace name | Unique name that identifies the workspace. The workspace name is **case-insensitive**.|
|Subscription| Select the Azure subscription to use.|
| Resource group | Use an existing resource group in a subscription or enter a name to create a new resource group. | 
| Region | Select the Azure region closest to your users and the data resources to create your workspace. |
| Storage account | The default storage account for the workspace. Requires non-hierarchical namespace.|
| Key Vault | The Azure Key Vault used by the workspace. |
| Application Insights | The application insights instance for the workspace. |
| Container Registry | The Azure Container Registry for the workspace. |

### 3.2. Deployment parameters

|  |  Prod	| Non-Prod | Implementation |
|--|--|--|--|
| **Workspace Name** | <name> | <name> | Parameter |
| **Azure Region** | resource group location | resource group location | Parameter |
| **SKU** | basic| basic | Default |
| **Storage account** | StorageAccount Name | StorageAccount Name | Parameter |
| **Key Vault** | KeyVault Name | KeyVault Name | Parameter |
| **Application Insights** | ApplicationInsights Name | ApplicationInsights Name | Parameter |
| **Container Registry** | ContainerRegistry Name | ContainerRegistry Name | Parameter |
| **Connectivity method** | Public endpoint| Public endpoint | Parameter |
| **Diagnostics Storage** | Storage/Log Analytics/Event Hub | Storage/Log Analytics/Event Hub | Parameter |

## 4. Service Management

| **MSM Code** | **Functional Control Description** | **Category** | **Product Assessment Q&A** | **Validated** | **Implementation** | **Status** |
|----------|----------------------------------------------------------------------------------------------------------------------------|------------------------|------------------------|------------------------|----|----|
| **M-STD02** | Health alerts are automatically generated, correlated and managed based on event monitoring.                            |     Standard   |   [Requires diagnostic settings for Azure Machine Learning and send logs to a Log Analytics workspace. Analyze and alert on this data with Azure Monitor  Azure Machine Learning logs for critical applications and business processes relying on Azure resources regarding their availability, performance, and operation](https://docs.microsoft.com/en-us/azure/machine-learning/monitor-azure-machine-learning#monitoring-data-from-azure-machine-learning).    |      Yes     |   [This control is applied by defining Resource Health Alerts in Azure Monitor which requires additional configuration there](https://docs.microsoft.com/en-us/azure/machine-learning/monitor-azure-machine-learning#alerts).   |  <span style="color:orange">**DRAFT**</span>   |
|  **M-STD05**        |       Disaster Recovery (DR) scenario’s are applied and  tested periodically          |    Standard    | Azure Machine Learning is a compute service which is having dependencies to data stores. Controls must be applied to data stores. Azure ML Service is having a SLA of 99.9%. |  No  |   N/A   |    <span style="color:orange">**DRAFT**</span>   |
|  **M-PaaS01**       |        RTO / RPO requirements are achieved for PaaS backup and restore           |    Standard    |   Azure Machine Learning is a compute service which is having dependencies to data stores. Controls must be applied to data stores. |  No  |   N/A   |    <span style="color:orange">**DRAFT**</span>   |

## 5. Security Controls

All product-specific security controls - for the current product version - can be found on the table below:

| Index | Security Requirements | Relevance | Implementation details  | Policy Enforced / Audit | Status  |
|--|--|--|--|--|--|
| CN-SR-01 | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later).  | [Web services deployed through Azure Machine Learning only support TLS version 1.2 that enforces data encryption in transit](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#44-encrypt-all-sensitive-information-in-transit). | N/A  | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-02 | Secret and Key management needs to be done by a dedicated database/vault.  | [When you create a new workspace, it automatically creates several Azure resources that are used by the workspace. A dedicated Azure KeyVault must be associated to store secrets that are used by compute targets and other sensitive information that's needed by the workspace](https://docs.microsoft.com/en-us/azure/machine-learning/concept-workspace#resources). | ARM/PowerShell | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-03 | Encrypt information at rest (Disc encryption).  | [Azure Machine Learning stores snapshots, output, and logs in the Azure Blob storage account that's tied to the Azure Machine Learning workspace and your subscription. All the data stored in Azure Blob storage is encrypted at rest with Microsoft-managed keys](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#48-encrypt-sensitive-information-at-rest). | ARM/PowerShell | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-04 | Maintain an inventory of sensitive Information.  | [Use tags to assist in tracking Azure resources that store or process sensitive information](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#41-maintain-an-inventory-of-sensitive-information)| ARM/PowerShell | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-05 | Use an active discovery tool to identify sensitive data.  | [Data identification, classification, and loss prevention features are not yet available for Azure Machine Learning. Implement a third-party solution if necessary for compliance purposes.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#45-use-an-active-discovery-tool-to-identify-sensitive-data) | N/A | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-06 | Protect the database from permanently deleting data by enabling soft delete functionality.  | Azure ML Service is a compute and not a data storage service. It is having dependencies to data stores that must cover this control. | N/A | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-07 | Ensure regular automated back ups  | [Data backup in Machine Learning service is through data managements on connected data stores. Enable Azure Backup for VMs and configure the desired frequency and retention periods. Back up customer-managed keys in Azure Key Vault. Azure ML Experiments, Models, requires backup by IAC (DevOps)](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#92-perform-complete-system-backups-and-backup-any-customer-managed-keys) | N/A | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-08 | Enforce the use of Azure Active Directory.  | [Machine Learning is integrated with Azure Active Directory, use Azure Active Directory SSO instead of configuring individual stand-alone credentials per-service.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#34-use-single-sign-on-sso-with-azure-active-directory)  | N/A | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-09 | Follow the principle of least privilege.  | [Use a secure, Azure-managed workstation (also known as a Privileged Access Workstation, or PAW) for administrative tasks that require elevated privileges.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#36-use-dedicated-machines-privileged-access-workstations-for-all-administrative-tasks) | N/A | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-10 | Configure security log storage retention.  | [In Azure Monitor, set the log retention period for Log Analytics workspaces associated with your Azure Machine Learning instances according to your organization's compliance regulations.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#25-configure-security-log-storage-retention)  | ARM/PowerShell | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-11 | Enable alerts for anomalous activity.  | [In Azure Monitor, configure logs related to Azure Machine Learning within the Activity Log, and Machine Learning diagnostic settings to send logs into a Log Analytics workspace to be queried or into a storage account for long-term archival storage.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#27-enable-alerts-for-anomalous-activities) | ARM/PowerShell | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-12 | Configure central security log management.   | [Ingest logs via Azure Monitor to aggregate security data generated by Azure Machine Learning. In Azure Monitor, use Log Analytics workspaces to query and perform analytics, and use Azure Storage accounts for long term and archival storage.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#22-configure-central-security-log-management) | ARM/PowerShell | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-13 | Enable audit logging of Azure Resources.  | [Enable diagnostic settings on Azure resources for access to audit, security, and diagnostic logs. You can also correlate Machine Learning service operation logs for security and compliance purposes.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#23-enable-audit-logging-for-azure-resources) |ARM/PowerShell | N/A |  <span style="color:green">**FINAL**</span>|
| CN-SR-14 | Enable MFA and conditional access with MFA.  | [Enable Azure Active Directory Multi-Factor Authentication and follow Azure Security Center identity and access recommendations.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#35-use-multi-factor-authentication-for-all-azure-active-directory-based-access) | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-15 | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network.  | [This contoso product reference to "cloud-native" and will not require VNET integration. If required secure the machine learning compute resource by isolating Azure Machine Learning training and inference jobs within an Azure virtual network.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#11-protect-azure-resources-within-virtual-networks) | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-16 | Ensure that the endpoint protection for all Virtual Machines is installed.  | [Microsoft anti-malware is enabled and maintained for the underlying host that supports Azure services (for example, Azure Machine learning)](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#83-ensure-antimalware-software-and-signatures-are-updated)  | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-17 | Secure outbound communication to the internet.  |[This contoso product reference to "cloud-native" and will not require VNET integration. If required secure the machine learning compute resource by isolating Azure Machine Learning training and inference jobs within an Azure virtual network.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#11-protect-azure-resources-within-virtual-networks) | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-18 | Enable JIT network access.  |[Microsoft anti-malware is enabled and maintained for the underlying host that supports Azure services (for example, Azure Machine learning)](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#83-ensure-antimalware-software-and-signatures-are-updated)  | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-19 | Run automated vulnerability scanning tools.  | [If the compute resource is owned by Microsoft, then Microsoft is responsible for vulnerability management of Azure Machine Learning service.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#51-run-automated-vulnerability-scanning-tools)  | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-20 | Use automated tools to monitor network resource configurations and detect changes.  | [Use Azure Activity Log to monitor network resource configurations and detect changes for network resources related to Azure Machine Learning.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#111-use-automated-tools-to-monitor-network-resource-configurations-and-detect-changes) | ARM/PowerShell | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-21 | Disable remote user access ports (RDP,SSH,Telnet,FTP).  | [A compute instance is a fully managed cloud-based workstation optimized for your machine learning development environment. Customer can setup SSH policy to enable/disable SSH access](https://docs.microsoft.com/en-us/azure/machine-learning/concept-compute-instance#why-use-a-compute-instance). | N/A | N/A |  <span style="color:orange">**DRAFT**</span> |
| CN-SR-22 | Enable automated Patching/ Upgrading.  | [If the compute resource is owned by Microsoft, then Microsoft is responsible for patch management of Azure Machine Learning service.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#52-deploy-automated-operating-system-patch-management-solution) | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-23 | Enable transparent data encryption.  |[Azure Machine Learning stores snapshots, output, and logs in the Azure Blob storage account that's tied to the Azure Machine Learning workspace and the subscription.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#48-encrypt-sensitive-information-at-rest)  | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-24 | Enable OS vulnerabilities recommendations. | [If the compute resource is owned by Microsoft, then Microsoft is responsible for patch management of Azure Machine Learning service.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#52-deploy-automated-operating-system-patch-management-solution) | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-25 | Configure firewall rules of existing firewalls if necessary.  | [Azure Machine Learning relies on other Azure services for compute resources. Compute resources (compute targets) must allow connections from Azure ML.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#11-protect-azure-resources-within-virtual-networks) | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-26 | Enable command-line audit logging.  |[Azure Machine Learning has varying support across different compute resources and even customer owned compute resources. For compute resources are owned by customer organization, use Azure Security Center to enable security event log monitoring for Azure virtual machines.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#210-enable-command-line-audit-logging)  | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-27 | Enable conditional access control.  | [Use Azure AD Conditional Access to limit users' ability to interact with Azure Resources Manager by configuring "Block access" for the "Microsoft Azure Management" App.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#611-limit-users-ability-to-interact-with-azure-resource-manager) | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-28 | Specify service tags to define network access controls on network security groups or Azure Firewall. | [This contoso product reference to "cloud-native" and will not require VNET integration.]() | N/A | N/A |  <span style="color:green">**FINAL**</span> |
| CN-SR-29 | Use Corporate Active Directory Credentials.  |[Machine Learning is integrated with Azure Active Directory, use Azure Active Directory SSO instead of configuring individual stand-alone credentials per-service.](https://docs.microsoft.com/en-us/azure/machine-learning/security-baseline#34-use-single-sign-on-sso-with-azure-active-directory)  | N/A | N/A |  <span style="color:green">**FINAL**</span> |
