Following table represents security requirements, gathered from Excel document "Standard Security Baseline v0.2", that need to be considered in the design of the Components/Products and in the certification process. <P> 
Nevertheless, additional security recommendations might be considered in the product design if required or recommended by Microsoft.


| Index | Scope | Category | Resource Type | Guideline | Extra Information Azure |
|--|--|---|--|---|--|
| CN&#x2011;SC&#x2011;01 | Service/Component | Data Protection | General | Use a secure protocol to encrypt data at transfer (Preferably TLS1.2 or later) | |
| CN-SC-02 | Service/Component | Data Protection | General | Secret and Key management needs to be done by a dedicated database/vault | |
| CN-SC-03 | Service/Component | Data Protection | General | Encrypt information at rest (Disc encryption) | |
| CN-SC-04 | Service/Component | Data Protection | General | Maintain an inventory of sensitive Information | |
| CN-SC-05 | Foundation | Data Protection | General | Use an active discovery tool to identify sensitive data | Enable Advanced Data Security |
| CN-SC-06 | Service/Component | Data Protection | Databases | Protect the database from permanently deleting data by enabling soft delete functionality | |
| CN-SC-07 | Service/Component | Data Recovery | General | Ensure regular automated back ups | |
| CN-SC-08 | Service/Component | IAM | General | Enforce the use of Azure Active Directory 
| CN-SC-10 | Foundation | Logging and Monitoring | General | Configure security log storage retention | |
| CN-SC-11 | Foundation | Logging and Monitoring | General | Enable alerts for anomalous activity | |
| CN-SC-12 | Foundation | Logging and Monitoring | General | Configure central security log management  | |
| CN-SC-13 | Service/Component | Loggin and Monitoring | General | Enable audit logging for Azure resources | Enable diagnostic logs on the service |
| CN-SC-14 | Foundation | MFA | General | Enable MFA and conditional access with MFA | |
| CN-SC-15 | Service/Component | Network Security | General | Protect resources using Network Security Groups or Azure Firewall on your Virtual Network | |
| CN-SC-16 | Service/Component | Network Security | Compute | Ensure that the endpoint protection for all Virtual Machines is installed | |
| CN-SC-17 | Service/Component | Network Security | Compute | Secure outbound communication to the internet | |
| CN-SC-18 | Service/Component | Network Security | Compute | Enable JIT network access | |
| CN-SC-19 | Foundation | Secure configuration | General | Run automated vulnerability scanning tools | Enable vulnerability assessment on service |
| CN-SC-20 | Foundation | Secure configuration | General | Use automated tools to monitor network resource configurations and detect changes   | Use activity log |
| CN-SC-21 | Service/Component | Secure configuration | General | Disable remote user access ports (RDP,SSH,Telnet,FTP) | |
| CN-SC-22 | Service/Component | Secure configuration | General | Enable automated Patching/ Upgrading | |
| CN-SC-23 | Service/Component | Secure configuration | Databases | Enable transparent data encryption | Only for Cosmos DB, Azure Synapse and SQL Database |
| CN-SC-24 | Service/Component | Secure configuration | Compute | Enable OS vulnerabilities recommendations | |
| CN-SC-25 | Service/Component | Network Security | General | Configure firewall rules of existing firewalls if necessary | |
| CN-SC-26 | Service/Component | Logging and Monitoring | Compute | Enable command-line audit logging | |
| CN-SC-27 | Foundation | IAM | General | Enable conditional access control | |
| CN-SC-28 | Service/Component | Network Security | General | Specify service tags to define network access controls on network security groups or Azure Firewall | |
| CN-SC-29 | Service/Component | IAM | Compute | Use Corporate Active Directory Credentials | |