Template EXAMPLE

<span style="color:red">This page serves as an template for Product descriptions. It is CCoE customer facing as well as used during the complete development process from design to build to certification. It addresses the product from a functionality as well as a security requirements perspective.</span> 


# Key Vault 1.0

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

## 2. Architecture

### 2.1. High Level Design

### 2.2. Data plane 

#### 2.2.1. Endpoint Access

#### 2.2.2. Endpoint Authorization and Authentication

### 2.3. Management Plane 

### 2.4. Service Limits
 
## 3. Service Provisioning

### 3.1. Prerequisites

### 3.2. Deployment parameters

## 4. Service Management 

## 5. Security Controls 

All product-specific security controls - for the current product version - can be found on the table below (and with additional guidelines [here](https://dev.azure.com/contoso-azure/building-blocks/_wiki/wikis/Wiki/473/Cloud-Native-Security-Controls)):

| Index | Security Requirements | Relevance | Implementation details  | Policy Enforced / Audit | Design Status  | Implementation Status |
|--|--|--|--|--|--|--|
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