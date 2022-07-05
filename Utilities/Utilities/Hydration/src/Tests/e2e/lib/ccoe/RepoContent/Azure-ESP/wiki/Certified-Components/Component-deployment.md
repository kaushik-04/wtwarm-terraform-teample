[[_TOC_]]

# Overview of Component deployment process

![Diagram of certified component consumption](/.attachments/images/Certified-Components/certified-components-consuming.png)

> NOTE: the diagram can be modified using the Visio file on [Teams GRP MCS Cloud-native Engagement > Agile Delivery](https://teams.microsoft.com/_?lm=deeplink&lmsrc=homePageWeb&cmpid=WebSignIn#/conversations/Agile%20Delivery?threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&ctx=channel) > Files > [01 - Design Documents](https://contoso.sharepoint.com/sites/GRP_001608-AgileDelivery/Shared%20Documents/Forms/AllItems.aspx?RootFolder=%2Fsites%2FGRP%5F001608%2DAgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20%2D%20Design%20Documents&FolderCTID=0x01200001544C4EB547E84DB41D1C6FCCD4BEA9) > [PXS - Diagrams.vsdx](https://teams.microsoft.com/l/file/6F59E176-935C-450C-B8A0-A23AB3831B4C?tenantId=e7ab81b2-1e84-4bf7-9dcb-b6fec01ed138&fileType=vsdx&objectUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery%2FShared%20Documents%2FAgile%20Delivery%2F01%20-%20Design%20Documents%2FPXS%20-%20Diagrams.vsdx&baseUrl=https%3A%2F%2Fcontoso.sharepoint.com%2Fsites%2FGRP_001608-AgileDelivery&serviceName=teams&threadId=19:2e84079377e541aaae5663305c890086@thread.tacv2&groupId=348f9039-5718-417a-8e56-85e2957e26be)

The process for using a Certified Component consists of the following steps:
1. Write the Configuration File that contains the configuration of the Service to be Deployed
2. Add the deployment step in your Azure DevOps pipeline, including:
   - Download the Component to use
   - Use the Component in combination with the configuration file
   - Use the Service Connection with permissions to deploy in the Landing Zone subscriptions
 3. Run the Pipeline to deploy and manage the Certified Component, considering that:
   - Azure Policies published with `deny` effect will prevent any non-compliant deployment
   - [Actions](https://docs.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations) not allowed in RBAC custom role `LZ Owner` [see Governance](/Foundation-Design/Governance) will result in a blocked deployment

## Write the configuration file

> Learn more in the section [Edit the configuration file](/Certified-Components/Component-deployment/Edit-the-configuration-file.md)

## Configure the deployment pipeline

> Learn more in the section [Configure the deployment pipeline](/Certified-Components/Component-deployment/Configure-the-deployment-pipeline.md)