# Overview

A business continuity and disaster recovery (BCDR) strategy that keeps data safe and apps and workloads up and running when planned and unplanned outages occur is important.
Azure Recovery Services contribute to BCDR strategy:
- Site Recovery Service helps ensure business continuity by keeping business apps and workloads running during outages.
- Site Recovery replicates workloads running on physical and virtual machines (VMs) from a primary site to a secondary location. When an outage occurs at the primary site, it fails over to a secondary location, and it would be possible to access apps from there. After the primary location is running again, it would be possible to fail back to it.
- Backup service keeps your data safe and recoverable by backing it up to Azure.

# Azure Backup

The details on how backups will be performed depends on the service itself. The required backup strategy documentation will be documented in the component documentation if applicable.

Azure Backup is the Azure-based service to backup (or protect) and restore data in the Microsoft cloud. Azure Backup also allows the protection of data from on-premises servers, virtual machines, virtualized workloads, SQL Server, SharePoint Server, and can replace existing traditional on-premises backup solutions.
Azure Backup stores backed-up data in a Recovery Services vault. A vault is an online-storage entity in Azure that’s used to hold data, such as backup copies, recovery points, and backup policies.

The Azure Backup service uses the VM Snapshot or VM SnapshotLinux extension to take a snapshot of the underlying storage. Once the Azure Backup service takes the snapshot, the data is transferred to the Vault. To maximize efficiency, the service identifies and transfers only the blocks of data that have changed since the previous backup. File and folder backup are also possible with Azure backup agents.
Azure Backup supports the backup of Azure VMs that have their OS/data disks encrypted with Azure Disk Encryption (ADE). ADE integrates with Azure Key Vault to manage disk-encryption keys and secrets. Azure backup shown in below figure 

![image.png](/.attachments/image-ca3e32cb-a4c0-49f3-a7f6-f2b953d5edbb.png)

# Azure PaaS Backup
Azure PaaS Services have in most cases a built-in backup functionality to provide backups. contoso will use Azure built-in backup functionality to backup PaaS services instead of using any third-party solutions. 

# Azure Backup Recovery Vaults
For contoso, Recovery Vaults can be created if required into each platform Landing Zone to facilitate the backup of VMs, application data and keeping the separation between the different environments and platform. Each vault can be added to the resource group used for managing resources.

contoso creates subscriptions for each platform in the tenant . Therefore, Recovery Service Vault, which acts as a storage for the backup data will be deployed into each platform subscription with relevant RBAC permissions defined on each recovery vault. 
Backup strategy of each platform will be decided during application intake process. This way the platform team can manage their own backups and decide the backup policy applied for each platform in each environment. At first contoso will start with default backup policies. Going forward the backup policies can be configured according to requirements of each platform.

![image.png](/.attachments/image-fe675440-5ae9-4e54-a82d-1126a0484433.png)
